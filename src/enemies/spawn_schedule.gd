class_name SpawnSchedule
extends Resource
## When and how many zombies appear: a slowly rising base rate, a surge about every minute
## followed by a breather, and the biggest surge in the last seconds before the goal.
## Runners join after the first minute. Tune it in data/spawn_schedule.tres, not in code.

enum Phase { NORMAL, SURGE, BREATHER, FINAL_SURGE }

@export var shambler: EnemyStats
@export var runner: EnemyStats
## Zombies per second at 0:00 (before surge/breather multipliers).
@export var start_rate: float = 0.8
## Extra zombies per second added every minute.
@export var rate_growth_per_minute: float = 0.5
## How far outside the visible screen zombies appear, in pixels.
@export var view_margin: float = 80.0

@export_group("Surges and breathers")
## Length of one surge/breather rhythm.
@export var cycle_seconds: float = 60.0
## Seconds into each cycle when the surge starts.
@export var surge_starts_at: float = 30.0
@export var surge_seconds: float = 20.0
@export var surge_multiplier: float = 2.5
## The breather follows right after the surge.
@export var breather_seconds: float = 10.0
@export var breather_multiplier: float = 0.2
## The last seconds before the goal.
@export var final_surge_seconds: float = 30.0
@export var final_surge_multiplier: float = 3.0

@export_group("Runners")
## No runners before this time.
@export var runner_start_seconds: float = 60.0
## Share of spawns that are runners once they start ...
@export var runner_share: float = 0.25
## ... growing by this much per minute ...
@export var runner_share_growth_per_minute: float = 0.05
## ... up to this.
@export var runner_share_max: float = 0.5


## Which part of the rhythm `seconds` falls in. `goal_seconds` <= 0 means no final surge.
func phase_at(seconds: float, goal_seconds: float) -> Phase:
	var final_start: float = goal_seconds - final_surge_seconds
	if goal_seconds > 0.0 and seconds >= final_start and seconds < goal_seconds:
		return Phase.FINAL_SURGE
	var in_cycle: float = fmod(seconds, cycle_seconds)
	var surge_end: float = surge_starts_at + surge_seconds
	if in_cycle >= surge_starts_at and in_cycle < surge_end:
		return Phase.SURGE
	if in_cycle >= surge_end and in_cycle < surge_end + breather_seconds:
		return Phase.BREATHER
	return Phase.NORMAL


func phase_multiplier(phase: Phase) -> float:
	match phase:
		Phase.SURGE:
			return surge_multiplier
		Phase.BREATHER:
			return breather_multiplier
		Phase.FINAL_SURGE:
			return final_surge_multiplier
	return 1.0


## Zombies per second at `seconds` into the run.
func rate_at(seconds: float, goal_seconds: float) -> float:
	var base: float = start_rate + rate_growth_per_minute * seconds / 60.0
	return base * phase_multiplier(phase_at(seconds, goal_seconds))


## Chance (0..1) that a new zombie is a runner.
func runner_chance(seconds: float) -> float:
	if runner == null or seconds < runner_start_seconds:
		return 0.0
	var minutes: float = (seconds - runner_start_seconds) / 60.0
	return minf(runner_share + runner_share_growth_per_minute * minutes, runner_share_max)


## Which zombie type to spawn at `seconds` into the run.
func enemy_at(seconds: float, rng: RandomNumberGenerator) -> EnemyStats:
	if rng.randf() < runner_chance(seconds):
		return runner
	return shambler
