class_name Spawner
extends Node
## Brings new zombies into the run following the spawn schedule, always just outside the
## visible screen.

## An elite appeared (sound, tests).
signal elite_spawned(elite: Zombie)
## A mini-boss or boss arrived (banner, health bar, sound).
signal boss_spawned(boss: Zombie)

## An elite or mini-boss more than this many seconds overdue (after a time jump) is skipped.
const MISSED_ELITE_SECONDS: float = 5.0

@export var schedule: SpawnSchedule

## The run goal (for the final surge); 0 = none.
var goal_seconds: float = 0.0
## Endless mode spawns more (1 = normal).
var rate_scale: float = 1.0
## Turned off when the goal is reached.
var active: bool = true
var enemies: EnemyManager
var camera: Camera2D
var rng: RandomNumberGenerator

## Fractional zombies owed (rate × time), so low rates still spawn evenly.
var _owed: float = 0.0
## The next elite of the schedule (its index).
var _next_elite: int = 0
## The mini-boss has come (or was skipped by a time jump).
var _mini_boss_done: bool = false


func setup(manager: EnemyManager, view_camera: Camera2D, run_rng: RandomNumberGenerator) -> void:
	enemies = manager
	camera = view_camera
	rng = run_rng


## Called by the run every physics frame with the current run time.
func tick(run_time: float, delta: float) -> void:
	if not active:
		return
	_owed += schedule.rate_at(run_time, goal_seconds) * rate_scale * boss_rate_scale() * delta
	while _owed >= 1.0:
		_owed -= 1.0
		spawn_one(schedule.enemy_at(run_time, rng))
	_spawn_due_elites(run_time)
	_spawn_due_mini_boss(run_time)


## Spawns one zombie of `stats` (an elite with `elite`) outside the screen. Returns null if there
## was no room or the maximum is reached.
func spawn_one(stats: EnemyStats, elite: EliteRules = null) -> Zombie:
	var at: Vector2 = _outside_view(stats.radius * (elite.size if elite != null else 1.0))
	if not at.is_finite():
		return null
	return enemies.spawn(stats, at, elite)


## Brings the boss `boss` in from outside the screen (or null if there was no room).
func spawn_boss(boss: BossDef) -> Zombie:
	var at: Vector2 = _outside_view(boss.enemy.radius * boss.size)
	if not at.is_finite():
		return null
	var zombie: Zombie = enemies.spawn_boss(boss, at)
	boss_spawned.emit(zombie)
	return zombie


## Normal spawning is lighter while a boss is on the field (1 = normal).
func boss_rate_scale() -> float:
	var lightest: float = 1.0
	for boss: Zombie in enemies.bosses():
		lightest = minf(lightest, boss.boss.spawn_rate_scale)
	return lightest


func _outside_view(radius: float) -> Vector2:
	var view: Rect2 = visible_rect()
	var area: Rect2 = enemies.play_rect
	return SpawnPlacement.outside_view(view, area, schedule.view_margin, radius, rng)


## The part of the world the camera shows right now.
func visible_rect() -> Rect2:
	var size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size / 2.0, size)


## An elite of `stats` outside the screen (or null, see `spawn_one`).
func spawn_elite(stats: EnemyStats) -> Zombie:
	var elite: Zombie = spawn_one(stats, schedule.elite_rules)
	if elite != null:
		elite_spawned.emit(elite)
	return elite


## Brings the elites whose time has come. Elites skipped by a time jump (developer menu) stay
## skipped instead of all arriving at once.
func _spawn_due_elites(run_time: float) -> void:
	while schedule.elite_time(_next_elite) <= run_time:
		if run_time - schedule.elite_time(_next_elite) <= MISSED_ELITE_SECONDS:
			spawn_elite(schedule.elite_enemy(_next_elite))
		_next_elite += 1


## Brings the mini-boss when its time has come (skipped like elites after a big time jump).
func _spawn_due_mini_boss(run_time: float) -> void:
	var boss: BossDef = schedule.mini_boss
	if _mini_boss_done or boss == null or run_time < boss.at_seconds:
		return
	_mini_boss_done = true
	if run_time - boss.at_seconds <= MISSED_ELITE_SECONDS:
		spawn_boss(boss)
