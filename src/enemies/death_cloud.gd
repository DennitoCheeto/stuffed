class_name DeathCloud
extends Resource
## What a bursting zombie (the bloater) leaves behind: a stuffing cloud on the floor that hurts
## any player inside it for a moment, then fades. Tune it in data/enemies/*.tres, not in code.

## Pixels. The cloud's edge is drawn exactly here.
@export var radius: float = 70.0
## Seconds it stays.
@export var duration: float = 2.5
## Per hit (a player can be hit again once their short hurt invulnerability is over).
@export var damage: float = 6.0
