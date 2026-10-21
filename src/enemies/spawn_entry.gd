class_name SpawnEntry
extends Resource
## One zombie type in the spawn schedule: from when it appears and what share of new zombies it
## makes up. Shamblers fill whatever share is left. Tune it in data/spawn_schedule.tres.

@export var enemy: EnemyStats
## None of this type before this run time.
@export var start_seconds: float = 60.0
## Share of spawns (0..1) once it starts ...
@export var share: float = 0.2
## ... growing by this much per minute ...
@export var share_growth_per_minute: float = 0.0
## ... up to this.
@export var share_max: float = 0.2


## Chance (0..1) that a new zombie at `seconds` is of this type.
func chance_at(seconds: float) -> float:
	if enemy == null or seconds < start_seconds:
		return 0.0
	var minutes: float = (seconds - start_seconds) / 60.0
	return minf(share + share_growth_per_minute * minutes, share_max)
