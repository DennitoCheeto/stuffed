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

@export_group("Patterns")
## Banner when one pattern is found ("New pattern: Lookout Cap!") ...
@export var pattern_banner: String = "New pattern: %s!"
@export var pattern_subtitle: String = "Sew it at the Sewing Workshop"
## ... and when several come at once (town; the subtitle lists them).
@export var patterns_banner: String = "New patterns!"
@export var patterns_subtitle: String = "%s: sew them at the Sewing Workshop"
## Seconds the banner stays in a run.
@export var pattern_banner_seconds: float = 2.6
## Sound when a pattern is found.
@export var pattern_sound: StringName = &"page"
## A pattern envelope opens when a hero comes this close (pixels, plus the hero's hitbox).
@export var envelope_touch_radius: float = 26.0
## An envelope lands this far from where its boss or elite fell (next to the gift box).
@export var envelope_offset: Vector2 = Vector2(64.0, -24.0)
## Developer menu "Drop pattern": this far from player 1.
@export var envelope_dev_offset: Vector2 = Vector2(0.0, -90.0)


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


## The pieces whose pattern comes from `kind` (and, unless empty, from `source`: a building id or
## a boss file name), in order.
func pieces_from(kind: GearDef.Source, source: String = "") -> Array[GearDef]:
	var result: Array[GearDef] = []
	for piece: GearDef in pieces:
		if piece.source_kind == kind and (source.is_empty() or String(piece.source) == source):
			result.append(piece)
	return result


## The banner title and subtitle for finding `found` (one or several patterns at once).
func pattern_news(found: Array[GearDef]) -> PackedStringArray:
	if found.size() == 1:
		return PackedStringArray([pattern_banner % found[0].display_name, pattern_subtitle])
	var names: PackedStringArray = []
	for piece: GearDef in found:
		names.append(piece.display_name)
	return PackedStringArray([patterns_banner, patterns_subtitle % ", ".join(names)])
