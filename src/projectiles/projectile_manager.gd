class_name ProjectileManager
extends Node2D
## Owns every shot of a run, the players' and the enemies'. Moves them all in one physics loop
## and keeps finished shots hidden for reuse instead of freeing them, so a screen full of
## projectiles stays cheap (spec 02 §14). Enemy bullets sit on their own layer above everything
## else in the world: danger always reads first (vision §6.1).

## Weapons and enemies find the manager through this group.
const GROUP: StringName = &"projectiles"
## Draw order of the enemy-bullet layer (zombies, players, shots and bursts are below it).
const HOSTILE_Z: int = 50

## Shots in flight.
var active: Array[Projectile] = []
## Shot nodes ever made (the pool keeps this small).
var created: int = 0
var enemies: EnemyManager
## Enemy bullets that hit furniture are gone (the players' shots fly over it).
var obstacles: Obstacles = Obstacles.new()
## Shots that leave this area are gone (the arena floor).
var play_rect: Rect2 = Rect2()
## Living players this frame (enemy bullets look for them here).
var targets: Array[Player] = []

var _pool: Dictionary[GDScript, Array] = {}
var _friendly: Node2D
var _hostile: Node2D


func _ready() -> void:
	add_to_group(GROUP)
	_friendly = Node2D.new()
	_friendly.name = "Friendly"
	add_child(_friendly)
	_hostile = Node2D.new()
	_hostile.name = "Hostile"
	_hostile.z_index = HOSTILE_Z
	add_child(_hostile)


func setup(enemy_manager: EnemyManager, area: Rect2, furniture: Obstacles = null) -> void:
	enemies = enemy_manager
	play_rect = area
	if furniture != null:
		obstacles = furniture


## A fresh shot of `kind` (a Projectile script), from the pool if one is free. Launch it next.
func spawn(kind: GDScript) -> Projectile:
	var shot: Projectile
	var free_shots: Array = _pool.get(kind, [])
	if free_shots.is_empty():
		shot = kind.new() as Projectile
		shot.manager = self
		created += 1
		(_hostile if shot.is_hostile() else _friendly).add_child(shot)
	else:
		shot = free_shots.pop_back()
	shot.reset()
	shot.visible = true
	active.append(shot)
	return shot


## Shots in flight that `weapon` fired.
func fired_by(weapon: Weapon) -> Array[Projectile]:
	var result: Array[Projectile] = []
	for shot: Projectile in active:
		if shot.weapon == weapon:
			result.append(shot)
	return result


func hostile_count() -> int:
	var count: int = 0
	for shot: Projectile in active:
		if shot.is_hostile():
			count += 1
	return count


## Removes every enemy bullet at once (e.g. when the goal is reached).
func clear_hostile() -> void:
	for i: int in range(active.size() - 1, -1, -1):
		if active[i].is_hostile():
			_release_at(i)


func _physics_process(delta: float) -> void:
	targets.clear()
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			targets.append(player)
	var i: int = 0
	# Shots launched during this loop (e.g. a split) are appended and move this frame too.
	while i < active.size():
		var shot: Projectile = active[i]
		var owner_gone: bool = not shot.is_hostile() and not is_instance_valid(shot.weapon)
		if not owner_gone and shot.advance(delta):
			i += 1
		else:
			_release_at(i)


## Back to the pool: hidden, and swapped out of the active list (order doesn't matter).
func _release_at(index: int) -> void:
	var shot: Projectile = active[index]
	active[index] = active[active.size() - 1]
	active.pop_back()
	shot.visible = false
	shot.weapon = null
	var kind: GDScript = shot.get_script()
	if not _pool.has(kind):
		_pool[kind] = []
	_pool[kind].append(shot)
