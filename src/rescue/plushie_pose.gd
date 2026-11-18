class_name PlushiePose
extends RefCounted
## One moment of a plushie's walk (made by PlushieGait, drawn by PlushieLook). Offsets are in
## units of the plushie's drawing unit `u` (size x height), so one gait fits every size.

## Offset of each foot (left, right) from where it stands: x forward, y up is negative.
var feet: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
## Extra turn of each arm or flipper (left, right), radians.
var arms: Array[float] = [0.0, 0.0]
## How far the body sits above the feet (u). The feet stay on the ground.
var body_lift: float = 0.0
## How far the whole plushie is off the ground (u, a hop).
var hop: float = 0.0
## The whole plushie rocks around its feet by this much (radians, a waddle).
var tilt: float = 0.0
## Squash and stretch of the whole plushie (1 = none).
var squash: Vector2 = Vector2.ONE


## The offset of the left (`side` < 0) or right foot.
func foot(side: float) -> Vector2:
	return feet[0 if side < 0.0 else 1]


## The extra turn of the left (`side` < 0) or right arm.
func arm(side: float) -> float:
	return arms[0 if side < 0.0 else 1]


## True when nothing moves (standing still).
func is_rest() -> bool:
	return (
		feet[0] == Vector2.ZERO
		and feet[1] == Vector2.ZERO
		and arms[0] == 0.0
		and arms[1] == 0.0
		and body_lift == 0.0
		and hop == 0.0
		and tilt == 0.0
		and squash == Vector2.ONE
	)
