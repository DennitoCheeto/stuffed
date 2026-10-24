class_name TownPlushie
extends Node2D
## A rescued plushie living in the Pillow Fort (spec 03 §7, AC-45): it walks around, sits on
## cushions, stops to wave when a player comes close, and has a name tag. A plushie that just
## moved in plays the stitch-up moment first (it pops up at the Plush Hospital with stitches
## flying). It never blocks anyone. Numbers in PlushieTownRules.

enum State { STITCHING, IDLE, WALKING, SITTING, WAVING }

## How many random spots a plushie tries before it just waits a bit longer.
const TRIES: int = 12
## Steps (pixels) when checking that a walk doesn't cross a building.
const PATH_STEP: float = 20.0
const STITCH_COLOR: Color = Color("#f4ecff")
const NAME_SIZE: int = 20
const NAME_WIDTH: float = 200.0

var plushie: PlushieDef
var rules: PlushieTownRules
var layout: TownLayout
var state: State = State.IDLE
## Where the current walk ends.
var target: Vector2 = Vector2.ZERO
## How many times it waved at a player (tests read it).
var waves: int = 0
var name_tag: Label

## Seconds left in the current state (idle, sitting, waving, stitching).
var _left: float = 0.0
## True when the current walk ends on a cushion (it sits down there).
var _to_cushion: bool = false
## Seconds until it may wave again.
var _wave_wait: float = 0.0
## What it goes back to after a wave.
var _after_wave: State = State.IDLE
var _after_wave_left: float = 0.0
## 1 = looks right, -1 = looks left.
var _facing: float = 1.0
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## `stitched` = it already lives here (no stitch-up moment).
func _init(
	who: PlushieDef,
	town_rules: PlushieTownRules,
	town_layout: TownLayout,
	at: Vector2,
	stitched: bool
) -> void:
	plushie = who
	rules = town_rules
	layout = town_layout
	position = at
	target = at
	name = "Plushie_" + who.id
	_rng.seed = hash(who.id) + roundi(at.x)
	if stitched:
		_rest()
	else:
		state = State.STITCHING
		_left = rules.stitch_seconds


func _ready() -> void:
	name_tag = TownArt.label(plushie.display_name, NAME_SIZE)
	add_child(name_tag)
	var top: float = PlushieLook.top(plushie, rules.size)
	TownArt.center_label(name_tag, 0.0, -top - 34.0, NAME_WIDTH)


func _physics_process(delta: float) -> void:
	_time += delta
	_wave_wait = maxf(_wave_wait - delta, 0.0)
	queue_redraw()
	if state == State.STITCHING:
		_left -= delta
		if _left <= 0.0:
			_rest()
		return
	if state != State.WAVING and _wave_wait <= 0.0:
		var near: Player = player_near()
		if near != null:
			_start_wave(near)
	match state:
		State.WALKING:
			_walk(delta)
		State.WAVING:
			var near: Player = player_near()
			if near != null:
				_look_at(near.global_position)
			_left -= delta
			if _left <= 0.0:
				state = _after_wave
				_left = _after_wave_left
		_:
			_left -= delta
			if _left <= 0.0:
				_pick_walk()


func is_stitching() -> bool:
	return state == State.STITCHING


## The nearest living player within waving distance (null = none).
func player_near() -> Player:
	var best: Player = null
	var best_distance: float = rules.wave_radius
	for player: Player in Players.all(get_tree()):
		var distance: float = player.global_position.distance_to(global_position)
		if distance <= best_distance:
			best = player
			best_distance = distance
	return best


## 0..1: how high the waving arm is right now.
func wave_amount() -> float:
	if state != State.WAVING:
		return 0.0
	return 0.55 + 0.45 * sin(_time * TAU * 2.5)


## True when a plushie may stand at `point`: on the blanket and clear of every building.
static func is_walkable(town_layout: TownLayout, point: Vector2, margin: float) -> bool:
	if not town_layout.play_rect().grow(-margin).has_point(point):
		return false
	for rect: Rect2 in town_layout.blocking_rects():
		if rect.grow(margin).has_point(point):
			return false
	return true


