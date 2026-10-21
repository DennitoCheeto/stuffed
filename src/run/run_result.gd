class_name RunResult
extends RefCounted
## How a finished run went: shown on the end screen and written to the run log.

## The goal was reached (dying in endless still counts as a win).
var won: bool = false
## Total run time, endless included.
var survived_seconds: float = 0.0
## Time played after the goal (0 without endless).
var endless_seconds: float = 0.0
var level: int = 1
var kills: int = 0
## What hit Banane last before he fell ("" if he didn't fall).
var killed_by: String = ""
## Picked cards in order, e.g. "Quick Feet 2".
var upgrades: PackedStringArray = []
var seed_value: int = 0
## How the run ended: "died" or "ended" (End run after the goal).
var ending: String = "died"


func title() -> String:
	return "You survived!" if won else "Banane got stuffed"
