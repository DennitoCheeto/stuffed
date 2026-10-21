class_name BananaPeel
extends Node2D
## A banana peel on the floor (Slippery). The first zombies to step on it slip and are stunned,
## then it is used up. It also disappears after its lifetime.

## Zombies slipped on this peel (for the "zwiip" sound later).
signal slipped(zombies: int)

const COLOR: Color = Color("#f2d65a")
const EDGE_COLOR: Color = Color("#b49a2c")
const POP_IN_TIME: float = 0.15
const FADE_TIME: float = 0.4

var lifetime: float = 4.0
var stun: float = 1.0
var radius: float = 18.0
var used: bool = false

var _age: float = 0.0
var _shape: PackedVector2Array = []


func _ready() -> void:
	_shape = FeltShapes.svg_path(
		PackedFloat32Array([-16, 4, -10, -12, 10, -12, 16, 4, 8, -4, -8, -4, -16, 4])
	)
	rotation = randf_range(-0.6, 0.6)
	scale = Vector2.ZERO


func _physics_process(delta: float) -> void:
	_age += delta
	scale = Vector2.ONE * minf(_age / POP_IN_TIME, 1.0) * 1.3
	if _age >= lifetime:
		remove()
		return
	modulate.a = clampf((lifetime - _age) / FADE_TIME, 0.0, 1.0)
	var group: StringName = EnemyManager.GROUP
	var manager: EnemyManager = get_tree().get_first_node_in_group(group) as EnemyManager
	if manager == null:
		return
	var victims: Array[Zombie] = manager.query_circle(global_position, radius)
	if victims.is_empty():
		return
	for zombie: Zombie in victims:
		zombie.stun(stun)
	slipped.emit(victims.size())
	remove()


func remove() -> void:
	used = true
	queue_free()


func _draw() -> void:
	draw_colored_polygon(FeltShapes.shifted(_shape, Vector2(1.0, 2.0)), EDGE_COLOR)
	draw_colored_polygon(_shape, COLOR)
