class_name WayHomePortal
extends Node2D
## The Way Home portal (spec 03 §4): a glowing felt pillow door with soft swirls. While any
## living player stands in it, a ring fills; stepping out pauses the ring (it doesn't empty).
## A full ring takes everybody home. Soft blue and white, never the red/orange of danger.

## The ring is full: the run ends and everybody goes home (tells only once).
signal entered(player: Player)

## Soft blue glow, white felt and swirls, a darker blue outline (hard rule 9: never red/orange).
const GLOW_COLOR: Color = Color("#9fd0ff")
const FELT_COLOR: Color = Color("#eaf4ff")
const SWIRL_COLOR: Color = Color("#7fb6ec")
const OUTLINE_COLOR: Color = Color("#3d6c99")
## The pillow door's size (pixels); it stands on the portal's middle.
const DOOR_WIDTH: float = 84.0
const DOOR_HEIGHT: float = 120.0
## Swirls turn this many times per second; the glow breathes this often.
const SWIRL_SPEED: float = 0.35
const PULSE_SPEED: float = 0.8

var rules: WayHomeRules
## 0..1: how full the ring is.
var fill: float = 0.0
## True once the ring is full.
var used: bool = false
## True while a living player stands in it.
var occupied: bool = false

var _time: float = 0.0


func setup(portal_rules: WayHomeRules) -> void:
	rules = portal_rules


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if used:
		return
	var standing: Player = _player_inside()
	occupied = standing != null
	if standing == null:
		return
	fill = minf(fill + delta / rules.fill_seconds, 1.0)
	if fill >= 1.0:
		used = true
		entered.emit(standing)


func _player_inside() -> Player:
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		var reach: float = rules.stand_radius
		if position.distance_squared_to(player.global_position) <= reach * reach:
			return player
	return null


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * TAU * PULSE_SPEED)
	_draw_floor_glow(pulse)
	_draw_door(pulse)
	_draw_ring()


## A soft glow on the floor where you stand.
func _draw_floor_glow(pulse: float) -> void:
	var glow: Color = GLOW_COLOR
	for step: int in 3:
		glow.a = 0.12 + 0.06 * pulse
		draw_circle(Vector2.ZERO, rules.stand_radius * (1.0 - step * 0.25), glow)


## The pillow door: a rounded arch of white felt with a blue glow, swirls and stitches.
func _draw_door(pulse: float) -> void:
	var arch: PackedVector2Array = _arch(DOOR_WIDTH / 2.0, DOOR_HEIGHT)
	var halo: Color = GLOW_COLOR
	halo.a = 0.35 + 0.2 * pulse
	draw_colored_polygon(_arch(DOOR_WIDTH / 2.0 + 8.0, DOOR_HEIGHT + 8.0), halo)
	draw_colored_polygon(arch, FELT_COLOR)
	var middle: Vector2 = Vector2(0.0, -DOOR_HEIGHT * 0.5)
	for i: int in 3:
		var turn: float = _time * TAU * SWIRL_SPEED + i * TAU / 3.0
		var radius: float = 10.0 + i * 7.0
		draw_arc(middle, radius, turn, turn + PI * 1.2, 16, SWIRL_COLOR, 3.0, true)
	var closed: PackedVector2Array = arch.duplicate()
	closed.append(arch[0])
	draw_polyline(closed, OUTLINE_COLOR, 3.0, true)
	var stitches: PackedVector2Array = _arch(DOOR_WIDTH / 2.0 - 6.0, DOOR_HEIGHT - 6.0)
	for j: int in range(0, stitches.size() - 1, 2):
		draw_line(stitches[j], stitches[j + 1], SWIRL_COLOR, 2.0, true)


## The ring that fills while someone stands in it (starts at the top, goes clockwise).
func _draw_ring() -> void:
	var track: Color = FELT_COLOR
	track.a = 0.5
	draw_arc(Vector2.ZERO, rules.stand_radius, 0.0, TAU, 40, track, 4.0, true)
	if fill > 0.0:
		var start: float = -PI / 2.0
		var end: float = start + TAU * fill
		draw_arc(Vector2.ZERO, rules.stand_radius, start, end, 40, FELT_COLOR, 6.0, true)


## Outline of an arch `half_width` wide each side and `height` tall, standing on (0, 0).
func _arch(half_width: float, height: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(-half_width, 0.0)]
	var top: float = -height + half_width
	for i: int in 13:
		var angle: float = PI + PI * i / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * half_width + Vector2(0.0, top))
	points.append(Vector2(half_width, 0.0))
	return points
