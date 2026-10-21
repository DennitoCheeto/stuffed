class_name Spawner
extends Node
## Brings new zombies into the run following the spawn schedule, always just outside the
## visible screen.

## An elite appeared (sound, tests).
signal elite_spawned(elite: Zombie)

## An elite more than this many seconds overdue (after a time jump) is skipped.
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


func setup(manager: EnemyManager, view_camera: Camera2D, run_rng: RandomNumberGenerator) -> void:
	enemies = manager
	camera = view_camera
	rng = run_rng


## Called by the run every physics frame with the current run time.
func tick(run_time: float, delta: float) -> void:
	if not active:
		return
	_owed += schedule.rate_at(run_time, goal_seconds) * rate_scale * delta
	while _owed >= 1.0:
		_owed -= 1.0
		spawn_one(schedule.enemy_at(run_time, rng))
	_spawn_due_elites(run_time)


## Spawns one zombie of `stats` (an elite with `elite`) outside the screen. Returns null if there
## was no room or the maximum is reached.
func spawn_one(stats: EnemyStats, elite: EliteRules = null) -> Zombie:
	var view: Rect2 = visible_rect()
	var margin: float = schedule.view_margin
	var area: Rect2 = enemies.play_rect
	var radius: float = stats.radius * (elite.size if elite != null else 1.0)
	var at: Vector2 = SpawnPlacement.outside_view(view, area, margin, radius, rng)
	if not at.is_finite():
		return null
	return enemies.spawn(stats, at, elite)


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
