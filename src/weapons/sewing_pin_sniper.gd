class_name SewingPinSniper
extends Weapon
## Aimed weapon: fires a long sewing pin towards the player's cursor on its own rhythm (no
## clicking). Fast, hits hard, pierces through zombies in a line.


func attack() -> bool:
	var manager: EnemyManager = enemies()
	if manager == null:
		return false
	var numbers: WeaponLevel = current()
	var aim: Vector2 = player.global_position.direction_to(player.aim_point())
	if aim == Vector2.ZERO:
		aim = player.facing
	Sfx.play(&"pin")
	var spread: float = deg_to_rad(numbers.spread_degrees)
	for i: int in numbers.count:
		var offset: float = (i - (numbers.count - 1) / 2.0) * spread
		var pin: PinProjectile = PinProjectile.new()
		pin.top_level = true
		add_child(pin)
		pin.launch(self, manager, aim.rotated(offset))
	return true
