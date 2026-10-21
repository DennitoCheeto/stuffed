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
	Sfx.play(&"throw", 0.6)
	for i: int in current().count:
		var target: Zombie = targets[_rng.randi_range(0, targets.size() - 1)]
		var thimble: ThimbleProjectile = shots.spawn(ThimbleProjectile) as ThimbleProjectile
		thimble.launch(self, target.position)
	return true


## Living zombies inside the visible part of the world.
func _on_screen(manager: EnemyManager) -> Array[Zombie]:
	var viewport: Viewport = get_viewport()
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var result: Array[Zombie] = []
	for zombie: Zombie in manager.zombies:
		if not zombie.dead and view.has_point(zombie.position):
			result.append(zombie)
	return result
