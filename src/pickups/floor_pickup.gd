class_name FloorPickup
extends Node2D
## A single-use toy on the floor (spec 02b §2): it bobs gently on a soft glow until a player
## touches it; then the run triggers it at once for that player.

## `player` touched the pickup (it tells only once).
signal touched(pickup: FloorPickup, player: Player)

## Bobs per second.
const BOB_SPEED: float = 0.9
## How far the toy bobs up and down, in pixels.
const BOB_HEIGHT: float = 3.0
const GLOW_RADIUS: float = 22.0
## The toy floats this high above the floor.
const FLOAT_HEIGHT: float = 10.0
## A double (Double Fun): a second toy peeks out behind the first, and the glow gets an extra
## ring this much bigger.
const TWIN_OFFSET: Vector2 = Vector2(-9.0, -5.0)
const TWIN_SHADE: Color = Color(0.85, 0.85, 0.85)
const DOUBLE_RING: float = 8.0

var kind: FloorPickupDef
var rules: FloorPickupRules
var taken: bool = false
## Double Fun: this one is a double (set before `setup`).
var double: bool = false
var toy: Sprite2D
## The second toy of a double (null otherwise).
var twin: Sprite2D
## 0..1, how bright the glow is right now.
var pulse: float = 0.0

var _time: float = 0.0


func setup(pickup_kind: FloorPickupDef, pickup_rules: FloorPickupRules) -> void:
	kind = pickup_kind
	rules = pickup_rules
	if double:
		twin = FeltAtlas.make_sprite(FloorPickupLook.key(kind.id))
		twin.scale *= FloorPickupLook.DRAW_SCALE
		twin.position = Vector2(0.0, -FLOAT_HEIGHT) + TWIN_OFFSET
		twin.modulate = TWIN_SHADE
		add_child(twin)
	toy = FeltAtlas.make_sprite(FloorPickupLook.key(kind.id))
	toy.scale *= FloorPickupLook.DRAW_SCALE
	toy.position = Vector2(0.0, -FLOAT_HEIGHT)
	add_child(toy)


func _physics_process(delta: float) -> void:
	_time += delta
	pulse = 0.5 + 0.5 * sin(_time * TAU * BOB_SPEED)
	toy.position.y = -FLOAT_HEIGHT - BOB_HEIGHT * pulse
	if twin != null:
		twin.position.y = -FLOAT_HEIGHT + TWIN_OFFSET.y - BOB_HEIGHT * (1.0 - pulse)
	queue_redraw()
	if taken:
		return
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		var reach: float = rules.touch_radius + player.stats.hitbox_radius
		if position.distance_squared_to(player.global_position) <= reach * reach:
			taken = true
			touched.emit(self, player)
			return


## A soft white-gold glow with a thin ring on the floor, a little brighter while the toy is up.
func _draw() -> void:
	var glow: Color = FloorPickupLook.GLOW_COLOR
	for ring: int in 3:
		glow.a = 0.1 + 0.06 * pulse
		draw_circle(Vector2.ZERO, GLOW_RADIUS * (1.0 - ring * 0.25), glow)
	glow.a = 0.45 + 0.25 * pulse
	draw_arc(Vector2.ZERO, GLOW_RADIUS + 2.0 * pulse, 0.0, TAU, 32, glow, 2.0, true)
	if double:
		var outer: float = GLOW_RADIUS + DOUBLE_RING + 2.0 * (1.0 - pulse)
		draw_arc(Vector2.ZERO, outer, 0.0, TAU, 40, glow, 2.0, true)
