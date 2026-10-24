class_name WeaponStats
extends Resource
## One weapon and its levels. Tune it in data/weapons/*.tres, not in code.

## Stable name for upgrades, saves and the run log.
@export var id: StringName = &""
@export var display_name: String = "Weapon"
## Its run title when it did most of the damage (spec 04 §4.2), e.g. "Mortar Maniac".
@export var run_title: String = ""
## The script that makes the weapon work (a Weapon subclass).
@export var behaviour: Script
## Push given to zombies it hits, in pixels per second.
@export var knockback: float = 120.0
## Radius of the projectile's hit area, in pixels.
@export var hit_radius: float = 14.0
## Seconds before one lasting shot (an orbiting needle) can hurt the same zombie again.
@export var hit_interval: float = 0.5
## For evolved weapons: the id of the weapon it evolved from ("" otherwise).
@export var evolved_from: StringName = &""
## Lingering areas (Yarn Bomb's sticky yarn): zombies inside move this much slower (0.5 = half
## speed) ...
@export var slow: float = 0.0
## ... and take this much damage every `hit_interval`.
@export var linger_damage: float = 0.0
## Evolved weapons: how their shots look (null = the normal look).
@export var shot_look: ShotLook
## Sound of one attack (a name in SfxBank) and its pitch (1 = as made).
@export var sound: StringName = &""
@export var sound_pitch: float = 1.0
## At least this many seconds between two of its sounds (0 = every attack). For weapons that
## attack very often, like the Stuffing Cloud, so they don't get tiring.
@export var sound_gap: float = 0.0
## Level 1 first.
@export var levels: Array[WeaponLevel] = []


func max_level() -> int:
	return levels.size()


## The numbers for `level` (1-based, clamped to the existing levels).
func at_level(level: int) -> WeaponLevel:
	return levels[clampi(level, 1, levels.size()) - 1]
