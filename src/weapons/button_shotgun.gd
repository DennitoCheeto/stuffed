class_name ButtonShotgun
extends Weapon
## Fires a short-range fan of buttons at the nearest zombie. Buttons hit hard up close and push
## zombies back.

## Only fires at zombies this many times the reach away.
const SEARCH_FACTOR: float = 1.5


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var numbers: WeaponLevel = current()
	var target: Zombie = manager.nearest(origin(), numbers.reach * SEARCH_FACTOR)
	if target == null:
		return false
	var aim: Vector2 = origin().direction_to(target.position)
	var spread: float = deg_to_rad(numbers.spread_degrees)
	for i: int in numbers.count:
		var offset: float = (i - (numbers.count - 1) / 2.0) * spread
		var button: ButtonProjectile = shots.spawn(_button_kind()) as ButtonProjectile
		button.launch(self, aim.rotated(offset))
	return true


## The button it fires (Bowling Buttons fires its own).
func _button_kind() -> GDScript:
	return ButtonProjectile
