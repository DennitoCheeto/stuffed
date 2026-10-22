class_name PeelBoomerang
extends Weapon
## Banane's starting weapon: throws a banana peel at the nearest zombie. It flies out to its
## reach, turns, and flies back to Banane (following him), hurting each zombie once per way.

## A thrown peel came back and Banane caught it.
signal peel_caught

## Only throws at zombies this many times the reach away (roughly: on screen).
const SEARCH_FACTOR: float = 2.0


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
	for i: int in numbers.count:
		var peel: BoomerangProjectile = shots.spawn(_peel_kind()) as BoomerangProjectile
		peel.launch(self, aim.rotated(_fan_angle(i, numbers)))
	return true


## Which shot it throws (Banana Split throws peels that split).
func _peel_kind() -> GDScript:
	return BoomerangProjectile


## Spreads several peels of one throw evenly around the aim (0, +a, -a, +2a, ...).
func _fan_angle(index: int, numbers: WeaponLevel) -> float:
	var spread: float = deg_to_rad(numbers.spread_degrees)
	var step: int = (index + 1) / 2
	var side: float = 1.0 if index % 2 == 1 else -1.0
	return spread * step * side
