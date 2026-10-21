class_name SpitAttack
extends Resource
## How a ranged zombie (the spitter) fights: it keeps some distance, puffs up for a moment (the
## wind-up), then spits slow stuffing balls at the nearest player. Its volleys follow `pattern`
## (e.g. a single ball, then a 3-ball fan, and again). Tune it in data/enemies/*.tres, not in code.

## It tries to stay about this far from the nearest player, in pixels ...
@export var keep_distance: float = 260.0
## ... and stands still while it is within this much of that distance.
@export var distance_band: float = 50.0
## It only starts a wind-up when the nearest player is at most this far away.
@export var fire_range: float = 480.0
## How long it visibly puffs up before every volley.
@export var windup_seconds: float = 0.6
## Seconds between volleys (after the shot, before the next wind-up).
@export var cooldown_seconds: float = 2.4
## The first wind-up starts at the earliest this long after it appears.
@export var first_delay_seconds: float = 1.0
## Balls per volley, used in turn (1 = a single ball, 3 = a fan of three).
@export var pattern: Array[int] = [1, 3]
## Angle between neighbouring balls of a fan, in degrees.
@export var fan_step_degrees: float = 18.0
## Pixels per second. Always slower than the heroes (spec 02 §8).
@export var bullet_speed: float = 110.0
@export var bullet_damage: float = 8.0
## Hit radius in pixels.
@export var bullet_radius: float = 8.0
## Seconds before a ball runs out.
@export var bullet_lifetime: float = 6.0


## How many balls volley number `volley` (0 = the first) has.
func balls_in_volley(volley: int) -> int:
	if pattern.is_empty():
		return 1
	return maxi(pattern[volley % pattern.size()], 1)


## Directions of the balls of one volley aimed along `aim` (a fan is centred on it).
func directions(aim: Vector2, balls: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var step: float = deg_to_rad(fan_step_degrees)
	for i: int in balls:
		result.append(aim.rotated((i - (balls - 1) / 2.0) * step))
	return result
