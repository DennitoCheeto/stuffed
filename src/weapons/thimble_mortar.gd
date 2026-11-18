class_name ThimbleMortar
extends Weapon
## Lobs thimbles at random zombies on screen. Each lands where its target stood when it was
## thrown (a shadow shows the spot) and hurts every zombie in a small area there.

## Only for picking targets, so the seeded run (spawns, cards) stays the same.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var targets: Array[Zombie] = _on_screen(manager)
	if targets.is_empty():
		return false
	for i: int in current().count:
		var target: Zombie = _pick_target(targets, i)
		var thimble: ThimbleProjectile = shots.spawn(_shot_kind()) as ThimbleProjectile
		thimble.launch(self, target.position)
	return true


## Where shot number `index` of this attack goes (a random zombie on screen).
func _pick_target(targets: Array[Zombie], _index: int) -> Zombie:
	return targets[_rng.randi_range(0, targets.size() - 1)]


## The lobbed shot (a ThimbleProjectile or a subclass).
func _shot_kind() -> GDScript:
	return ThimbleProjectile


## Living zombies inside the visible part of the world (a turret: within its range).
func _on_screen(manager: EnemyManager) -> Array[Zombie]:
	if is_turret():
		return _in_range(manager)
	var viewport: Viewport = get_viewport()
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var result: Array[Zombie] = []
	for zombie: Zombie in manager.zombies:
		if not zombie.dead and view.has_point(zombie.position):
			result.append(zombie)
	return result


func _in_range(manager: EnemyManager) -> Array[Zombie]:
	var result: Array[Zombie] = []
	var reach: float = mount_range * mount_range
	for zombie: Zombie in manager.zombies:
		if not zombie.dead and zombie.position.distance_squared_to(origin()) <= reach:
			result.append(zombie)
	return result
