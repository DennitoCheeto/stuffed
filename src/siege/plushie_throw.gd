class_name PlushieThrow
extends Weapon
## A helping plushie's throw in the night siege (spec 07 §4, AC-79): a small stuffing ball at the
## nearest zombie in reach, every ~2 s. Weak (a bit of help, mostly charm). Mounted like a
## turret (`Weapon.mount`), so its damage counts under the plushies' row in the weapon tally.
## Numbers in data/siege/plushie_ball.tres.


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var target: Zombie = manager.nearest(origin(), mount_range)
	if target == null:
		return false
	var ball: StuffingBall = shots.spawn(StuffingBall) as StuffingBall
	ball.launch(self, origin().direction_to(target.position))
	return true
