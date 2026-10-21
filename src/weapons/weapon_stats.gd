class_name WeaponStats
extends Resource
## One weapon and its levels. Tune it in data/weapons/*.tres, not in code.

## Stable name for upgrades, saves and the run log.
@export var id: StringName = &""
@export var display_name: String = "Weapon"
## The script that makes the weapon work (a Weapon subclass).
@export var behaviour: Script
## Push given to zombies it hits, in pixels per second.
@export var knockback: float = 120.0
## Radius of the projectile's hit area, in pixels.
@export var hit_radius: float = 14.0
## Level 1 first.
@export var levels: Array[WeaponLevel] = []


func max_level() -> int:
	return levels.size()


## The numbers for `level` (1-based, clamped to the existing levels).
func at_level(level: int) -> WeaponLevel:
	return levels[clampi(level, 1, levels.size()) - 1]
