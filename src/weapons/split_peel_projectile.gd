class_name SplitPeelProjectile
extends BoomerangProjectile
## A Banana Split peel: where it turns to fly back, two more peels split off to the sides. They
## fly apart for a moment, then home in on the player too.

## How far the split-off peels fly to the side of the way back, in degrees.
const SPLIT_DEGREES: float = 40.0
## How long they fly straight apart before turning home.
const SPLIT_TIME: float = 0.18

## True for the two peels that split off (they don't split again).
var split_off: bool = false

var _apart_left: float = 0.0


func reset() -> void:
	super()
	split_off = false
	_apart_left = 0.0


func advance(delta: float) -> bool:
	if _apart_left > 0.0:
		_apart_left -= delta
		global_position += _direction * _numbers.speed * delta
		_hit_zombies()
		rotation += SPIN_SPEED * delta
		return true
	var was_returning: bool = returning
	var alive: bool = super(delta)
	if alive and returning and not was_returning and not split_off:
		_split()
	return alive


func _split() -> void:
	var home: Vector2 = global_position.direction_to(_boomerang.player.global_position)
	for side: float in [-1.0, 1.0]:
		var piece: SplitPeelProjectile = manager.spawn(SplitPeelProjectile) as SplitPeelProjectile
		piece.launch(_boomerang, home.rotated(deg_to_rad(SPLIT_DEGREES) * side))
		piece.global_position = global_position
		piece.returning = true
		piece.split_off = true
		piece._apart_left = SPLIT_TIME
