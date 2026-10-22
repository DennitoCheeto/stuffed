class_name BouncyYarnBall
extends Weapon
## Throws yarn balls at the nearest zombie. Each ball bounces on to the next zombie nearby and
## off the arena's walls until it has hit `pierce + 1` zombies or its duration is over.

## Only throws at zombies this many times the reach away.
const SEARCH_FACTOR: float = 1.5


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var numbers: WeaponLevel = current()
	var target: Zombie = manager.nearest(player.global_position, numbers.reach * SEARCH_FACTOR)
	if target == null:
		return false
	var aim: Vector2 = player.global_position.direction_to(target.position)
	var spread: float = deg_to_rad(numbers.spread_degrees)
	for i: int in numbers.count:
		var offset: float = (i - (numbers.count - 1) / 2.0) * spread
		var ball: YarnProjectile = shots.spawn(YarnProjectile) as YarnProjectile
		ball.launch(self, aim.rotated(offset))
	return true
