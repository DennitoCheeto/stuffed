class_name HeroStats
extends Resource
## Balance numbers for one hero. Tune them in data/heroes/*.tres, not in code.

@export var display_name: String = "Hero"
@export var max_health: float = 100.0
## Pixels per second.
@export var move_speed: float = 150.0
## How far one dash carries the hero, in pixels.
@export var dash_distance: float = 120.0
## How long the dash burst lasts, in seconds. The hero can't be hurt during it.
@export var dash_duration: float = 0.15
## Seconds from the start of one dash until the next dash is possible.
@export var dash_cooldown: float = 1.5
## Seconds the hero can't be hurt again after taking a hit.
@export var hurt_invulnerability: float = 0.5
## Radius of the real hitbox (smaller than the drawing).
@export var hitbox_radius: float = 12.0
## XP buttons closer than this (pixels) fly to the hero.
@export var pickup_range: float = 60.0
## The weapon the hero starts every run with.
@export var starting_weapon: WeaponStats

@export_group("Slippery (Banane's passive)")
## Every dash drops a banana peel where it started (off for heroes without the passive).
@export var slippery: bool = false
## Seconds a peel stays on the floor if nobody steps on it.
@export var peel_lifetime: float = 4.0
## Seconds a zombie is stunned after slipping.
@export var peel_stun: float = 1.0
## Peels on the floor at once (the oldest goes when a new one would be too many).
@export var peel_max: int = 3
## Radius of a peel's slippery area, in pixels.
@export var peel_radius: float = 18.0
