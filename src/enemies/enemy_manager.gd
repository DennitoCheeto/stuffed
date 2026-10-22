class_name EnemyManager
extends Node
## Owns all zombies of a run and moves them together each physics frame: walk towards the
## nearest player, push each other apart a little (a crowd, not a blob), hurt players they touch.
## Ranged zombies (spitters) keep their distance instead and spit after a visible wind-up;
## bloaters burst into a hurting cloud when killed.
## Weapons ask it for zombies near a point and deal damage through it.
## Zombies live under the `actors` node, which sits at the world origin.

signal zombie_killed(zombie: Zombie)
## A zombie took damage (damage numbers, hit sound).
signal zombie_hit(zombie: Zombie, amount: float)
## A ranged zombie starts puffing up (a shot is coming).
signal zombie_winding_up(zombie: Zombie)
## A ranged zombie spat `balls` stuffing balls.
signal zombie_spat(zombie: Zombie, balls: int)
## A killed zombie burst into a cloud that hurts players (the bloater).
signal zombie_burst(zombie: Zombie, cloud: EnemyCloud)
## A boss shows the telegraph of `pattern` (e.g. &"charge", &"stomp"): it attacks soon.
signal boss_telegraphed(boss: Zombie, pattern: StringName)
## A boss's `pattern` happens now (the charge starts, the stomp fires).
signal boss_attacked(boss: Zombie, pattern: StringName)
## A boss got angry (the Sock Puppet King at half health).
signal boss_angry(boss: Zombie)
## A boss landed from a lunge.
signal boss_landed(boss: Zombie)
## A freeze is about to end: the ice cracks (sound).
signal ice_cracking
## A freeze ended: everything moves again.
signal thawed

## Weapons find the manager through this group.
const GROUP: StringName = &"enemy_manager"
const GRID_CELL: float = 48.0
## How strongly overlapping zombies push each other apart (0..1 per frame).
const SEPARATION: float = 0.5
## At most this many death bursts at once; more kills just pop without flying pieces.
const MAX_BURSTS: int = 60

var actors: Node2D
var effects: Node2D
## Where ranged zombies put their stuffing balls.
var projectiles: ProjectileManager
## Furniture: zombies walk around it (bosses too, unless they are in the air).
var obstacles: Obstacles = Obstacles.new()
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
## Snow Globe: seconds the horde stays frozen (0 = not frozen), see `freeze`.
var freeze_left: float = 0.0
## While frozen, bosses move at this share of their speed.
var freeze_boss_speed: float = 0.5
## The ice cracks this many seconds before the freeze ends.
var freeze_crack_seconds: float = 1.0

## The crack of the current freeze was announced.
var _cracked: bool = false
var _grid: SpatialGrid = SpatialGrid.new(GRID_CELL)
## Only for looks (shamble phase, burst directions), so it doesn't change the seeded run.
var _cosmetic_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(GROUP)


func setup(
	actors_node: Node2D,
	effects_node: Node2D,
	area: Rect2,
	max_count: int,
	furniture: Obstacles = null
) -> void:
	actors = actors_node
	effects = effects_node
	play_rect = area
	max_alive = max_count
	if furniture != null:
		obstacles = furniture


func alive_count() -> int:
	return zombies.size()


## Adds a zombie at `at` (an elite with `elite`). Returns null when the maximum number of zombies
## is already alive.
func spawn(stats: EnemyStats, at: Vector2, elite: EliteRules = null) -> Zombie:
	if zombies.size() >= max_alive:
		return null
	return _add(stats, at, elite, null)


## Adds the boss `boss` at `at` (always, even when the maximum number of zombies is alive).
func spawn_boss(boss: BossDef, at: Vector2) -> Zombie:
	return _add(boss.enemy, at, null, boss)


## Living bosses (mini-boss and boss).
func bosses() -> Array[Zombie]:
	var result: Array[Zombie] = []
	for zombie: Zombie in zombies:
		if zombie.is_boss():
			result.append(zombie)
	return result


