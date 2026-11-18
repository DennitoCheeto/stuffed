class_name ChillyHug
extends Node2D
## Pip's passive (spec 08 §3, AC-88): zombies close to her move slower (bosses less), for as
## long as they stay close. A soft frost ring on the floor shows the reach. Only in a run or a
## siege (an armed hero); numbers in the hero's .tres (HeroStats "Chilly Hug").

## Each touch keeps a zombie slowed this long, so it wears off just after it leaves the ring.
const LINGER_SECONDS: float = 0.2
const RING_POINTS: int = 48
const RING_WIDTH: float = 3.0
## How much the ring breathes (share of its radius).
const BREATHE: float = 0.04

var player: Player
## How many zombies were slowed in the last physics frame (tests).
var chilled: int = 0

var _time: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	# On the floor, under zombies and the hero (WorldLayers), like the hero ring.
	z_as_relative = false
	z_index = WorldLayers.FLOOR_MARKS


func _physics_process(delta: float) -> void:
	_time += delta
	chilled = 0
	visible = player.armed and not player.is_dead()
	if not visible:
		return
	queue_redraw()
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager == null:
		return
	var stats: HeroStats = player.stats
	for zombie: Zombie in manager.query_circle(player.global_position, stats.chilly_radius):
		if zombie.dead:
			continue
		var amount: float = stats.chilly_boss_slow if zombie.is_boss() else stats.chilly_slow
		zombie.slow(amount, LINGER_SECONDS)
		chilled += 1


## The ring's radius right now (it breathes a little).
func ring_radius() -> float:
	var breath: float = sin(_time * TAU * player.stats.chilly_ring_pulse)
	return player.stats.chilly_radius * (1.0 + BREATHE * breath)


func _draw() -> void:
	var color: Color = player.stats.chilly_ring_color
	var radius: float = ring_radius()
	var ring: PackedVector2Array = []
	for i: int in RING_POINTS + 1:
		var turn: float = TAU * i / RING_POINTS
		ring.append(Vector2(cos(turn), sin(turn)) * radius)
	FeltDraw.fill(self, ring.slice(0, RING_POINTS), Color(color, color.a * 0.35))
	draw_polyline(ring, color, RING_WIDTH, true)
