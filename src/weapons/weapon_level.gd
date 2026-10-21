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
## How many zombies one projectile passes through (0 = stops at the first).
@export var pierce: int = 0
## Angle between projectiles of one attack, in degrees.
@export var spread_degrees: float = 0.0
@export_multiline var card_text: String = ""
