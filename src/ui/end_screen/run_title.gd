class_name RunTitle
extends RefCounted
## A title one run earned (RunTitleRules.pick): what the sticker says and whether it's a first.

## RunTitleDef.id; a weapon title adds the weapon ("weapon_star:thimble_mortar"), so each
## weapon's title is new once.
var id: String = ""
var text: String = ""
var rarity: int = 0
var bad: bool = false
## Never earned before: it gets a "New!" sticker (set by Main from the save).
var is_new: bool = false


func _init(title_id: String = "", words: String = "", rare: int = 0, joke: bool = false) -> void:
	id = title_id
	text = words
	rarity = rare
	bad = joke