## True when a straight walk from `from` to `to` stays clear of every building.
static func is_path_clear(
	town_layout: TownLayout, from: Vector2, to: Vector2, margin: float
) -> bool:
	var steps: int = maxi(ceili(from.distance_to(to) / PATH_STEP), 1)
	for i: int in range(1, steps + 1):
		if not is_walkable(town_layout, from.lerp(to, float(i) / steps), margin):
			return false
	return true


func _rest() -> void:
	state = State.IDLE
	_left = _rng.randf_range(rules.idle_min_seconds, rules.idle_max_seconds)


func _start_wave(player: Player) -> void:
	_after_wave = state
	_after_wave_left = _left
	state = State.WAVING
	_left = rules.wave_seconds
	_wave_wait = rules.wave_seconds + rules.wave_cooldown
	waves += 1
	Sfx.play(rules.wave_sound)
	_look_at(player.global_position)


## Picks the next walk: sometimes to a cushion, else somewhere nearby. Waits if nothing fits.
func _pick_walk() -> void:
	for i: int in TRIES:
		var cushion: bool = not layout.cushions.is_empty() and _rng.randf() < rules.sit_chance
		var spot: Vector2 = _cushion_spot() if cushion else _nearby_spot()
		if is_walkable(layout, spot, rules.keep_clear) and _can_walk_to(spot):
			target = spot
			_to_cushion = cushion
			state = State.WALKING
			return
	_rest()


func _cushion_spot() -> Vector2:
	var index: int = _rng.randi_range(0, layout.cushions.size() - 1)
	return layout.cushions[index] + Vector2(0.0, 20.0)


func _nearby_spot() -> Vector2:
	var direction: Vector2 = Vector2.from_angle(_rng.randf() * TAU)
	return position + direction * rules.walk_distance * _rng.randf_range(0.3, 1.0)


## A walk may start inside the keep-clear zone (right at the Hospital door): only the rest of
## the way must be clear.
func _can_walk_to(spot: Vector2) -> bool:
	var start: Vector2 = position
	if not is_walkable(layout, start, rules.keep_clear):
		start = position.move_toward(spot, rules.keep_clear * 2.0)
	return is_path_clear(layout, start, spot, rules.keep_clear)


func _walk(delta: float) -> void:
	_look_at(target)
	position = position.move_toward(target, rules.walk_speed * delta)
	if position.distance_to(target) > 0.5:
		return
	if _to_cushion:
		state = State.SITTING
		_left = _rng.randf_range(rules.sit_min_seconds, rules.sit_max_seconds)
	else:
		_rest()


func _look_at(point: Vector2) -> void:
	if absf(point.x - position.x) > 2.0:
		_facing = signf(point.x - position.x)


func _draw() -> void:
	var bob: float = 0.0
	if state == State.WALKING:
		bob = -absf(sin(_time * TAU * 1.8)) * rules.bob_pixels
	var squash: Vector2 = Vector2(_facing, 1.0)
	if state == State.SITTING:
		squash = Vector2(_facing * 1.06, 0.9)
	var stitch: float = 1.0
	if state == State.STITCHING:
		stitch = 1.0 - _left / rules.stitch_seconds
		squash *= lerpf(0.4, 1.0, minf(stitch * 2.0, 1.0))
	draw_set_transform(Vector2(0.0, bob), 0.0, squash)
	PlushieLook.draw(self, plushie, Vector2.ZERO, rules.size, wave_amount())
	draw_set_transform(Vector2.ZERO)
	if state == State.STITCHING:
		_draw_stitches(stitch)


## The stitch-up moment: little cross stitches fly out around it and fade.
func _draw_stitches(progress: float) -> void:
	var middle: Vector2 = Vector2(0.0, -PlushieLook.top(plushie, rules.size) / 2.0)
	var color: Color = Color(STITCH_COLOR, 1.0 - progress)
	var reach: float = 30.0 + 50.0 * progress
	for i: int in 8:
		var at: Vector2 = middle + Vector2.from_angle(TAU * i / 8.0 + progress) * reach
		draw_line(at + Vector2(-6, -6), at + Vector2(6, 6), color, 3.0, true)
		draw_line(at + Vector2(-6, 6), at + Vector2(6, -6), color, 3.0, true)
