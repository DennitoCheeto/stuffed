class_name RaincoatPuddle
extends Node2D
## One Raincoat puddle (spec 09 §3): a calm water streak from where a dash started to where it
## landed, `GearDef.radius` wide on each side. While it lasts it slows the zombies standing in it
## and pops enemy bullets that fly into it. It fades out over its last moments, then frees itself.
## Look (#328): a felt puddle, a deeper blue wobbly rim around a lighter pool, two stitched ripples
## that slowly spread and a small glint; it spreads in when it appears.

## A slowed zombie stays slow this long after leaving the puddle (seconds).
const LINGER_SECONDS: float = 0.25
const FADE_SECONDS: float = 0.5
const ROUND_POINTS: int = 12
## Roughly one edge point every this many pixels.
const SAMPLE_PIXELS: float = 6.0
## Seconds it takes to spread in (from `SPREAD_FROM` of its size) and fade in.
const SPREAD_SECONDS: float = 0.2
const SPREAD_FROM: float = 0.6
## The edge wobbles in and out by this share of the radius in a few big soft lobes
## (`WOBBLE_BUMPS` per round puddle), with a smaller ripple on top.
const WOBBLE: float = 0.13
const WOBBLE_BUMPS: float = 3.0
const SMALL_WOBBLE: float = 0.35
const SMALL_BUMPS: float = 2.6
## Rim (the whole puddle, a bit deeper blue) and the lighter pool inside it.
const RIM_ALPHA: float = 0.5
const RIM_DARKEN: float = 0.15
const POOL_ALPHA: float = 0.45
const POOL_LIGHTEN: float = 0.2
const POOL_SHARE: float = 0.78
## Ripple stitches: two drops at these shares of the way along the streak, each with rings at
## `RIPPLE_SHARES` of the radius, spreading by `RIPPLE_SPREAD` over the puddle's life; each ring
## is an open arc of `RIPPLE_ARC` of a full turn.
const DROP_SPOTS: PackedFloat32Array = [0.28, 0.72]
const RIPPLE_SHARES: PackedFloat32Array = [0.28, 0.52]
const RIPPLE_SPREAD: float = 0.14
const RIPPLE_ARC: float = 0.7
const RIPPLE_LIGHTEN: float = 0.55
const RIPPLE_ALPHA: float = 0.7
const STITCH_DASH: float = 5.0
const STITCH_GAP: float = 4.0
const STITCH_WIDTH: float = 1.6
## A small light oval near the top left.
const GLINT_ALPHA: float = 0.45
const GLINT_LIGHTEN: float = 0.8

var from: Vector2
var to: Vector2
var radius: float = 30.0
## How much slower zombies in it walk (0.3 = 30%).
var slow: float = 0.3
var color: Color = Color.WHITE
## Seconds left before it dries up.
var left: float = 0.0
## Seconds since it appeared.
var age: float = 0.0
## Zombies it slowed and enemy bullets it popped (tests).
var slowed: int = 0
var fizzled: int = 0
var _phase: float = 0.0
var _lifetime: float = 1.0


func setup(start: Vector2, end: Vector2, piece: GearDef, slow_share: float) -> void:
	from = start
	to = end
	radius = piece.radius
	slow = slow_share
	color = piece.effect_color
	left = piece.seconds
	_lifetime = maxf(piece.seconds, 0.01)
	_phase = randf() * TAU
	modulate.a = 0.0  # fades in from its first frame
	# Stays on the floor where the dash went, under the zombies.
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.FLOOR_MARKS


