class_name RaincoatPuddle
extends Node2D
## One Raincoat puddle (spec 09 §3): a calm water streak from where a dash started to where it
## landed, `GearDef.radius` wide on each side. While it lasts it slows the zombies standing in it
## and pops enemy bullets that fly into it. It fades out over its last moments, then frees itself.

## A slowed zombie stays slow this long after leaving the puddle (seconds).
const LINGER_SECONDS: float = 0.25
const FADE_SECONDS: float = 0.5
const ALPHA: float = 0.45
const ROUND_POINTS: int = 12

var from: Vector2
var to: Vector2
var radius: float = 30.0
## How much slower zombies in it walk (0.3 = 30%).
var slow: float = 0.3
var color: Color = Color.WHITE
## Seconds left before it dries up.
var left: float = 0.0
## Zombies it slowed and enemy bullets it popped (tests).
var slowed: int = 0
var fizzled: int = 0


func setup(start: Vector2, end: Vector2, piece: GearDef, slow_share: float) -> void:
	from = start
	to = end
	radius = piece.radius
	slow = slow_share
	color = piece.effect_color
	left = piece.seconds
	# Stays on the floor where the dash went, under the zombies.
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.FLOOR_MARKS


## True if `point` is in the puddle.
func covers(point: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(point, from, to).distance_to(point) <= radius


func _physics_process(delta: float) -> void:
	left -= delta
	if left <= 0.0:
		queue_free()
		return
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager != null:
		var middle: Vector2 = (from + to) / 2.0
		var reach: float = from.distance_to(to) / 2.0 + radius
		for zombie: Zombie in manager.query_circle(middle, reach):
			if not zombie.dead and covers(zombie.position):
				zombie.slow(slow, LINGER_SECONDS)
				slowed += 1
		var shots: ProjectileManager = manager.get_tree().get_first_node_in_group(
			ProjectileManager.GROUP
		)
		if shots != null:
			fizzled += shots.pop_enemy_bullets_where(covers).size()
	modulate.a = minf(left / FADE_SECONDS, 1.0) * GameSettings.own_effects
	queue_redraw()


func _draw() -> void:
	FeltDraw.fill(self, outline(), Color(color, ALPHA))


## The puddle's edge: a capsule around the dash path (a circle when the dash went nowhere).
func outline() -> PackedVector2Array:
	if from.distance_to(to) < 1.0:
		return FeltDraw.circle(from, radius, ROUND_POINTS * 2)
	var side: float = (to - from).angle() + PI / 2.0
	var points: PackedVector2Array = []
	for i: int in ROUND_POINTS + 1:
		points.append(from + Vector2.from_angle(side + PI * i / ROUND_POINTS) * radius)
	for i: int in ROUND_POINTS + 1:
		points.append(to + Vector2.from_angle(side + PI + PI * i / ROUND_POINTS) * radius)
	return points
