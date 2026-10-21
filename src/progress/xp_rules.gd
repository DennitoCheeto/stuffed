class_name XpRules
extends Resource
## XP numbers: how much each button is worth and how much XP each level needs.
## Tune them in data/xp_rules.tres, not in code.

## XP needed to go from level 1 to level 2.
@export var first_level_xp: int = 5
## Each level needs this much more than the one before (0.4 = +40%), rounded.
@export var growth_per_level: float = 0.4
## XP per button size: small, medium, big (see EnemyStats.XpSize).
@export var button_values: PackedInt32Array = [1, 3, 10]
## Buttons flying to a player start at this speed (pixels per second) ...
@export var attract_start_speed: float = 120.0
## ... speed up by this much per second ...
@export var attract_acceleration: float = 1400.0
## ... up to this speed.
@export var attract_max_speed: float = 900.0


## XP needed to go from `level` to `level + 1`.
func xp_to_next(level: int) -> int:
	return roundi(first_level_xp * pow(1.0 + growth_per_level, maxi(level, 1) - 1))


func button_value(size: EnemyStats.XpSize) -> int:
	return button_values[size]