## True if `point` is in the puddle.
func covers(point: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(point, from, to).distance_to(point) <= radius


func _physics_process(delta: float) -> void:
	left -= delta
	age += delta
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
	var fade: float = minf(minf(left / FADE_SECONDS, age / SPREAD_SECONDS), 1.0)
	modulate.a = fade * GameSettings.own_effects
	queue_redraw()


func _draw() -> void:
	var size: float = drawn_radius()
	var wobble: float = size * WOBBLE
	var look: Array[Color] = look_colors(color)
	FeltDraw.fill(self, ring(size, wobble), look[0])
	FeltDraw.fill(self, ring(size * POOL_SHARE, wobble * POOL_SHARE), look[1])
	var stitches: PackedVector2Array = []
	var spread: float = RIPPLE_SPREAD * clampf(age / _lifetime, 0.0, 1.0)
	var drops: PackedFloat32Array = DROP_SPOTS
	if from.distance_to(to) < size:
		drops = PackedFloat32Array([0.5])
	for d: int in drops.size():
		var center: Vector2 = from.lerp(to, drops[d])
		for i: int in RIPPLE_SHARES.size():
			var start: float = _phase + d * 2.1 + i * 2.3
			var ring_size: float = size * (RIPPLE_SHARES[i] + spread)
			var arc: PackedVector2Array = _arc(center, ring_size, start)
			stitches.append_array(GearLook.stitches(arc, STITCH_DASH, STITCH_GAP))
	if not stitches.is_empty():
		draw_multiline(stitches, look[2], STITCH_WIDTH)
	FeltDraw.fill(self, _glint(size), look[3])


## The look's colours made from the piece's `effect_color`: rim, pool, ripple stitches, glint.
static func look_colors(base: Color) -> Array[Color]:
	return [
		Color(base.darkened(RIM_DARKEN), RIM_ALPHA),
		Color(base.lightened(POOL_LIGHTEN), POOL_ALPHA),
		Color(base.lightened(RIPPLE_LIGHTEN), RIPPLE_ALPHA),
		Color(base.lightened(GLINT_LIGHTEN), GLINT_ALPHA),
	]


## Radius it is drawn at right now (it spreads in when it appears; `radius` is what counts).
func drawn_radius() -> float:
	var grown: float = ease(clampf(age / SPREAD_SECONDS, 0.0, 1.0), 0.4)
	return radius * lerpf(SPREAD_FROM, 1.0, grown)


## The puddle's edge: a capsule around the dash path (a circle when the dash went nowhere).
func outline() -> PackedVector2Array:
	return ring(drawn_radius(), drawn_radius() * WOBBLE)


## Points `size` px around the dash path (a capsule, a circle when the dash went nowhere), the
## edge wobbling in and out by `wobble` px.
func ring(size: float, wobble: float) -> PackedVector2Array:
	var length: float = from.distance_to(to)
	var along: Vector2 = from.direction_to(to) if length >= 1.0 else Vector2.RIGHT
	if length < 1.0:
		length = 0.0
	var normal: Vector2 = along.orthogonal()
	var half_turn: float = PI * size
	var around: float = 2.0 * length + 2.0 * half_turn
	# Whole numbers of bumps, so the wobble meets itself where the ring closes.
	var bumps: float = maxf(roundf(around * WOBBLE_BUMPS / (TAU * maxf(size, 1.0))), 3.0)
	var small_bumps: float = roundf(bumps * SMALL_BUMPS)
	var count: int = maxi(roundi(around / SAMPLE_PIXELS), 8)
	var points: PackedVector2Array = []
	for i: int in count:
		var s: float = around * i / count
		var spot: Vector2 = from
		var out: Vector2 = (-normal).rotated((s - 2.0 * length - half_turn) / maxf(size, 0.01))
		if s < length:
			spot = from + along * s
			out = normal
		elif s < length + half_turn:
			spot = to
			out = normal.rotated((s - length) / size)
		elif s < 2.0 * length + half_turn:
			spot = to - along * (s - length - half_turn)
			out = -normal
		var turn: float = TAU * s / around
		var bump: float = sin(bumps * turn + _phase)
		bump += SMALL_WOBBLE * sin(small_bumps * turn - _phase)
		points.append(spot + out * (size + wobble * bump))
	return points


## An open stitched arc of `RIPPLE_ARC` of a circle around `center`, starting at angle `start`.
func _arc(center: Vector2, size: float, start: float) -> PackedVector2Array:
	var count: int = maxi(roundi(TAU * size * RIPPLE_ARC / SAMPLE_PIXELS), 6)
	var points: PackedVector2Array = []
	for i: int in count + 1:
		points.append(center + Vector2.from_angle(start + TAU * RIPPLE_ARC * i / count) * size)
	return points


## A small light oval near the top left of the puddle's start.
func _glint(size: float) -> PackedVector2Array:
	var middle: Vector2 = from + Vector2(-0.3, -0.38) * size
	var points: PackedVector2Array = []
	for i: int in ROUND_POINTS:
		var angle: float = TAU * i / ROUND_POINTS
		points.append(middle + Vector2(cos(angle) * 0.2, sin(angle) * 0.08) * size)
	return points
