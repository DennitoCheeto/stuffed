class_name GiftCard
extends RefCounted
## One card the gift box shows after opening (spec 02 §20): what one thing received was.

## The felt icon (see `UpgradeIcon`).
var icon: StringName = &""
## Evolutions only: the icon of the weapon it evolved from (shown as "old → new").
var from_icon: StringName = &""
## Evolutions only: the name of the weapon it evolved from.
var from_name: String = ""
var title: String = ""
## "Lv 2 → 3", "Evolved!" or the heal amount.
var level_text: String = ""
## One line of what it does.
var text: String = ""


func is_evolution() -> bool:
	return from_icon != &""
