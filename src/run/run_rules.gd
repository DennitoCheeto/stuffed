class_name RunRules
extends Resource
## Balance numbers for a whole run. Tune them in data/run_rules.tres, not in code.

## Survive this long to reach the goal.
@export var goal_seconds: float = 300.0
## Never more zombies alive at once than this.
@export var max_enemies_alive: int = 500
