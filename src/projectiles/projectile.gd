class_name Projectile
extends Sprite2D
## One shot in flight: a player's projectile or an enemy bullet. Shots don't move themselves: the
## ProjectileManager moves all of them in one loop and reuses finished ones (a pool), because
## hundreds of nodes that each run their own physics callback, or that are created and freed for
## every shot, cost a lot. Shots are sprites from the FeltAtlas (no shapes drawn per frame).

## The weapon that fired it (null for enemy bullets). Its shots vanish if the weapon goes away.
var weapon: Weapon
var manager: ProjectileManager


## Enemy bullets are drawn above everything and hurt players instead of zombies.
func is_hostile() -> bool:
	return false


## Called each time the shot is taken from the pool: forget everything from its last flight.
func reset() -> void:
	weapon = null
	rotation = 0.0


## Moves the shot by one physics frame. Returns false when it is done (back to the pool).
func advance(_delta: float) -> bool:
	return false
