class_name YarnCannon
extends Weapon
## Aimed weapon: fires a slow, heavy yarn ball towards the player's cursor on its own rhythm. It
## bursts on the first zombie it touches (or at the end of its reach) and hurts everything in
## the burst's area.


func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null or enemies() == null:
		return false
	var numbers: WeaponLevel = current()
	var aim: Vector2 = player.global_position.direction_to(player.aim_point())
	if aim == Vector2.ZERO:
		aim = player.facing
	Sfx.play(&"throw", 0.5)
	var spread: float = deg_to_rad(numbers.spread_degrees)
	for i: int in numbers.count:
		var offset: float = (i - (numbers.count - 1) / 2.0) * spread
		var ball: CannonProjectile = shots.spawn(CannonProjectile) as CannonProjectile
		ball.launch(self, aim.rotated(offset))
	return true
