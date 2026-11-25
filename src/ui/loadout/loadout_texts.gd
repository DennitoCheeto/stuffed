class_name LoadoutTexts
extends Resource
## Every word of the loadout pages (spec 04b): tune them in data/ui/loadout_view.tres, not in code.

## The pause menu's button.
@export var button: String = "Loadout"
@export var title: String = "Your loadout"
## Column heading: player number, hero name.
@export var heading: String = "Player %d · %s"
@export var weapons_heading: String = "Weapons"
@export var items_heading: String = "Items"
@export var gear_heading: String = "Gear"
## Level of a weapon that isn't maxed yet: level, top level.
@export var level: String = "Lv %d / %d"
@export var maxed: String = "MAX"
@export var evolved: String = "Evolved"
## Evolution hint under a weapon: what it becomes, the partner item.
@export var evolve_hint: String = "→ %s with %s"
## Shown instead of the evolved name while that evolution hasn't been seen.
@export var unseen: String = "?"
## The weapon is maxed and its partner owned: the next gift box evolves it.
@export var ready: String = "Ready! Find a gift box"
## A worn gear piece: name, stitch level.
@export var gear_line: String = "%s Lv %d"
@export var no_gear: String = "Nothing worn"
