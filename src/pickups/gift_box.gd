class_name GiftBox
extends Node2D
## A gift box on the floor (dropped by elites; later the mini-boss and boss). It glows softly and
## bobs until a player touches it; then it opens for that player (spec 02 §6, §15).

## `player` touched the box (it tells only once).
signal touched(box: GiftBox, player: Player)

## Glow pulses per second.
const PULSE_SPEED: float = 1.2
const GLOW_RADIUS: float = 30.0
const GLOW_CENTER: Vector2 = Vector2(0.0, -6.0)

var rules: GiftBoxRules
var opened: bool = false
var box: Sprite2D
var lid: Sprite2D
## 0..1, how bright the glow is right now.
var pulse: float = 0.0

var _time: float = 0.0


func setup(gift_rules: GiftBoxRules) -> void:
	rules = gift_rules
	box = _sprite(GiftBoxLook.BOX, Vector2(0.0, 8.0))
	lid = _sprite(GiftBoxLook.LID, Vector2(0.0, -18.0))


func _physics_process(delta: float) -> void:
	_time += delta
	pulse = 0.5 + 0.5 * sin(_time * TAU * PULSE_SPEED)
	lid.position.y = -18.0 - 2.0 * pulse
	queue_redraw()
	if opened:
		return
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		var reach: float = rules.touch_radius + player.stats.hitbox_radius
		if position.distance_squared_to(player.global_position) <= reach * reach:
			opened = true
			touched.emit(self, player)
			return


## A soft warm glow under the box: a few see-through circles, brighter towards the middle.
func _draw() -> void:
	var glow: Color = GiftBoxLook.GLOW_COLOR
	for ring: int in 4:
		var share: float = 1.0 - ring * 0.22
		glow.a = 0.12 + 0.08 * pulse
		draw_circle(GLOW_CENTER, GLOW_RADIUS * share * (0.95 + 0.1 * pulse), glow)


func _sprite(key: StringName, at: Vector2) -> Sprite2D:
	var sprite: Sprite2D = FeltAtlas.make_sprite(key)
	sprite.position = at
	sprite.scale *= GiftBoxLook.DRAW_SCALE
	add_child(sprite)
	return sprite
