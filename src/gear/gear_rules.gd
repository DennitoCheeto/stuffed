class_name GearRules
extends Resource
## The sewn-on gear (spec 09): every piece and what the Sewing Workshop's levels open. Numbers
## live in data/gear/gear_rules.tres and the pieces' own .tres files.

const PATH: String = "res://data/gear/gear_rules.tres"

static var _current: GearRules

## Every piece, by slot (Head, Body, Charm).
@export var pieces: Array[GearDef] = []
## The building id of the Sewing Workshop.
@export var workshop: StringName = &"sewing_workshop"
## The Workshop level each slot needs (in `GearDef.Slot` order): Head and Body at Lv 1, Charm Lv 2.
@export var slot_levels: Array[int] = [1, 1, 2]
## The highest stitch level per Workshop level (index = Workshop level, 0 = not built).
@export var stitch_caps: Array[int] = [0, 1, 2, 3]


static func current() -> GearRules:
	if _current == null:
		_current = load(PATH) as GearRules
	return _current


## The piece with this id, or null.
func find(id: String) -> GearDef:
	for piece: GearDef in pieces:
		if String(piece.id) == id:
			return piece
	return null


## The pieces of one slot, in order.
func pieces_in(slot: GearDef.Slot) -> Array[GearDef]:
	var result: Array[GearDef] = []
	for piece: GearDef in pieces:
		if piece.slot == slot:
			result.append(piece)
	return result


## The Workshop level slot `slot` needs.
func slot_level(slot: GearDef.Slot) -> int:
	return slot_levels[slot] if slot < slot_levels.size() else 1


## The highest stitch level a Workshop at `workshop_level` can sew.
func stitch_cap(workshop_level: int) -> int:
	if stitch_caps.is_empty():
		return 0
	return stitch_caps[clampi(workshop_level, 0, stitch_caps.size() - 1)]
