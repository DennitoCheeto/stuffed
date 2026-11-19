class_name GearBook
extends RefCounted
## The rules for sewn-on gear (spec 09 §4-§6, §8): owning patterns, sewing a piece (stitch Lv 1)
## and stitching it stronger at the Sewing Workshop, wearing and taking pieces off per player.
## The town owns the pieces; each sewn piece exists once, so only one player can wear it.

## The next sewing step of a piece (sew or stitch) for the town.
enum Step {
	CAN_SEW,
	CAN_STITCH,
	## Sewn at its top stitch level.
	MAXED,
	## The pattern wasn't found yet.
	NO_PATTERN,
	## The Workshop isn't built, or a lost siege damaged it.
	NO_WORKSHOP,
	## The Workshop's level is too low for this slot or the next stitch level.
	NEEDS_LEVEL,
	## Everything is ready, but the jars don't hold enough.
	MISSING,
}

## Whether a player can put a piece on.
enum Wear {
	CAN_WEAR,
	## This player already wears it.
	WORN,
	## Another player wears it (one copy per piece).
	TAKEN,
	NOT_SEWN,
	## The Workshop's level doesn't open this slot yet.
	SLOT_LOCKED,
}


## The main action of a piece's tile on the sewing table (spec 09 §6) for one player.
enum Action {
	## Not sewn yet: sew it (it goes on if that slot is empty).
	SEW,
	## Worn by this player: stitch it one level up.
	STITCH,
	## Sewn, nobody wears it: put it on (swaps what was in that slot).
	WEAR,
	## Worn by this player and it can't be stitched further now: take it off.
	TAKE_OFF,
	## Nothing to do (no pattern, slot locked, another player wears it).
	NONE,
}


## The Workshop's level (0 = not built).
static func workshop_level(save: TownSave, rules: GearRules = GearRules.current()) -> int:
	return save.building_level(String(rules.workshop))


## True when the Workshop's level opens slot `slot` (wearing works even while it is damaged).
static func slot_open(
	save: TownSave, slot: GearDef.Slot, rules: GearRules = GearRules.current()
) -> bool:
	var at: int = workshop_level(save, rules)
	return at > 0 and at >= rules.slot_level(slot)


## The highest stitch level the Workshop can sew now (0 = none: not built or damaged).
static func stitch_cap(save: TownSave, rules: GearRules = GearRules.current()) -> int:
	if save.is_damaged(String(rules.workshop)):
		return 0
	return rules.stitch_cap(workshop_level(save, rules))


## The next sewing step of `piece` for the town in `save`.
static func step_of(save: TownSave, piece: GearDef, rules: GearRules = GearRules.current()) -> Step:
	var id: String = String(piece.id)
	var at: int = save.gear.stitch_level(id)
	if at >= piece.max_level():
		return Step.MAXED
	if not save.gear.has_pattern(id):
		return Step.NO_PATTERN
	if workshop_level(save, rules) <= 0 or save.is_damaged(String(rules.workshop)):
		return Step.NO_WORKSHOP
	if not slot_open(save, piece.slot, rules) or at + 1 > stitch_cap(save, rules):
		return Step.NEEDS_LEVEL
	if not save.can_afford(piece.level(at + 1).cost()):
		return Step.MISSING
	return Step.CAN_SEW if at == 0 else Step.CAN_STITCH


## Sews `piece` (or stitches it one level up) for the town: takes the price once. Sewing a new
## piece puts it on player `player` when that slot is empty. Returns false (and changes
## nothing) unless its step is CAN_SEW or CAN_STITCH.
static func sew(
	save: TownSave, piece: GearDef, player: int = 0, rules: GearRules = GearRules.current()
) -> bool:
	var step: Step = step_of(save, piece, rules)
	if step != Step.CAN_SEW and step != Step.CAN_STITCH:
		return false
	var id: String = String(piece.id)
	var at: int = save.gear.stitch_level(id)
	if not save.spend(piece.level(at + 1).cost()):
		return false
	save.gear.stitches[id] = at + 1
	if step == Step.CAN_SEW and save.gear.worn_in(player, piece.slot_name()).is_empty():
		save.gear.put_on(player, piece.slot_name(), id)
	return true


## Whether player `player` can put `piece` on.
static func wear_state(
	save: TownSave, piece: GearDef, player: int, rules: GearRules = GearRules.current()
) -> Wear:
	var id: String = String(piece.id)
	if not save.gear.is_sewn(id):
		return Wear.NOT_SEWN
	var wearer: int = save.gear.wearer_of(id)
	if wearer == player:
		return Wear.WORN
	if wearer >= 0:
		return Wear.TAKEN
	if not slot_open(save, piece.slot, rules):
		return Wear.SLOT_LOCKED
	return Wear.CAN_WEAR


## Player `player` puts `piece` on (free; it replaces what they wore in that slot). Returns
## false (and changes nothing) unless its wear state is CAN_WEAR.
static func wear(
	save: TownSave, piece: GearDef, player: int, rules: GearRules = GearRules.current()
) -> bool:
	if wear_state(save, piece, player, rules) != Wear.CAN_WEAR:
		return false
	save.gear.put_on(player, piece.slot_name(), String(piece.id))
	return true


