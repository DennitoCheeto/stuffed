class_name StuffingCloud
extends Weapon
## A soft cloud stays around the player and hurts every zombie inside it with each puff. Area is
## the cloud's radius, cooldown the time between puffs (Quick Hands makes it puff faster).


## Always "fires" (one puff), even with no zombie inside, so the puffs keep a steady beat.
func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var cloud: CloudProjectile = _cloud(shots)
	var numbers: WeaponLevel = current()
	var center: Vector2 = player.global_position
	for zombie: Zombie in manager.query_circle(center, numbers.area):
		var push: Vector2 = center.direction_to(zombie.position) * stats.knockback
		manager.damage(zombie, numbers.damage, push, self)
	cloud.puff()
	return true


## The cloud around the player; made on the first puff and kept while the weapon exists.
func _cloud(shots: ProjectileManager) -> CloudProjectile:
	var mine: Array[Projectile] = shots.fired_by(self)
	if not mine.is_empty():
		return mine[0] as CloudProjectile
	var cloud: CloudProjectile = shots.spawn(CloudProjectile) as CloudProjectile
	cloud.launch(self)
	return cloud
