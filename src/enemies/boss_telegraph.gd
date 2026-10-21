class_name BossTelegraph
extends Node2D
## A boss's warning on the floor (vision §6.1: danger is always shown before it happens):
## a red lane for a charge, a red ring for a stomp. It fills up as the attack comes closer.
## A child of its boss, drawn under everyone else in the world (above the floor).

enum Kind { NONE, CHARGE, STOMP }

const COLOR: Color = Color("#ff2a2a")
const EDGE_WIDTH: float = 4.0
## Fill strength at the start and at the end of the telegraph.
const FILL_ALPHA: Vector2 = Vector2(0.15, 0.45)
const RING_POINTS: int = 48

var kind: Kind = Kind.NONE
## Charge: from the boss to the end of his path, in pixels.
var path: Vector2 = Vector2.ZERO
## Charge: width of the lane (the boss's body).
var lane_width: float = 0.0
## Stomp: radius of the ring.
var ring_radius: float = 0.0
## 0 = just shown, 1 = the attack comes now.
var progress: float = 0.0


func _init() -> void:
	z_index = -1
	visible = false


func show_charge(charge_path: Vector2, width: float) -> void:
	kind = Kind.CHARGE
	path = charge_path
	lane_width = width
	_show()


func show_stomp(radius: float) -> void:
	kind = Kind.STOMP
	ring_radius = radius
	_show()


func clear() -> void:
	kind = Kind.NONE
	visible = false


func is_showing() -> bool:
	return kind != Kind.NONE


func set_progress(amount: float) -> void:
	progress = amount
	queue_redraw()


func _show() -> void:
	progress = 0.0
	visible = true
	queue_redraw()


func _draw() -> void:
	var fill: Color = Color(COLOR, lerpf(FILL_ALPHA.x, FILL_ALPHA.y, progress))
	match kind:
		Kind.CHARGE:
			var side: Vector2 = path.orthogonal().normalized() * lane_width * 0.5
			var lane: PackedVector2Array = [side, path + side, path - side, -side]
			draw_colored_polygon(lane, fill)
			draw_line(side, path + side, COLOR, EDGE_WIDTH)
			draw_line(-side, path - side, COLOR, EDGE_WIDTH)
			draw_line(path + side, path - side, COLOR, EDGE_WIDTH)
			# A bright line grows along the lane: when it reaches the end, he goes.
			draw_line(Vector2.ZERO, path * progress, COLOR, EDGE_WIDTH * 2.0)
		Kind.STOMP:
			draw_circle(Vector2.ZERO, ring_radius * progress, fill)
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, RING_POINTS, COLOR, EDGE_WIDTH)
