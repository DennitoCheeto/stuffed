class_name RunRules
extends Resource
## Balance numbers for a whole run. Tune them in data/run_rules.tres, not in code.

## Survive this long to reach the goal.
@export var goal_seconds: float = 480.0
## Never more zombies alive at once than this.
@export var max_enemies_alive: int = 500

@export_group("Endless (after the goal)")
## Every endless minute: new zombies get this much more health (0.15 = +15%) ...
@export var endless_health_growth_per_minute: float = 0.15
## ... and this much more contact damage ...
@export var endless_damage_growth_per_minute: float = 0.15
## ... and this many more zombies spawn (0.1 = +10%).
@export var endless_spawn_growth_per_minute: float = 0.1


## Zombie health multiplier after `minute` full endless minutes.
func endless_health_scale(minute: int) -> float:
	return 1.0 + endless_health_growth_per_minute * minute


func endless_damage_scale(minute: int) -> float:
	return 1.0 + endless_damage_growth_per_minute * minute


func endless_spawn_scale(minute: int) -> float:
	return 1.0 + endless_spawn_growth_per_minute * minute
