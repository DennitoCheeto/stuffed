class_name SpawnSchedule
extends Resource
## When and how many zombies appear: a slowly rising base rate, a surge about every minute
## followed by a breather, and the biggest surge in the last seconds before the goal.
## Other zombie types join one after another (`entries`); shamblers fill the rest.
## Tune it in data/spawn_schedule.tres, not in code.

enum Phase { NORMAL, SURGE, BREATHER, FINAL_SURGE }

## The default zombie: every spawn that isn't one of the `entries`.
@export var shambler: EnemyStats
## Runners, spitters, bloaters, tanks: when each joins and how many of them.
@export var entries: Array[SpawnEntry] = []
## Zombies per second at 0:00 (before surge/breather multipliers).
@export var start_rate: float = 0.8
## Extra zombies per second added every minute.
@export var rate_growth_per_minute: float = 0.5
## How far outside the visible screen zombies appear, in pixels.
@export var view_margin: float = 80.0

@export_group("Elites")
## What makes a zombie an elite.
@export var elite_rules: EliteRules
## Elites before the boss, in time order (about 3-4 per run).
@export var elites: Array[EliteSpawn] = []
## After the last one, another elite every this many seconds (endless), cycling through the types.
@export var elite_repeat_seconds: float = 75.0

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


## The schedule entry for the zombie type called `display_name`, or null.
func entry_named(display_name: String) -> SpawnEntry:
	for entry: SpawnEntry in entries:
		if entry.enemy != null and entry.enemy.display_name == display_name:
			return entry
	return null


## Which zombie type to spawn at `seconds` into the run.
func enemy_at(seconds: float, rng: RandomNumberGenerator) -> EnemyStats:
	var roll: float = rng.randf()
	for entry: SpawnEntry in entries:
		var chance: float = entry.chance_at(seconds)
		if roll < chance:
			return entry.enemy
		roll -= chance
	return shambler


## When elite number `index` (0 = the first) comes. INF without elites.
func elite_time(index: int) -> float:
	if elites.is_empty():
		return INF
	if index < elites.size():
		return elites[index].at_seconds
	var after_last: int = index - elites.size() + 1
	return elites[elites.size() - 1].at_seconds + elite_repeat_seconds * after_last


## Which zombie type elite number `index` is an elite of.
func elite_enemy(index: int) -> EnemyStats:
	return elites[index % elites.size()].enemy


## How many elites come before `seconds` into the run.
func elites_before(seconds: float) -> int:
	var count: int = 0
	while elite_time(count) < seconds:
		count += 1
	return count
