class_name MaterialRules
extends Resource
## How much of a run's haul goes home (spec 03 §3).
## Tune it in data/town/material_rules.tres, not in code.

## Share kept after beating the King (endless included).
@export var keep_share_won: float = 1.0
## Share kept after getting stuffed or giving up (also a run the game closed during).
@export var keep_share_lost: float = 0.5


## The share of the haul a finished run takes home.
func keep_share(result: RunResult) -> float:
	return keep_share_won if result.won else keep_share_lost