func _add(stats: EnemyStats, at: Vector2, elite: EliteRules, boss: BossDef) -> Zombie:
	var zombie: Zombie = Zombie.new()
	zombie.position = at
	zombie.setup(stats, health_scale, damage_scale, _cosmetic_rng.randf(), elite, boss)
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
		_burst_into_cloud(zombie)
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
	var frozen: bool = is_frozen()
	var shake: float = thaw_shake()
	for zombie: Zombie in zombies:
		if calm:
			zombie.heading = Vector2.ZERO
			zombie.windup_left = -1.0
			if zombie.brain != null:
				zombie.brain.calm_down()
			zombie.tick(delta)
		elif frozen and not zombie.is_boss():
			_hold_frozen(zombie, shake)
			zombie.tick(delta)
		else:
			zombie.frozen = false
			# A Snow Globe only slows bosses: their whole turn runs at a share of the speed.
			var turn: float = delta * freeze_boss_speed if frozen else delta
			_take_turn(zombie, players, turn)
			zombie.tick(turn)
	_count_down_freeze(delta)


## A zombie's normal turn: walk (or the boss's pattern), touch players, attack.
func _take_turn(zombie: Zombie, players: Array[Player], delta: float) -> void:
	var target: Player = _nearest_player(zombie.position, players)
	if zombie.brain != null:
		_move_boss(zombie, target, delta)
	else:
		_move(zombie, target, delta)
	if zombie.brain == null or not zombie.brain.is_airborne():
		_touch_players(zombie, players)
	if zombie.attack != null:
		_attack(zombie, target, delta)


## Freezes the horde for `seconds` (Snow Globe, spec 02b §3): zombies can't move, attack or hurt
## by touch, but still take damage. Bosses aren't frozen, they move at `boss_speed` (0.5 = half).
## In the last `crack_seconds` the ice cracks and they shake.
func freeze(seconds: float, boss_speed: float, crack_seconds: float) -> void:
	freeze_left = maxf(freeze_left, seconds)
	freeze_boss_speed = boss_speed
	freeze_crack_seconds = crack_seconds
	_cracked = false


func is_frozen() -> bool:
	return freeze_left > 0.0


## 0 while the ice holds, rising to 1 in the last seconds of a freeze (the ice cracks).
func thaw_shake() -> float:
	if not is_frozen() or freeze_left > freeze_crack_seconds:
		return 0.0
	return clampf(1.0 - freeze_left / maxf(freeze_crack_seconds, 0.001), 0.0, 1.0)


## A frozen zombie stands still in its pose: no walking, no push, no wind-up, no touch damage.
func _hold_frozen(zombie: Zombie, shake: float) -> void:
	zombie.frozen = true
	zombie.thaw_shake = shake
	zombie.heading = Vector2.ZERO
	zombie.knockback = Vector2.ZERO
	zombie.windup_left = -1.0


func _count_down_freeze(delta: float) -> void:
	if not is_frozen():
		return
	freeze_left = maxf(freeze_left - delta, 0.0)
	if not _cracked and freeze_left <= freeze_crack_seconds:
		_cracked = true
		ice_cracking.emit()
	if freeze_left <= 0.0:
		for zombie: Zombie in zombies:
			zombie.frozen = false
		thawed.emit()


func _alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			result.append(player)
	return result


func _move(zombie: Zombie, target: Player, delta: float) -> void:
	var walk: Vector2 = _around_furniture(zombie, _walk(zombie, target))
	zombie.heading = walk.normalized()
	var step: Vector2 = (walk + zombie.knockback) * delta + _separation(zombie)
	_place(zombie, zombie.position + step)


## A boss goes where its brain says. The crowd doesn't push it: it pushes the crowd.
func _move_boss(zombie: Zombie, target: Player, delta: float) -> void:
	var walk: Vector2 = zombie.brain.step(zombie, target, self, delta)
	if zombie.brain.is_airborne():
		zombie.heading = walk.normalized()
		var inside: Rect2 = play_rect.grow(-zombie.radius())
		var flight: Vector2 = zombie.position + (walk + zombie.knockback) * delta
		zombie.position = flight.clamp(inside.position, inside.end)
		return
	walk = _around_furniture(zombie, walk)
	zombie.heading = walk.normalized()
	_place(zombie, zombie.position + (walk + zombie.knockback) * delta)


## `walk` turned along the side of furniture in the way (zombies slide around it).
func _around_furniture(zombie: Zombie, walk: Vector2) -> Vector2:
	if obstacles.is_empty():
		return walk
	var steered: Array = obstacles.steer(zombie.position, zombie.radius(), walk, zombie.detour)
	zombie.detour = steered[1]
	return steered[0]


