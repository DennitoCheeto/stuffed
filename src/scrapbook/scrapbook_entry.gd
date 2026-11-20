class_name ScrapbookEntry
extends RefCounted
## One spot in the Scrapbook (spec 03 §8): a weapon, item, enemy, floor pickup or plushie, and
## what the book shows once it was seen (picture, name, text, a note).

enum Picture { ICON, ZOMBIE, PICKUP, PLUSHIE, GEAR }

## Saved in TownSave.seen under its page (a weapon or item id, "shambler", "elite", "pip", ...).
var id: String = ""
var display_name: String = ""
var text: String = ""
## A second line: a weapon's evolution partner, an evolution's recipe, an item's top level.
var note: String = ""
var picture: Picture = Picture.ICON
## ICON: the UpgradeIcon to draw.
var icon: StringName = &""
## ZOMBIE: its felt puppet, how big it is drawn (elites, bosses) and the elite marks.
var look: EnemyStats.Look = EnemyStats.Look.SHAMBLER
var size: float = 1.0
var elite: bool = false
## PICKUP: the floor pickup id (its felt look).
var pickup: StringName = &""
## PLUSHIE: who.
var plushie: PlushieDef
## GEAR: the piece, a GearDef (drawn in its calm colour at stitch level 1). Typed as Resource:
## a GearDef field here closes a script loop (typecheck "resources still in use").
var gear: Resource


func _init(entry_id: String, entry_name: String, entry_text: String) -> void:
	id = entry_id
	display_name = entry_name
	text = entry_text
