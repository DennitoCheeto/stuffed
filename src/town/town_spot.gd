class_name TownSpot
extends Resource
## One building spot in the Pillow Fort (spec 03 §5, §6): where it stands, which building goes
## there and when its ruin can be rebuilt.

@export var id: StringName = &""
## The building (name, costs, effects) in data/town/buildings/.
@export var building: BuildingDef
## Where the ruin (later the building) stands, in town pixels. It blocks walking.
@export var rect: Rect2 = Rect2(0, 0, 260, 180)
## How many buildings must be rebuilt before this one can be (0 = from the start).
@export var needs_rebuilds: int = 0
## Can only be rebuilt once a rescued plushie has been brought home.
@export var needs_rescue: bool = false


func display_name() -> String:
	return building.display_name


## True when the ruin can be rebuilt with `rebuilt` buildings in town and `has_rescue` plushies.
func is_unlocked(rebuilt: int, has_rescue: bool) -> bool:
	if needs_rescue and not has_rescue:
		return false
	return rebuilt >= needs_rebuilds


## False for the ruins that can be rebuilt from the very start (they never get a "New building!").
func starts_locked() -> bool:
	return needs_rescue or needs_rebuilds > 0


## What the sign says while the ruin is still tangled in zombie yarn.
func unlock_hint() -> String:
	if needs_rescue:
		return "Bring home a rescued plushie"
	if needs_rebuilds == 1:
		return "Rebuild 1 building first"
	return "Rebuild %d buildings first" % needs_rebuilds


func is_unlocked_in(town: TownSave) -> bool:
	return is_unlocked(town.rebuilt_count(), not town.plushies.is_empty())
