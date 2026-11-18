class_name PlushieGait
extends Resource
## How a plushie walks (issue #147): its own little puppet walk like Banane's. A sub-resource of
## each PlushieDef, so tuning a walk is a data change. STEP = feet take turns lifting, arms swing
## the other way, the body bobs up on each step (a big `tilt` turns it into Böbö's heavy waddle).
## HOP = Robbar's seal wobble: the whole blob hops, stretches in the air and squashes on landing
## while the flippers paddle. Lengths are in the plushie's drawing unit `u`.

enum Kind { STEP, HOP }

@export var kind: Kind = Kind.STEP
## Steps (or hops) per second.
@export var steps_per_second: float = 3.6
## How high a lifted foot goes (u).
@export var foot_lift: float = 0.16
## How far a foot reaches forward and back (u).
@export var foot_reach: float = 0.1
## How far the arms (or flippers) swing (radians).
@export var arm_swing: float = 0.35
## How far the body bobs up on each step (u).
@export var body_bob: float = 0.08
## How far the whole plushie rocks side to side (radians).
@export var tilt: float = 0.04
## How high a hop goes (u).
@export var hop_height: float = 0.0
## Squash on landing and stretch in the air (0 = none, 0.2 = 20%).
@export var squash: float = 0.0


## The walk at `seconds` into it; `amount` (0..1) blends from standing still to the full walk.
func pose(seconds: float, amount: float) -> PlushiePose:
	var result: PlushiePose = PlushiePose.new()
	if amount <= 0.0:
		return result
	# One full cycle = two steps (left, then right) or two hops.
	var turn: float = seconds * steps_per_second * PI
	var s: float = sin(turn)
	if kind == Kind.HOP:
		_hop(result, turn, amount)
	else:
		_step(result, s, cos(turn), amount)
	return result


func _step(result: PlushiePose, s: float, c: float, amount: float) -> void:
	result.feet = [
		Vector2(c * foot_reach, -maxf(s, 0.0) * foot_lift) * amount,
		Vector2(-c * foot_reach, -maxf(-s, 0.0) * foot_lift) * amount,
	]
	result.arms = [s * arm_swing * amount, s * arm_swing * amount]
	result.body_lift = absf(s) * body_bob * amount
	result.tilt = s * tilt * amount


func _hop(result: PlushiePose, turn: float, amount: float) -> void:
	var up: float = absf(sin(turn))
	var ground: float = (1.0 - up) * (1.0 - up)
	result.hop = up * hop_height * amount
	var stretch: float = (up * 0.5 - ground) * squash * amount
	result.squash = Vector2(1.0 - stretch, 1.0 + stretch)
	var paddle: float = sin(turn * 2.0) * arm_swing * amount
	result.arms = [paddle, paddle]
	result.tilt = sin(turn) * tilt * amount
