class_name EnemyManager
extends Node
## Owns all zombies of a run and moves them together each physics frame: walk towards the
## nearest player, push each other apart a little (a crowd, not a blob), hurt players they touch.
## Weapons ask it for zombies near a point and deal damage through it.
## Zombies live under the `actors` node, which sits at the world origin.

signal zombie_killed(zombie: Zombie)
## A zombie took damage (damage numbers, hit sound).
signal zombie_hit(zombie: Zombie, amount: float)

## Weapons find the manager through this group.
const GROUP: StringName = &"enemy_manager"
const GRID_CELL: float = 48.0
## How strongly overlapping zombies push each other apart (0..1 per frame).
const SEPARATION: float = 0.5
## At most this many death bursts at once; more kills just pop without flying pieces.
const MAX_BURSTS: int = 60

var actors: Node2D
var effects: Node2D
## Zombies never leave this area (the arena floor).
var play_rect: Rect2 = Rect2()
var max_alive: int = 500
## Endless mode makes zombies tougher by raising these.
var health_scale: float = 1.0
var damage_scale: float = 1.0
var kills: int = 0
var zombies: Array[Zombie] = []
## While calm (goal reached), zombies stand still and can't hurt anyone.
var calm: bool = false

var _grid: SpatialGrid = SpatialGrid.new(GRID_CELL)
## Only for looks (shamble phase, burst directions), so it doesn't change the seeded run.
var _cosmetic_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(GROUP)


func setup(actors_node: Node2D, effects_node: Node2D, area: Rect2, max_count: int) -> void:
	actors = actors_node
	effects = effects_node
	play_rect = area
	max_alive = max_count


func alive_count() -> int:
	return zombies.size()


## Adds a zombie at `at`. Returns null when the maximum number of zombies is already alive.
func spawn(stats: EnemyStats, at: Vector2) -> Zombie:
	if zombies.size() >= max_alive:
		return null
	var zombie: Zombie = Zombie.new()
	zombie.position = at
	zombie.setup(stats, health_scale, damage_scale, _cosmetic_rng.randf())
	actors.add_child(zombie)
	zombies.append(zombie)
	_grid.insert(zombie, at)
	return zombie


## Hurts a zombie and pushes it. Returns true if it died.
func damage(zombie: Zombie, amount: float, push: Vector2 = Vector2.ZERO) -> bool:
	if not is_instance_valid(zombie) or zombie.dead:
		return false
	zombie_hit.emit(zombie, amount)
	if zombie.take_damage(amount, push):
		_remove(zombie, true)
		return true
	return false


## Pops every zombie at once (developer menu).
func kill_all() -> void:
	for zombie: Zombie in zombies.duplicate():
		zombie.dead = true
		_remove(zombie, true)


## Pops every zombie, nearest to `center` first, spread over `duration` seconds: a satisfying
## chain of pops (goal reached). Awaitable.
func pop_all_in_chain(center: Vector2, duration: float) -> void:
	var queue: Array[Zombie] = zombies.duplicate()
	queue.sort_custom(
		func(a: Zombie, b: Zombie) -> bool:
			return a.position.distance_squared_to(center) < b.position.distance_squared_to(center)
	)
	var frames: int = maxi(roundi(duration * Engine.physics_ticks_per_second), 1)
	var per_frame: int = ceili(float(queue.size()) / frames)
	while not queue.is_empty():
		for i: int in mini(per_frame, queue.size()):
			var zombie: Zombie = queue.pop_front()
			if is_instance_valid(zombie) and not zombie.dead:
				zombie.dead = true
				_remove(zombie, true)
		await get_tree().physics_frame


## Living zombies whose body touches the circle.
func query_circle(center: Vector2, radius: float) -> Array[Zombie]:
	var result: Array[Zombie] = []
	for item: Object in _grid.candidates(center, radius + GRID_CELL):
		var zombie: Zombie = item as Zombie
		if not is_instance_valid(zombie) or zombie.dead:
			continue
		var reach: float = radius + zombie.radius()
		if zombie.position.distance_squared_to(center) <= reach * reach:
			result.append(zombie)
	return result


## The living zombie closest to `point` within `max_distance`, or null.
func nearest(point: Vector2, max_distance: float = INF) -> Zombie:
	var best: Zombie = null
	var best_distance: float = max_distance * max_distance
	for zombie: Zombie in zombies:
		var distance: float = zombie.position.distance_squared_to(point)
		if distance < best_distance:
			best = zombie
			best_distance = distance
	return best


func _physics_process(delta: float) -> void:
	var players: Array[Player] = _alive_players()
	_grid.clear()
	for zombie: Zombie in zombies:
		_grid.insert(zombie, zombie.position)
	for zombie: Zombie in zombies:
		if calm:
			zombie.heading = Vector2.ZERO
		else:
			_move(zombie, players, delta)
			_touch_players(zombie, players)
		zombie.tick(delta)


func _alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			result.append(player)
	return result


func _move(zombie: Zombie, players: Array[Player], delta: float) -> void:
	var walk: Vector2 = Vector2.ZERO
	var target: Player = _nearest_player(zombie.position, players)
	if target != null and zombie.stun_left <= 0.0:
		walk = zombie.position.direction_to(target.global_position) * zombie.move_speed
	zombie.heading = walk.normalized()
	var step: Vector2 = (walk + zombie.knockback) * delta + _separation(zombie)
	var edge: float = zombie.radius()
	var inside: Rect2 = play_rect.grow(-edge)
	zombie.position = (zombie.position + step).clamp(inside.position, inside.end)


func _nearest_player(point: Vector2, players: Array[Player]) -> Player:
	var best: Player = null
	var best_distance: float = INF
	for player: Player in players:
		var distance: float = player.global_position.distance_squared_to(point)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


## How far overlapping neighbours push this zombie this frame.
func _separation(zombie: Zombie) -> Vector2:
	var push: Vector2 = Vector2.ZERO
	var own_radius: float = zombie.radius()
	for item: Object in _grid.candidates(zombie.position, own_radius * 2.0):
		var other: Zombie = item as Zombie
		if other == zombie or not is_instance_valid(other) or other.dead:
			continue
		var offset: Vector2 = zombie.position - other.position
		var min_distance: float = own_radius + other.radius()
		var distance_squared: float = offset.length_squared()
		if distance_squared >= min_distance * min_distance:
			continue
		if distance_squared < 0.0001:
			offset = Vector2.RIGHT.rotated(zombie.get_instance_id() % 360)
			distance_squared = 1.0
		var distance: float = sqrt(distance_squared)
		push += offset / distance * (min_distance - distance)
	return (push * SEPARATION * 0.5).limit_length(own_radius * 0.5)


func _touch_players(zombie: Zombie, players: Array[Player]) -> void:
	for player: Player in players:
		var reach: float = zombie.radius() + player.stats.hitbox_radius
		if zombie.position.distance_squared_to(player.global_position) <= reach * reach:
			player.take_hit(zombie.contact_damage, zombie.stats.display_name)


func _remove(zombie: Zombie, with_burst: bool) -> void:
	var index: int = zombies.find(zombie)
	if index == -1:
		return
	zombies[index] = zombies[zombies.size() - 1]
	zombies.pop_back()
	kills += 1
	zombie_killed.emit(zombie)
	if with_burst and effects != null and effects.get_child_count() < MAX_BURSTS:
		var burst: ZombieBurst = ZombieBurst.new()
		effects.add_child(burst)
		burst.global_position = zombie.global_position
		burst.launch(zombie.puppet, _cosmetic_rng)
	zombie.queue_free()
