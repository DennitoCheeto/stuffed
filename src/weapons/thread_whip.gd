class_name ThreadWhip
extends Weapon
## Aimed weapon: a quick lash of thread in a wide arc towards the player's cursor. Every zombie
## inside the arc is hurt at once. Area is the arc's radius, spread its width in degrees; with a
## count of 2 the second lash goes the other way (behind the player).


func attack() -> bool:
	var manager: EnemyManager = enemies()
	var shots: ProjectileManager = projectiles()
	if manager == null or shots == null:
		return false
	var aim: Vector2 = player.global_position.direction_to(player.aim_point())
	if aim == Vector2.ZERO:
		aim = player.facing
	for i: int in current().count:
		var lash: WhipProjectile = shots.spawn(WhipProjectile) as WhipProjectile
		lash.launch(self, aim.rotated(PI * i))
	return true
