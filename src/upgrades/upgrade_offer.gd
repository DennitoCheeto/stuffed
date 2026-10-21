class_name UpgradeOffer
extends RefCounted
## One card on the level-up screen: an upgrade and the level picking it would reach.

var upgrade: UpgradeDef
## 1 = new.
var next_level: int = 1
## For weapons that can evolve: the partner item the card shows (null otherwise).
var partner: UpgradeDef


func _init(offered: UpgradeDef, level: int) -> void:
	upgrade = offered
	next_level = level


## "New!", "Lv 2 → 3", or "" for the snack.
func level_text() -> String:
	if upgrade.kind == UpgradeDef.Kind.SNACK:
		return ""
	if next_level <= 1:
		return "New!"
	return "Lv %d → %d" % [next_level - 1, next_level]


func description() -> String:
	return upgrade.text_for(next_level)
