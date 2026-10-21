class_name WeaponLevel
extends Resource
## What a weapon does at one level. `card_text` is the line on the level-up card that offers this
## level, so it must say exactly what changes.

@export var damage: float = 8.0
## Seconds between attacks (before Quick Hands).
@export var cooldown: float = 1.4
## How far the projectile flies, in pixels.
@export var reach: float = 250.0
## Projectiles per attack.
@export var count: int = 1
## Projectile speed in pixels per second.
@export var speed: float = 450.0
## How many zombies one projectile passes through (0 = stops at the first, -1 = no limit).
@export var pierce: int = 0
## Radius of an area hit (clouds, bursts, arcs), in pixels; 0 for weapons without one.
@export var area: float = 0.0
## How long a lasting effect stays (clouds, beams, orbits), in seconds; 0 if none.
@export var duration: float = 0.0
## Angle between projectiles of one attack, in degrees.
@export var spread_degrees: float = 0.0
@export_multiline var card_text: String = ""
