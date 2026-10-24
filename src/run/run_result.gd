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
## Damage that landed in the whole run (the sum of `weapons`).
var total_damage: float = 0.0
## Per weapon and player, biggest damage first (spec 04 §4.1, WeaponTallyEntry.to_dict): id, name,
## player (-1 = not a weapon, e.g. the Party Popper), weapon, damage, kills, seconds_held, level,
## evolved. The kills add up to `kills`.
var weapons: Array[Dictionary] = []
## What hit Banane last before he fell ("" if he didn't fall).
var killed_by: String = ""
## Picked cards in order, e.g. "Quick Feet 2".
var upgrades: PackedStringArray = []
var seed_value: int = 0
## How the run ended: "died", "ended" (End run after the goal), "quit" (gave up) or "way_home"
## (the Way Home portal).
var ending: String = "died"
## Evolutions in order: {"weapon": evolved name, "time": run seconds, "player": 0-based index}.
var evolutions: Array[Dictionary] = []
## Player 1's rerolls, skips and banishes used.
var rerolls_used: int = 0
var skips_used: int = 0
var banishes_used: int = 0
## Run time when the mini-boss / the boss was beaten (-1 = not beaten).
var mini_boss_defeated_at: float = -1.0
var boss_defeated_at: float = -1.0
## Floor pickups grabbed, in order: {"name", "time": run seconds, "player": 0-based index}.
var floor_pickups: Array[Dictionary] = []
## Material id -> amount collected in the run (victory bonus included), and what went home.
var materials_collected: Dictionary[String, int] = {}
var materials_kept: Dictionary[String, int] = {}
## Weapons that could come up on cards this run (upgrade pool ids; the Toy Box Armory adds more).
var unlocked_weapons: PackedStringArray = []
## The rescue (spec 03 §7): {"plushie": id, "time": run seconds it appeared, "freed": bool,
## "freed_at": run seconds or -1}. Empty = no rescue appeared in this run.
var rescue: Dictionary = {}


## How the run ended for the town (spec 03 §10): "king", "way_home", "died" or "gave_up".
func run_end() -> String:
	if won:
		return "king"
	match ending:
		"way_home":
			return "way_home"
		"quit":
			return "gave_up"
	return "died"


## Id of the plushie freed in this run ("" = none).
func rescued_plushie() -> String:
	if rescue.get("freed", false):
		return str(rescue["plushie"])
	return ""


func title() -> String:
	if won:
		return "You survived!"
	if ending == "way_home":
		return "Home safe!"
	return "You gave up" if ending == "quit" else "Banane got stuffed"
