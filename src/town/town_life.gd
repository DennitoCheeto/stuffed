class_name TownLife
extends Node2D
## Ambient motion over the Pillow Fort (spec 05 §3.4): soft see-through sunbeams slanting across
## the quilt with dust sparkles drifting up in them, and now and then a paper plane gliding over
## the town with its shadow on the floor. One node draws all of it (a few dozen shapes). Numbers
## in data/town/town_life_rules.tres, colours from the world palette.

const RULES: TownLifeRules = preload("res://data/town/town_life_rules.tres")
## Soft beam edges: the beam is drawn as a few nested bands (share of the width each).
const BEAM_BANDS: Array[float] = [1.0, 0.7, 0.4]

var layout: TownLayout
var rules: TownLifeRules = RULES
## Seconds since the town opened.
var elapsed: float = 0.0
## When the next paper plane takes off (seconds after the town opened).
var next_plane_at: float = 0.0
var planes_flown: int = 0
var plane_flying: bool = false
## The point on the floor under the plane (its shadow).
var plane_ground: Vector2 = Vector2.ZERO
## 1 = flies right, -1 = flies left.
var plane_direction: float = 1.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## One per sparkle: x = where across its beam (0..1), y = where along it at the start (0..1).
var _sparkles: PackedVector2Array = []


func _init(town_layout: TownLayout) -> void:
	layout = town_layout
	name = "Life"
	_rng.seed = 1906
	next_plane_at = rules.plane_first_at
	for i: int in rules.sunbeam_starts.size() * rules.sparkles_per_beam:
		_sparkles.append(Vector2(_rng.randf_range(0.1, 0.9), _rng.randf()))


func _process(delta: float) -> void:
	elapsed += delta
	_fly(delta)
	queue_redraw()


## The corners of sunbeam `index` (top-left, top-right, bottom-right, bottom-left).
func beam(index: int, share: float = 1.0) -> PackedVector2Array:
	var top: float = -layout.wall_thickness
	var height: float = layout.size.y + layout.wall_thickness * 2.0
	var width: float = rules.sunbeam_width * share
	var left: float = rules.sunbeam_starts[index] + (rules.sunbeam_width - width) / 2.0
	var shift: float = rules.sunbeam_slant * height
	return [
		Vector2(left, top),
		Vector2(left + width, top),
		Vector2(left + width + shift, top + height),
		Vector2(left + shift, top + height),
	]


func beam_count() -> int:
	return rules.sunbeam_starts.size()


## Where every dust sparkle is right now (town pixels).
func sparkle_positions() -> PackedVector2Array:
	var result: PackedVector2Array = []
	for i: int in _sparkles.size():
		result.append(_sparkle_at(i))
	return result


## Where the paper plane is in the air (only meaningful while `plane_flying`).
func plane_position() -> Vector2:
	var bob: float = sin(elapsed * 1.3) * rules.plane_bob
	return plane_ground + Vector2(0.0, -rules.plane_height + bob)


func _sparkle_at(i: int) -> Vector2:
	var corners: PackedVector2Array = beam(floori(float(i) / rules.sparkles_per_beam))
	var length: float = corners[3].y - corners[0].y
	var along: float = fposmod(_sparkles[i].y - elapsed * rules.sparkle_drift / length, 1.0)
	var top: Vector2 = corners[0].lerp(corners[1], _sparkles[i].x)
	var bottom: Vector2 = corners[3].lerp(corners[2], _sparkles[i].x)
	return top.lerp(bottom, along)


func _fly(delta: float) -> void:
	if not plane_flying:
		if elapsed >= next_plane_at:
			_launch()
		return
	plane_ground.x += plane_direction * rules.plane_speed * delta
	var margin: float = _plane_margin()
	if plane_ground.x < -margin or plane_ground.x > layout.size.x + margin:
		plane_flying = false
		planes_flown += 1
		next_plane_at = elapsed + _rng.randf_range(rules.plane_min_gap, rules.plane_max_gap)


func _launch() -> void:
	plane_flying = true
	plane_direction = 1.0 if _rng.randf() < 0.5 else -1.0
	var margin: float = _plane_margin()
	var x: float = -margin if plane_direction > 0.0 else layout.size.x + margin
	plane_ground = Vector2(x, _rng.randf_range(0.25, 0.9) * layout.size.y)


func _plane_margin() -> float:
	return layout.wall_thickness + rules.plane_size * 2.0


func _draw() -> void:
	var palette: WorldPalette = WorldPalette.current()
	var light: Color = palette.sunbeam
	var band_alpha: float = light.a * rules.sunbeam_strength / BEAM_BANDS.size()
	for i: int in beam_count():
		for share: float in BEAM_BANDS:
			draw_colored_polygon(beam(i, share), Color(light, band_alpha))
	for i: int in _sparkles.size():
		var phase: float = elapsed * rules.sparkle_twinkle + _sparkles[i].y
		var twinkle: float = 0.5 + 0.5 * sin(phase * TAU)
		var r: float = rules.sparkle_size * (0.4 + 0.6 * twinkle)
		var star: PackedVector2Array = BuildingSketch.star(_sparkle_at(i), r)
		draw_colored_polygon(star, Color(palette.sparkle, 0.35 + 0.55 * twinkle))
	if plane_flying:
		_draw_plane(palette)


## A folded paper plane: two wings with a crease, an ink outline and a soft shadow below.
func _draw_plane(palette: WorldPalette) -> void:
	var s: float = rules.plane_size
	var shadow: PackedVector2Array = FeltDraw.circle(Vector2.ZERO, 1.0, 12)
	var flat: Transform2D = Transform2D(0.0, Vector2(s * 0.5, s * 0.14), 0.0, plane_ground)
	draw_colored_polygon(flat * shadow, palette.shadow)
	var tilt: float = cos(elapsed * 1.3) * 0.12
	var at: Vector2 = plane_position()
	draw_set_transform(at, tilt * plane_direction, Vector2(plane_direction, 1.0))
	var nose: Vector2 = Vector2(s * 0.5, 0.0)
	var notch: Vector2 = Vector2(-s * 0.32, 0.0)
	var top_wing: PackedVector2Array = [nose, Vector2(-s * 0.5, -s * 0.34), notch]
	var low_wing: PackedVector2Array = [nose, notch, Vector2(-s * 0.5, s * 0.22)]
	draw_colored_polygon(low_wing, palette.tag.darkened(0.14))
	draw_colored_polygon(top_wing, palette.tag)
	var outline: PackedVector2Array = [nose, top_wing[1], notch, low_wing[2], nose]
	draw_polyline(outline, palette.ink, 2.0, true)
	draw_line(nose, notch, Color(palette.ink, 0.5), 1.2, true)
	draw_set_transform(Vector2.ZERO)
