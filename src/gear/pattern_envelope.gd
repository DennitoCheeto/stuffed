class_name PatternEnvelope
extends Node2D
## A paper sewing-pattern envelope on the Bedroom floor (spec 09 §4): dropped where a boss fell
## the first time or by an elite (Raincoat). It bobs and glows softly; the first hero who
## touches it finds the pattern, then it is gone. An edge arrow points to it (PickupArrows).

## `player` touched the envelope (it tells only once).
signal touched(envelope: PatternEnvelope, player: Player)

## A soft mint glow (the player's side, never a danger colour).
const GLOW_COLOR: Color = Color("#9fe3c8")
const PAPER_COLOR: Color = Color("#f6edd6")
const FLAP_COLOR: Color = Color("#e6d8b6")
const INK_COLOR: Color = Color("#1d3a52")
## The dashed cutting line of the pattern printed on the paper.
const PATTERN_COLOR: Color = Color("#6f9fc4")
const HALF_SIZE: Vector2 = Vector2(17.0, 12.0)
const GLOW_RADIUS: float = 30.0
const PULSE_SPEED: float = 1.1
const BOB_PIXELS: float = 3.0

## The piece whose pattern is inside.
var piece: GearDef
var touch_radius: float = 26.0
var taken: bool = false
## 0..1, how bright the glow is right now.
var pulse: float = 0.0

var _time: float = 0.0


func setup(gear: GearDef, reach: float) -> void:
	piece = gear
	touch_radius = reach


func _physics_process(delta: float) -> void:
	_time += delta
	pulse = 0.5 + 0.5 * sin(_time * TAU * PULSE_SPEED)
	queue_redraw()
	if taken:
		return
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		var reach: float = touch_radius + player.stats.hitbox_radius
		if global_position.distance_squared_to(player.global_position) <= reach * reach:
			taken = true
			touched.emit(self, player)
			queue_free()
			return


## Glow rings, then the envelope: paper, flap, a dashed pattern line and an ink outline.
func _draw() -> void:
	var glow: Color = GLOW_COLOR
	for ring: int in 3:
		glow.a = 0.12 + 0.08 * pulse
		draw_circle(Vector2.ZERO, GLOW_RADIUS * (1.0 - ring * 0.25), glow)
	var lift: Vector2 = Vector2(0.0, -BOB_PIXELS * pulse - 6.0)
	var h: Vector2 = HALF_SIZE
	var body: PackedVector2Array = [
		lift + Vector2(-h.x, -h.y),
		lift + Vector2(h.x, -h.y),
		lift + Vector2(h.x, h.y),
		lift + Vector2(-h.x, h.y),
	]
	draw_colored_polygon(body, PAPER_COLOR)
	var flap: PackedVector2Array = [
		lift + Vector2(-h.x, -h.y), lift + Vector2(h.x, -h.y), lift + Vector2(0.0, h.y * 0.25)
	]
	draw_colored_polygon(flap, FLAP_COLOR)
	draw_dashed_line(
		lift + Vector2(-h.x * 0.6, h.y * 0.6), lift + Vector2(h.x * 0.6, h.y * 0.6), PATTERN_COLOR,
		2.0, 4.0
	)
	body.append(body[0])
	draw_polyline(body, INK_COLOR, 2.5, true)
	draw_polyline(flap, INK_COLOR, 2.0, true)
