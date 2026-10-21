class_name Spawner
extends Node
## Brings new zombies into the run following the spawn schedule, always just outside the
## visible screen.

@export var schedule: SpawnSchedule

## The run goal (for the final surge); 0 = none.
var goal_seconds: float = 0.0
## Turned off when the goal is reached.
var active: bool = true
var enemies: EnemyManager
var camera: Camera2D
var rng: RandomNumberGenerator

## Fractional zombies owed (rate × time), so low rates still spawn evenly.
var _owed: float = 0.0


func setup(manager: EnemyManager, view_camera: Camera2D, run_rng: RandomNumberGenerator) -> void:
	enemies = manager
	camera = view_camera
	rng = run_rng


## Called by the run every physics frame with the current run time.
func tick(run_time: float, delta: float) -> void:
	if not active:
		return
	_owed += schedule.rate_at(run_time, goal_seconds) * delta
	while _owed >= 1.0:
		_owed -= 1.0
		spawn_one(schedule.enemy_at(run_time, rng))


## Spawns one zombie of `stats` outside the screen. Returns null if there was no room or the
## maximum is reached.
func spawn_one(stats: EnemyStats) -> Zombie:
	var view: Rect2 = visible_rect()
	var margin: float = schedule.view_margin
	var area: Rect2 = enemies.play_rect
	var at: Vector2 = SpawnPlacement.outside_view(view, area, margin, stats.radius, rng)
	if not at.is_finite():
		return null
	return enemies.spawn(stats, at)


## The part of the world the camera shows right now.
func visible_rect() -> Rect2:
	var size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size / 2.0, size)
