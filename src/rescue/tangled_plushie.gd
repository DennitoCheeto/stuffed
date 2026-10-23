class_name TangledPlushie
extends Node2D
## A plushie that isn't fully zombified yet, tangled in a ball of zombie yarn (spec 03 §7).
## While any living player stands next to it, a ring fills; moving away pauses the ring (it
## doesn't empty). When the ring is full the plushie hops into the player's backpack.
## Soft lilac, never the red/orange of danger (hard rule 9).

## The ring is full: the plushie is free (tells only once).
signal freed(player: Player)

## Soft lilac glow, ring and edge arrow.
const GLOW_COLOR: Color = Color("#d4b8ff")
const RING_COLOR: Color = Color("#f4ecff")
## The dull zombie yarn it is tangled in.
const YARN_COLOR: Color = Color("#7c7390")
const YARN_DARK: Color = Color("#5a526b")
## The plushie's head radius (pixels).
const SIZE: float = 22.0
## Yarn strands while it is still fully tangled; they fall away as the ring fills.
const STRANDS: int = 10
## It wriggles this often (per second) while tangled.
const WRIGGLE_SPEED: float = 1.6
## The hop into the backpack takes this long (seconds) and goes this high (pixels).
const HOP_SECONDS: float = 0.5
const HOP_HEIGHT: float = 50.0

var rules: RescueRules
var plushie: PlushieDef
## 0..1: how full the ring is.
var fill: float = 0.0
## True once the ring is full.
var used: bool = false
## True while a living player stands next to it.
var occupied: bool = false

var _time: float = 0.0
## 0..1 through the hop into the backpack.
var _hop: float = 0.0
var _rescuer: Player


func setup(rescue_rules: RescueRules, who: PlushieDef) -> void:
	rules = rescue_rules
	plushie = who


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if used:
		_hop_to_backpack(delta)
		return
	var standing: Player = _player_near()
	occupied = standing != null
	if standing == null:
		return
	fill = minf(fill + delta / rules.fill_seconds, 1.0)
	if fill >= 1.0:
		used = true
		_rescuer = standing
		freed.emit(standing)


## Where the ring sits (world position): the plushie stands on `position`.
func middle() -> Vector2:
	return global_position + Vector2(0.0, -SIZE)


func _player_near() -> Player:
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		var reach: float = rules.stand_radius
		if middle().distance_squared_to(player.global_position) <= reach * reach:
			return player
	return null


## It follows its rescuer in a little hop, shrinks into the backpack and is gone.
func _hop_to_backpack(delta: float) -> void:
	_hop += delta / HOP_SECONDS
	if _hop >= 1.0:
		queue_free()
		return
	if is_instance_valid(_rescuer):
		position = position.lerp(_rescuer.global_position, minf(delta * 8.0, 1.0))
	scale = Vector2.ONE * (1.0 - 0.7 * _hop)


func _draw() -> void:
	if used:
		draw_set_transform(Vector2(0.0, -sin(PI * _hop) * HOP_HEIGHT))
		PlushieLook.draw(self, plushie, Vector2.ZERO, SIZE)
		return
	_draw_glow()
	_draw_ring()
	var wriggle: float = sin(_time * TAU * WRIGGLE_SPEED) * 0.08 * (1.0 - fill)
	draw_set_transform(Vector2.ZERO, wriggle)
	PlushieLook.draw(self, plushie, Vector2.ZERO, SIZE)
	_draw_yarn()
	draw_set_transform(Vector2.ZERO)


## A soft glow on the floor where you stand to free it.
func _draw_glow() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * TAU * 0.8)
	var glow: Color = GLOW_COLOR
	glow.a = 0.12 + 0.08 * pulse
	draw_circle(Vector2(0.0, -SIZE), rules.stand_radius, glow)


## The ring that fills while someone stands next to it (starts at the top, goes clockwise).
func _draw_ring() -> void:
	var middle: Vector2 = Vector2(0.0, -SIZE)
	var track: Color = RING_COLOR
	track.a = 0.45
	draw_arc(middle, rules.stand_radius, 0.0, TAU, 40, track, 4.0, true)
	if fill > 0.0:
		var start: float = -PI / 2.0
		draw_arc(middle, rules.stand_radius, start, start + TAU * fill, 40, RING_COLOR, 6.0, true)


## Loops of yarn wrapped round the plushie; fewer as the ring fills.
func _draw_yarn() -> void:
	var left: int = ceili(STRANDS * (1.0 - fill))
	for i: int in left:
		var middle: Vector2 = Vector2(sin(i * 2.3) * SIZE * 0.5, -SIZE * (0.6 + 0.16 * i))
		var radius: float = SIZE * (0.75 + 0.25 * sin(i * 1.7))
		var start: float = i * 1.9
		var color: Color = YARN_COLOR if i % 2 == 0 else YARN_DARK
		draw_arc(middle, radius, start, start + PI * 1.3, 14, color, 3.0, true)
