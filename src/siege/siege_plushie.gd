class_name SiegePlushie
extends Node2D
## A plushie living in town helps in the night siege (spec 07 §4, AC-79): it stands by the fort
## and throws a small stuffing ball at the nearest zombie in reach every ~2 s (`PlushieThrow`,
## damage under the plushies' row in the weapon tally). Zombies passing close turn to it and can
## knock it out (`target` falls): it tips over, dizzy stars circle its head and it stops
## throwing. A standing Plush Hospital stands it back up after its revive time (12 / 8 / 5 s);
## without one (or once the Hospital is knocked down) it stays out until the siege ends. It is
## never lost. Drawn as one baked picture with its danger colours calmed. Numbers in
## `SiegeRules` ("Plushies") and `BuildingLevel.siege_revive_seconds`.

signal knocked_out
signal stood_up

## How high its throw starts (share of its height, from its feet).
const THROW_HEIGHT: float = 0.6
## Points of a dizzy star, its size and how far above its head the stars circle.
const STAR_POINTS: int = 5
const STAR_RADIUS: float = 6.0
const STAR_ORBIT: Vector2 = Vector2(16.0, 5.0)
const STAR_LIFT: float = 8.0
const STAR_OUTLINE: float = 1.5

## Its town look with the danger colours calmed.
var plushie: PlushieDef
## What the horde knocks at (a small patch of floor around its feet).
var target: SiegeTarget
## Its stuffing balls (a mounted weapon with no hero).
var throw: Weapon
var look: PlushiePicture
## The Plush Hospital fighting in this siege (null = none) and how long it takes to stand a
## knocked-out plushie back up.
var hospital: SiegeBuilding
var revive_seconds: float = 0.0
## Seconds until it stands back up (counts down only while the Hospital stands).
var revive_left: float = 0.0
## How often it was knocked out in this siege (for tests).
var times_knocked_out: int = 0

var _rules: SiegeRules
var _active: bool = true
var _time: float = 0.0


func setup(who: PlushieDef, at: Vector2, rules: SiegeRules) -> void:
	plushie = who.calmed()
	position = at
	_rules = rules
	name = "Plushie_%s" % who.id
	var half: Vector2 = Vector2.ONE * rules.plushie_footprint
	target = SiegeTarget.new(
		Rect2(at - half, half * 2.0), rules.plushie_health, rules.plushie_touch_rate
	)
	target.pull = rules.plushie_reach
	target.fell.connect(_on_knocked_out)
	target.revived.connect(_on_stood_up)
	var ball: WeaponStats = rules.plushie_ball
	throw = ball.behaviour.new() as Weapon
	throw.mount(ball, 1, ball.at_level(1).reach, WeaponTally.PLUSHIES)
	throw.position = Vector2(0.0, -PlushieLook.top(plushie, rules.plushie_size) * THROW_HEIGHT)
	look = PlushiePicture.new()
	look.setup(plushie, rules.plushie_size, rules.plushie_halo)
	# Behind this node's own drawing, so the dizzy stars show in front of it.
	look.show_behind_parent = true
	add_child(look)
	if who.shape == PlushieDef.Shape.BANANE:
		# Banane helping in the siege while someone else plays him (spec 08 §9): his felt puppet.
		var puppet: BananePuppet = BananePuppet.new()
		puppet.position = -HeroMarker.FEET
		puppet.show_behind_parent = true
		add_child(puppet)
	add_child(throw)


## The Plush Hospital that stands it back up after `seconds` (null = nobody does).
func set_hospital(building: SiegeBuilding, seconds: float) -> void:
	hospital = building
	revive_seconds = seconds


func is_out() -> bool:
	return target.is_fallen()


## True while it throws (standing, and the siege goes on).
func is_throwing() -> bool:
	return throw.process_mode != Node.PROCESS_MODE_DISABLED


## True while a standing Plush Hospital will stand it back up.
func can_revive() -> bool:
	return _active and hospital != null and not hospital.is_fallen() and revive_seconds > 0.0


## The siege is over: no more throwing or standing up.
func stop() -> void:
	_active = false
	throw.process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	if not is_out():
		return
	_time += delta
	queue_redraw()
	if not can_revive():
		return
	revive_left -= delta
	if revive_left <= 0.0:
		target.revive()


func _on_knocked_out() -> void:
	times_knocked_out += 1
	revive_left = revive_seconds
	_time = 0.0
	throw.process_mode = Node.PROCESS_MODE_DISABLED
	look.rotation = deg_to_rad(_rules.plushie_out_tilt)
	look.scale = Vector2(1.0, _rules.plushie_out_squash)
	Sfx.play(_rules.plushie_out_sound)
	queue_redraw()
	knocked_out.emit()


func _on_stood_up() -> void:
	revive_left = 0.0
	if _active:
		throw.process_mode = Node.PROCESS_MODE_INHERIT
	look.rotation = 0.0
	look.scale = Vector2.ONE
	Sfx.play(_rules.plushie_up_sound)
	queue_redraw()
	stood_up.emit()


## Where dizzy star `i` is right now (relative to its feet).
func star_position(i: int) -> Vector2:
	var head: float = PlushieLook.top(plushie, _rules.plushie_size) * _rules.plushie_out_squash
	var turn: float = _time * _rules.dizzy_spin * TAU + TAU * i / maxi(_rules.dizzy_stars, 1)
	var orbit: Vector2 = Vector2(cos(turn) * STAR_ORBIT.x, sin(turn) * STAR_ORBIT.y)
	return Vector2(0.0, -head - STAR_LIFT) + orbit


## Dizzy stars circle its head while it is out (soft yellow with an ink edge).
func _draw() -> void:
	if not is_out():
		return
	var ink: Color = WorldPalette.current().ink
	for i: int in _rules.dizzy_stars:
		var points: PackedVector2Array = _star(star_position(i))
		FeltDraw.fill(self, points, _rules.dizzy_color)
		points.append(points[0])
		draw_polyline(points, ink, STAR_OUTLINE, true)


static func _star(center: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in STAR_POINTS * 2:
		var radius: float = STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * 0.45
		var angle: float = -PI / 2.0 + PI * i / STAR_POINTS
		points.append(center + Vector2.from_angle(angle) * radius)
	return points
