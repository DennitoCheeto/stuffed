class_name SpawnSchedule
extends Resource
## When and how many zombies appear. Tune it in data/spawn_schedule.tres, not in code.

@export var shambler: EnemyStats
## Zombies per second at 0:00.
@export var start_rate: float = 1.0
## Extra zombies per second added every minute.
@export var rate_growth_per_minute: float = 1.0
## How far outside the visible screen zombies appear, in pixels.
@export var view_margin: float = 80.0


## Zombies per second at `seconds` into the run.
func rate_at(seconds: float) -> float:
	return start_rate + rate_growth_per_minute * seconds / 60.0


## Which zombie type to spawn at `seconds` into the run.
func enemy_at(_seconds: float, _rng: RandomNumberGenerator) -> EnemyStats:
	return shambler
