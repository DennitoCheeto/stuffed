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
@export var pattern_banner_seconds: float = 4.5
## Sound when a pattern is found.
@export var pattern_sound: StringName = &"page"
## A pattern envelope opens when a hero comes this close (pixels, plus the hero's hitbox).
@export var envelope_touch_radius: float = 26.0
## An envelope lands this far from where its boss or elite fell (next to the gift box).
@export var envelope_offset: Vector2 = Vector2(64.0, -24.0)
## Developer menu "Drop pattern": this far from player 1.
@export var envelope_dev_offset: Vector2 = Vector2(0.0, -90.0)

@export_group("Sewing table")
@export var table_title: String = "Sewing table"
## What E does at a built Workshop (keys filled in by `KeyBindings.fill`).
@export var table_prompt: String = "{interact}   Open the sewing table"
## Which keys do what on the table.
@export var table_hint: String = "{interact} or click: sew, stitch or wear      {reroll}: take off"
@export var table_close_hint: String = "Esc: close"
## The slot names on the hero photo, in `GearDef.Slot` order.
@export var slot_titles: PackedStringArray = ["Head", "Body", "Charm"]
@export var empty_slot: String = "nothing on"
## The main action on a tile.
@export var sew_text: String = "Sew"
@export var stitch_text: String = "Stitch to Lv %d"
@export var wear_text: String = "Wear"
@export var take_off_text: String = "Take off"
## Why a tile can't do more right now.
@export var building_source_text: String = "Build the %s to Lv %d"
@export var needs_workshop_text: String = "Needs Workshop Lv %d"
@export var taken_text: String = "Player %d wears it"
@export var maxed_text: String = "Top stitch level!"
@export var repair_text: String = "Repair the Workshop first"
## The Workshop's own upgrade, as a button on the table.
@export var upgrade_text: String = "Upgrade the Workshop to Lv %d"
## Floats over the Workshop while something can be sewn or stitched (like "Can build!").
@export var can_sew_tag: String = "Can sew!"
## The sewing moment: seconds the needle bobs before the pop.
@export var sewing_seconds: float = 0.55
## How big the felt puff is when a piece is sewn (a building's rebuild puff is 1).
@export var sewing_puff: float = 0.45

@export_group("Hiding gear")
## The eye toggles (spec 09 §6, AC-100b): one per slot, and one for every slot.
@export var shown_text: String = "Show on hero"
@export var hidden_text: String = "Hidden"
@export var hide_all_text: String = "Hide all"
@export var show_all_text: String = "Show all"
## Above the toggles on the Wardrobe's hero picker.
@export var picker_gear_title: String = "Gear on your hero:"
## Which key hides (keys filled in by `KeyBindings.fill`).
@export var hide_hint: String = "{hide_gear}: hide on hero"


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


## Where `piece`'s pattern comes from: "Build the Watchtower to Lv 2" (`place` = the building's
## name) or its `found_text` ("Big Ted drops this").
func source_text(piece: GearDef, place: String) -> String:
	if piece.source_kind != GearDef.Source.BUILDING:
		return piece.found_text
	return building_source_text % [place, piece.source_level]
