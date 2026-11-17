class_name TowerPin
extends Weapon
## The Watchtower's turret in the night siege (spec 07 §4): a slow, strong sewing pin at the
## toughest zombie in range (the one with the most health left). Numbers in
## data/siege/watchtower_pin.tres (weapon level = the Watchtower's level).


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var target: Zombie = toughest(manager)
	if target == null:
		return false
	var pin: PinProjectile = shots.spawn(PinProjectile) as PinProjectile
	pin.launch(self, origin().direction_to(target.position))
	return true


## The living zombie with the most health within its range (null = none).
func toughest(manager: EnemyManager) -> Zombie:
	var reach: float = mount_range if mount_range > 0.0 else current().reach
	var best: Zombie = null
	for zombie: Zombie in manager.zombies:
		if zombie.dead or zombie.position.distance_to(origin()) > reach:
			continue
		if best == null or zombie.health > best.health:
			best = zombie
	return best
