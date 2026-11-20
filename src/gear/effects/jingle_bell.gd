class_name JingleBell
extends Node2D
## Jingle Bell (spec 09 §3, AC-99): every `amount` kills by the hero's own weapons (per stitch
## level) the bell rings out a shockwave: every zombie within `GearDef.radius` is pushed back and
## takes `GearDef.damage`. The ring is a quick calm circle in the bell's colour, growing out from
## the hero.

## Push given to zombies the shockwave hits, in pixels per second.
const PUSH: float = 320.0
const RING_SECONDS: float = 0.35
const RING_WIDTH: float = 4.0
const RING_ALPHA: float = 0.55
const RING_POINTS: int = 40

var player: Player
var piece: GearDef
## Kills counted toward the next ring.
var kills: int = 0
## Rings in this run and zombies the last one hit (tests).
var rings: int = 0
var hit_last: int = 0

var _manager: EnemyManager
var _left: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.JINGLE_BELL)
	# Grows out from where it rang, under the zombies.
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS
	visible = false


## Kills it takes to ring at the worn stitch level.
func kills_per_ring() -> int:
	return roundi(piece.amount(player.gear.level_of(piece)))


## Rings now (the kill count starts over).
func ring() -> void:
	kills = 0
	rings += 1
	hit_last = 0
	var at: Vector2 = player.global_position
	if _manager != null:
		for zombie: Zombie in _manager.query_circle(at, piece.radius):
			if zombie.dead:
				continue
			var push: Vector2 = at.direction_to(zombie.position) * PUSH
			_manager.damage_from(WeaponTally.JINGLE_BELL, zombie, piece.damage, push)
			hit_last += 1
	if piece.sound != &"":
		Sfx.play(piece.sound)
	global_position = at
	_left = RING_SECONDS
	visible = true


func _physics_process(_delta: float) -> void:
	if _manager == null:
		_manager = get_tree().get_first_node_in_group(EnemyManager.GROUP) as EnemyManager
		if _manager != null:
			_manager.killed_by.connect(_on_killed_by)


func _on_killed_by(weapon: Weapon, _zombie: Zombie) -> void:
	if weapon.player != player or not player.armed or player.is_dead():
		return
	kills += 1
	if kills >= kills_per_ring():
		ring()


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
	var radius: float = piece.radius * (0.3 + 0.7 * share)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, RING_POINTS, color, RING_WIDTH, true)
