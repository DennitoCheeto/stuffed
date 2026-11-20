class_name ApronSnack
extends Node2D
## A Picnic Apron snack on the floor (spec 09 §3): a little cookie on a napkin in the apron's
## colour, bobbing gently. The first living hero who touches it while hurt eats it and heals
## `GearDef.factor` of their max health; heroes at full health walk over it.

signal eaten(by: Player)

## A hero this close eats it (pixels).
const TOUCH_RADIUS: float = 26.0
const NAPKIN_RADIUS: float = 11.0
const COOKIE_RADIUS: float = 7.0
## A calm biscuit tan (low saturation: never a danger colour) and its crumbs.
const COOKIE: Color = Color(0.89, 0.8, 0.64)
const CRUMBS: Color = Color(0.62, 0.55, 0.47)
const BOB_PIXELS: float = 2.0
const BOB_SPEED: float = 3.0

var heal_share: float = 0.15
var napkin: Color = Color.WHITE

var _age: float = 0.0


func setup(at: Vector2, piece: GearDef) -> void:
	heal_share = piece.factor
	napkin = piece.effect_color
	# Lies on the floor where it fell, with the XP buttons.
	top_level = true
	global_position = at
	z_as_relative = false
	z_index = WorldLayers.PICKUPS


func _physics_process(delta: float) -> void:
	_age += delta
	for hero: Player in Players.all(get_tree()):
		if hero.is_dead() or hero.health >= hero.max_health:
			continue
		if hero.global_position.distance_to(global_position) <= TOUCH_RADIUS:
			hero.heal(hero.max_health * heal_share)
			eaten.emit(hero)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var lift: Vector2 = Vector2(0.0, -BOB_PIXELS * (0.5 + 0.5 * sin(_age * BOB_SPEED)))
	FeltDraw.fill(self, FeltDraw.circle(Vector2.ZERO, NAPKIN_RADIUS, 16), napkin)
	FeltDraw.fill(self, FeltDraw.circle(lift, COOKIE_RADIUS, 16), COOKIE)
	for crumb: Vector2 in [Vector2(-2.5, -2.0), Vector2(2.0, -0.5), Vector2(-0.5, 2.5)]:
		draw_circle(lift + crumb, 1.1, CRUMBS)