## Player `player` takes off what they wear in `slot` (free). Returns false if it was empty.
static func take_off(save: TownSave, player: int, slot: GearDef.Slot) -> bool:
	var slot_name: String = GearDef.SLOT_NAMES[slot]
	if save.gear.worn_in(player, slot_name).is_empty():
		return false
	save.gear.take_off(player, slot_name)
	return true


## The pieces player `player` wears, by slot (only slots with a piece on).
static func worn_pieces(
	save: TownSave, player: int, rules: GearRules = GearRules.current()
) -> Array[GearDef]:
	var result: Array[GearDef] = []
	for slot_name: String in GearDef.SLOT_NAMES:
		var piece: GearDef = rules.find(save.gear.worn_in(player, slot_name))
		if piece != null:
			result.append(piece)
	return result


## Every piece's every stitch level together (the price of sewing everything to the top).
static func total_cost(rules: GearRules = GearRules.current()) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for piece: GearDef in rules.pieces:
		for stitch: GearLevel in piece.levels:
			var cost: Dictionary[String, int] = stitch.cost()
			for id: String in cost:
				result[id] = result.get(id, 0) + cost[id]
	return result


## Pieces whose building pattern the town has earned but doesn't own yet (spec 09 §4): their
## building stands at the pattern's level (Lv 2) or higher. Old saves catch up this way too.
static func building_patterns_due(
	save: TownSave, rules: GearRules = GearRules.current()
) -> Array[GearDef]:
	var result: Array[GearDef] = []
	for piece: GearDef in rules.pieces_from(GearDef.Source.BUILDING):
		var built: int = save.building_level(String(piece.source))
		if built >= piece.source_level and not save.gear.has_pattern(String(piece.id)):
			result.append(piece)
	return result


## Gives the town every building pattern it has earned. Returns the new ones.
static func give_building_patterns(
	save: TownSave, rules: GearRules = GearRules.current()
) -> Array[GearDef]:
	var due: Array[GearDef] = building_patterns_due(save, rules)
	for piece: GearDef in due:
		save.gear.add_pattern(String(piece.id))
	return due


## The main action of `piece`'s tile for player `player`. SEW and STITCH may still be short of
## materials (`can_act` says whether it works right now).
static func action_for(
	save: TownSave, piece: GearDef, player: int, rules: GearRules = GearRules.current()
) -> Action:
	var step: Step = step_of(save, piece, rules)
	var wear_now: Wear = wear_state(save, piece, player, rules)
	if wear_now == Wear.CAN_WEAR:
		return Action.WEAR
	var can_sew: bool = step == Step.CAN_SEW or step == Step.CAN_STITCH or step == Step.MISSING
	if wear_now == Wear.NOT_SEWN and can_sew:
		return Action.SEW
	if wear_now != Wear.WORN:
		return Action.NONE
	if can_sew:
		return Action.STITCH
	return Action.TAKE_OFF


## True when `piece`'s main action works right now (sewing needs the materials).
static func can_act(
	save: TownSave, piece: GearDef, player: int, rules: GearRules = GearRules.current()
) -> bool:
	var action: Action = action_for(save, piece, player, rules)
	if action == Action.WEAR or action == Action.TAKE_OFF:
		return true
	if action == Action.NONE:
		return false
	var step: Step = step_of(save, piece, rules)
	return step == Step.CAN_SEW or step == Step.CAN_STITCH


## Does `piece`'s main action for player `player`: sewing pays once. Returns false (and changes
## nothing) if it can't be done right now.
static func act(
	save: TownSave, piece: GearDef, player: int, rules: GearRules = GearRules.current()
) -> bool:
	if not can_act(save, piece, player, rules):
		return false
	var action: Action = action_for(save, piece, player, rules)
	if action == Action.WEAR:
		return wear(save, piece, player, rules)
	if action == Action.TAKE_OFF:
		return take_off(save, player, piece.slot)
	return sew(save, piece, player, rules)


## True when the jars can pay for sewing or stitching any piece (the Workshop's "Can sew!" tag).
static func can_sew_any(save: TownSave, rules: GearRules = GearRules.current()) -> bool:
	for piece: GearDef in rules.pieces:
		var step: Step = step_of(save, piece, rules)
		if step == Step.CAN_SEW or step == Step.CAN_STITCH:
			return true
	return false


## The Workshop level `piece` needs for its next step: its slot, or the next stitch level.
static func workshop_level_needed(
	save: TownSave, piece: GearDef, rules: GearRules = GearRules.current()
) -> int:
	var next: int = save.gear.stitch_level(String(piece.id)) + 1
	var needed: int = rules.slot_level(piece.slot)
	for level: int in rules.stitch_caps.size():
		if rules.stitch_caps[level] >= next:
			return maxi(needed, level)
	return maxi(needed, rules.stitch_caps.size() - 1)
