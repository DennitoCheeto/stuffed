class_name UpgradeOffer
extends RefCounted
## One card on the level-up screen: an upgrade and the level picking it would reach.

## A shiny card (Shiny Card trick, spec 06 §3.1) gives this many levels at once.
const SHINY_LEVELS: int = 2

var upgrade: UpgradeDef
## 1 = new.
var next_level: int = 1
## For weapons that can evolve: the partner item the card shows (null otherwise).
var partner: UpgradeDef
## Shiny Card trick: picking this card gives SHINY_LEVELS levels instead of one.
var shiny: bool = false


func _init(offered: UpgradeDef, level: int) -> void:
	upgrade = offered
	next_level = level


## How many levels picking this card gives.
func levels() -> int:
	return SHINY_LEVELS if shiny else 1


## The level the upgrade stands at after picking this card.
func reached_level() -> int:
	return next_level + levels() - 1


## True if this card may be shiny: a weapon or item with room for all the shiny levels (never
## the snack, never a card one level from max).
func can_shine() -> bool:
	if upgrade.kind == UpgradeDef.Kind.SNACK:
		return false
	return next_level + SHINY_LEVELS - 1 <= upgrade.top_level()


## "New!", "Lv 2 → 3", or "" for the snack. Shiny: "New! Lv 2" or "Lv 2 → 4".
func level_text() -> String:
	if upgrade.kind == UpgradeDef.Kind.SNACK:
		return ""
	if next_level <= 1:
		return "New! Lv %d" % reached_level() if shiny else "New!"
	return "Lv %d → %d" % [next_level - 1, reached_level()]


func description() -> String:
	return upgrade.text_for(next_level)
