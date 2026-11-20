class_name WornGear
extends RefCounted
## What one player wears (spec 09 §7, §8): the pieces on, their stitch levels and which slots are
## hidden (a hidden piece isn't drawn on the hero but still works). Read from the town's save for
## a player slot; the hero, its puppet and the photos draw from it, the gear effects read it.

## The pieces on, in slot order (Head, Body, Charm; empty slots are left out).
var pieces: Array[GearDef] = []
## Piece id -> stitch level (1-3).
var levels: Dictionary[StringName, int] = {}
## Slot names ("head", "body", "charm") whose piece isn't drawn on the hero.
var hidden: PackedStringArray = []


## What player `player` wears in the town of `save`.
static func of(save: TownSave, player: int, rules: GearRules = GearRules.current()) -> WornGear:
	var worn: WornGear = WornGear.new()
	for piece: GearDef in GearBook.worn_pieces(save, player, rules):
		worn.pieces.append(piece)
		worn.levels[piece.id] = maxi(save.gear.stitch_level(String(piece.id)), 1)
	for slot_name: String in GearDef.SLOT_NAMES:
		if save.gear.is_hidden(player, slot_name):
			worn.hidden.append(slot_name)
	return worn


## The stitch level of `piece` as worn (0 = not worn).
func level_of(piece: GearDef) -> int:
	return levels.get(piece.id, 0)


## The piece `id` as worn (null = not worn).
func find_piece(id: StringName) -> GearDef:
	for worn: GearDef in pieces:
		if worn.id == id:
			return worn
	return null


## The number of piece `id` at its worn stitch level (0 = not worn).
func amount_of(id: StringName) -> float:
	var worn: GearDef = find_piece(id)
	return worn.amount(level_of(worn)) if worn != null else 0.0


## The piece on in `slot` (null = nothing).
func in_slot(slot: GearDef.Slot) -> GearDef:
	for piece: GearDef in pieces:
		if piece.slot == slot:
			return piece
	return null


## True when the piece `id` is worn (shown or hidden: it works either way).
func has(id: StringName) -> bool:
	return levels.has(id)


func is_hidden(slot: GearDef.Slot) -> bool:
	return hidden.has(GearDef.SLOT_NAMES[slot])


## The pieces drawn on the hero (worn and not hidden), in slot order.
func shown() -> Array[GearDef]:
	var result: Array[GearDef] = []
	for piece: GearDef in pieces:
		if not is_hidden(piece.slot):
			result.append(piece)
	return result


## A short text that changes whenever what is drawn changes (to skip needless rebakes).
func look_key() -> String:
	var parts: PackedStringArray = []
	for piece: GearDef in shown():
		parts.append("%s:%d" % [piece.id, level_of(piece)])
	return ",".join(parts)


## The worn pieces as result entries for player `player` (end screen tags, run log):
## {"player", "slot", "id", "name", "level"}, hidden pieces too (they still work).
func to_list(player: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for piece: GearDef in pieces:
		var entry: Dictionary = {
			"player": player, "slot": piece.slot_name(), "id": String(piece.id)
		}
		entry["name"] = piece.display_name
		entry["level"] = level_of(piece)
		result.append(entry)
	return result
