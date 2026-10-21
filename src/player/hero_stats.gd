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
