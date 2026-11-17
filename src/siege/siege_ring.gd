class_name SiegeRing
extends Node2D
## A building helper's ring on the ground in the night siege (spec 07 §4): a soft stitched
## circle around the building that shows how far it reaches (the Snack Bar's healing ring, the
## Party Shop's confetti trap). It sits on the floor, under the buildings and the heroes, in a
## calm colour (never enemy danger, AC-83). It stops for good when its building is knocked down
## or the siege ends. Subclasses do the work in `_work(delta)` and set `glow` (0..1) for the look.

## Stitches around the ring and how much of each step is thread.
const STITCHES: int = 32
const STITCH_SHARE: float = 0.6
const WIDTH: float = 5.0
## Ring opacity at rest and at full glow; the soft fill inside at full glow.
const REST_ALPHA: float = 0.5
const GLOW_ALPHA: float = 0.95
const FILL_ALPHA: float = 0.14

var building: SiegeBuilding
## Reach from the middle of the building's footprint (pixels).
var radius: float = 0.0
var color: Color = Color.WHITE
## 0..1: how strongly the ring shows right now.
var glow: float = 0.0

var _active: bool = true


## Puts the ring around `target` (`at` = the footprint's middle, world position).
func place(target: SiegeBuilding, reach: float, at: Vector2, ring_color: Color) -> void:
	building = target
	radius = reach
	position = at
	color = ring_color
	building.fell.connect(stop)


## True while it still works (its building stands and the siege goes on).
func is_active() -> bool:
	return _active


func stop() -> void:
	_active = false
	glow = 0.0
	queue_redraw()


## True when `point` (world position) is inside the ring.
func covers(point: Vector2) -> bool:
	return position.distance_squared_to(point) <= radius * radius


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var before: float = glow
	_work(delta)
	if not is_equal_approx(before, glow):
		queue_redraw()


## What the helper does each physics tick (only while active).
func _work(_delta: float) -> void:
	pass


func _draw() -> void:
	if not _active:
		return
	var ring: Color = color
	ring.a = lerpf(REST_ALPHA, GLOW_ALPHA, glow)
	if glow > 0.0:
		var fill: Color = color
		fill.a = FILL_ALPHA * glow
		draw_circle(Vector2.ZERO, radius, fill)
	var step: float = TAU / STITCHES
	for i: int in STITCHES:
		var start: float = i * step
		draw_arc(Vector2.ZERO, radius, start, start + step * STITCH_SHARE, 4, ring, WIDTH, true)
