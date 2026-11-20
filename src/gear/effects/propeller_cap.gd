class_name PropellerCap
extends Node2D
## Propeller Cap (spec 09 §3, AC-99): the hero's dash goes `amount` farther (per stitch level,
## `GearEffects.dash_distance`), and where it lands a thump hurts every zombie within
## `GearDef.radius` by `GearDef.damage` and nudges them away. The thump is a quick calm ring in
## the cap's colour.

## Push given to zombies the thump hits, in pixels per second.
const PUSH: float = 160.0
const RING_SECONDS: float = 0.3
const RING_WIDTH: float = 3.0
const RING_ALPHA: float = 0.5
const RING_POINTS: int = 32

var player: Player
var piece: GearDef
## Thumps in this run and zombies the last one hit (tests).
var thumps: int = 0
var hit_last: int = 0

var _left: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.PROPELLER_CAP)
	player.dash_landed.connect(_on_dash_landed)
	# Stays where the dash landed, under the zombies.
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS
	visible = false


func _on_dash_landed(at: Vector2) -> void:
	if not player.armed or player.is_dead():
		return
	thumps += 1
	hit_last = 0
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager != null:
		for zombie: Zombie in manager.query_circle(at, piece.radius):
			if zombie.dead:
				continue
			var push: Vector2 = at.direction_to(zombie.position) * PUSH
			manager.damage_from(WeaponTally.PROPELLER_CAP, zombie, piece.damage, push)
			hit_last += 1
	if piece.sound != &"":
		Sfx.play(piece.sound)
	global_position = at
	_left = RING_SECONDS
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	visible = _left > 0.0
	modulate.a = GameSettings.own_effects
	queue_redraw()


func _draw() -> void:
	var share: float = 1.0 - _left / RING_SECONDS
	var color: Color = Color(piece.color, RING_ALPHA * (1.0 - share))
	var radius: float = piece.radius * (0.5 + 0.5 * share)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, RING_POINTS, color, RING_WIDTH, true)
