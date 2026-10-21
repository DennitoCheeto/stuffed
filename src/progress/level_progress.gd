class_name LevelProgress
extends RefCounted
## One player's level and XP during a run.

signal xp_changed(xp: int, needed: int, level: int)
## Emitted once per level gained (two at once = two signals).
signal leveled_up(new_level: int)

var rules: XpRules
var level: int = 1
## XP collected towards the next level.
var xp: int = 0


func _init(xp_rules: XpRules) -> void:
	rules = xp_rules


func xp_needed() -> int:
	return rules.xp_to_next(level)


## Adds XP and returns how many levels were gained (a big pickup can give several).
func add_xp(amount: int) -> int:
	xp += amount
	var gained: int = 0
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		gained += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)
	return gained


## Fills the bar to the next level (developer menu).
func level_up_now() -> void:
	add_xp(xp_needed() - xp)