## Moves a zombie to `point`, but never into furniture or out of the arena.
func _place(zombie: Zombie, point: Vector2) -> void:
	var edge: float = zombie.radius()
	var inside: Rect2 = play_rect.grow(-edge)
	zombie.position = obstacles.push_out(point, edge).clamp(inside.position, inside.end)


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
			player.take_hit(zombie.contact_damage, zombie.display_name)


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


## Where a zombie wants to go: straight at its target, or (ranged zombies) to a spot at their
## keep distance. A ranged zombie stands still while it winds up.
func _walk(zombie: Zombie, target: Player) -> Vector2:
	if target == null or zombie.stun_left > 0.0:
		return Vector2.ZERO
	var toward: Vector2 = zombie.position.direction_to(target.global_position)
	toward *= zombie.current_speed()
	var attack: SpitAttack = zombie.attack
	if attack == null:
		return toward
	if zombie.is_winding_up():
		return Vector2.ZERO
	var distance: float = zombie.position.distance_to(target.global_position)
	if distance > attack.keep_distance + attack.distance_band:
		return toward
	if distance < attack.keep_distance - attack.distance_band:
		return -toward
	return Vector2.ZERO


## A ranged zombie's turn: count down, wind up when a player is in range, spit when the wind-up
## is over. Being stunned cancels the wind-up.
func _attack(zombie: Zombie, target: Player, delta: float) -> void:
	var attack: SpitAttack = zombie.attack
	zombie.attack_cooldown -= delta
	if zombie.is_stunned():
		zombie.windup_left = -1.0
		return
	if zombie.is_winding_up():
		zombie.windup_left -= delta
		if zombie.windup_left <= 0.0:
			zombie.windup_left = -1.0
			if target != null:
				_spit(zombie, target, attack)
		return
	if zombie.attack_cooldown > 0.0 or target == null or projectiles == null:
		return
	var reach: float = attack.fire_range
	if zombie.position.distance_squared_to(target.global_position) > reach * reach:
		return
	zombie.windup_left = attack.windup_seconds
	zombie_winding_up.emit(zombie)


## The next volley of its pattern (one ball or a fan), aimed at where the target is now.
func _spit(zombie: Zombie, target: Player, attack: SpitAttack) -> void:
	var balls: int = attack.balls_in_volley(zombie.volleys)
	zombie.volleys += 1
	zombie.attack_cooldown = attack.cooldown_seconds
	var aim: Vector2 = zombie.position.direction_to(target.global_position)
	fire_volley(zombie, aim, attack, balls, zombie.spit_damage)
	zombie_spat.emit(zombie, balls)


## Hurts every living player within `radius` of `center` (a boss landing). Dashing players
## get away.
func hurt_players_near(center: Vector2, radius: float, damage: float, source: String) -> void:
	for player: Player in _alive_players():
		var reach: float = radius + player.stats.hitbox_radius
		if player.is_dashing():
			continue
		if player.global_position.distance_squared_to(center) <= reach * reach:
			player.take_hit(damage, source)


## Fires `balls` stuffing balls of `attack` from the edge of `zombie`'s body, fanned around
## `aim`, each hurting `damage`.
func fire_volley(
	zombie: Zombie, aim: Vector2, attack: SpitAttack, balls: int, damage: float
) -> void:
	if projectiles == null:
		return
	for direction: Vector2 in attack.directions(aim, balls):
		var ball: EnemyBullet = projectiles.spawn(EnemyBullet) as EnemyBullet
		ball.launch(
			zombie.position + direction * zombie.radius(),
			direction * attack.bullet_speed,
			damage,
			attack.bullet_radius,
			attack.bullet_lifetime,
			zombie.display_name
		)


## A killed bloater leaves its stuffing cloud where it died (not while calm: nothing hurts then).
func _burst_into_cloud(zombie: Zombie) -> void:
	var cloud_stats: DeathCloud = zombie.stats.death_cloud
	if cloud_stats == null or projectiles == null or calm:
		return
	var cloud: EnemyCloud = projectiles.spawn(EnemyCloud) as EnemyCloud
	var damage_amount: float = cloud_stats.damage * damage_scale
	var source: String = zombie.display_name
	cloud.launch(zombie.position, cloud_stats.radius, cloud_stats.duration, damage_amount, source)
	zombie_burst.emit(zombie, cloud)
