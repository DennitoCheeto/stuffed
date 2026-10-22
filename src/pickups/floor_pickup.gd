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

var kind: FloorPickupDef
var rules: FloorPickupRules
var taken: bool = false
var toy: Sprite2D
## 0..1, how bright the glow is right now.
var pulse: float = 0.0

var _time: float = 0.0


func setup(pickup_kind: FloorPickupDef, pickup_rules: FloorPickupRules) -> void:
	kind = pickup_kind
	rules = pickup_rules
	toy = FeltAtlas.make_sprite(FloorPickupLook.key(kind.id))
	toy.scale *= FloorPickupLook.DRAW_SCALE
	toy.position = Vector2(0.0, -FLOAT_HEIGHT)
	add_child(toy)


func _physics_process(delta: float) -> void:
	_time += delta
	pulse = 0.5 + 0.5 * sin(_time * TAU * BOB_SPEED)
	toy.position.y = -FLOAT_HEIGHT - BOB_HEIGHT * pulse
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
