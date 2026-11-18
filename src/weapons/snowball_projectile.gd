class_name SnowballProjectile
extends ThimbleProjectile
## Pip's lobbed snowball (Snowball Toss, spec 08 §3): flies like a thimble (ring on the floor,
## shadow, high arc), bursts in a small area and slows every zombie it hits for a moment
## (`WeaponStats.slow` / `slow_seconds`).


func _ball_part() -> StringName:
	return ProjectileLook.SNOWBALL


func _landed_on(zombie: Zombie) -> void:
	if zombie.dead:
		return
	zombie.slow(weapon.stats.slow, weapon.stats.slow_seconds)
