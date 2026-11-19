class_name BigHeart
extends Node2D
## BamBam's passive (spec 08 §3, AC-88): every level-up heals him and every hero nearby by a share
## of their max health, and a heart pulse pushes zombies close by back (no damage). The pulse is a
## soft pink ring of little hearts growing out from him. Numbers in the hero's .tres ("Big Heart").

const HEARTS: int = 10
const HEART_SIZE: float = 7.0

var player: Player
## How many pulses fired in this run, and how many zombies the last one pushed (tests).
var pulses: int = 0
var pushed: int = 0

var _left: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	player.progress.leveled_up.connect(_on_leveled_up)
	# An own effect: under the zombies (WorldLayers), but over the floor.
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS
	visible = false


func _on_leveled_up(_new_level: int) -> void:
	if not player.armed or player.is_dead():
		return
	pulses += 1
	var stats: HeroStats = player.stats
	for hero: Player in Players.all(get_tree()):
		if hero.is_dead():
			continue
		if hero.global_position.distance_to(player.global_position) <= stats.big_heart_heal_reach:
			hero.heal(hero.max_health * stats.big_heart_heal)
	pushed = 0
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager != null:
		var at: Vector2 = player.global_position
		for zombie: Zombie in manager.query_circle(at, stats.big_heart_push_reach):
			if zombie.dead:
				continue
			var away: Vector2 = at.direction_to(zombie.position)
			zombie.knockback += away * stats.big_heart_push * zombie.knockback_taken()
			pushed += 1
	_left = stats.big_heart_seconds
	visible = true
	queue_redraw()


## How far the pulse has grown (0 = just fired, 1 = done).
func pulse_share() -> float:
	return 1.0 - _left / maxf(player.stats.big_heart_seconds, 0.001)


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	visible = _left > 0.0
	modulate.a = GameSettings.own_effects
	queue_redraw()


func _draw() -> void:
	var share: float = pulse_share()
	var radius: float = player.stats.big_heart_push_reach * share
	var color: Color = player.stats.big_heart_color
	color.a *= 1.0 - share
	for i: int in HEARTS:
		var at: Vector2 = Vector2.from_angle(TAU * i / HEARTS) * radius
		draw_colored_polygon(_heart(at, HEART_SIZE * (1.0 + share)), color)


static func _heart(center: Vector2, size: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in 16:
		var t: float = TAU * i / 16.0
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(center + Vector2(x, -y) * size / 16.0)
	return points
