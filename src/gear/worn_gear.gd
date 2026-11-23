class_name WornGear
extends RefCounted
## What one player wears (spec 09 §7, §8): the pieces on and their stitch levels. Read from the
## town's save for a player slot; the gear effects read it, the menus show it (gear is not drawn
## on the hero, #331).

## The pieces on, in slot order (Head, Body, Charm; empty slots are left out).
var pieces: Array[GearDef] = []
## Piece id -> stitch level (1-3).
var levels: Dictionary[StringName, int] = {}


## What player `player` wears in the town of `save`.
static func of(save: TownSave, player: int, rules: GearRules = GearRules.current()) -> WornGear:
	var worn: WornGear = WornGear.new()
	for piece: GearDef in GearBook.worn_pieces(save, player, rules):
		worn.pieces.append(piece)
		worn.levels[piece.id] = maxi(save.gear.stitch_level(String(piece.id)), 1)
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


## True when the piece `id` is worn.
func has(id: StringName) -> bool:
	return levels.has(id)


## The worn pieces as result entries for player `player` (end screen tags, run log):
## {"player", "slot", "id", "name", "level"}.
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
