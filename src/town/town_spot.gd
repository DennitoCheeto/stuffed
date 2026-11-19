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
## Only appears (and can be rebuilt) once the town owns a gear pattern (spec 09 §5): until
## then the spot is empty quilt, no ruin, nothing blocks.
@export var needs_pattern: bool = false
## The coloured thread path from the tape measure road to the building (spec 05 §3.1): points
## along it, drawn smooth. It starts on the road and never crosses anything that blocks.
@export var thread_path: PackedVector2Array = []


func display_name() -> String:
	return building.display_name


## True when the ruin can be rebuilt with `rebuilt` buildings in town, `has_rescue` plushies
## and `has_pattern` gear patterns.
func is_unlocked(rebuilt: int, has_rescue: bool, has_pattern: bool = false) -> bool:
	if needs_pattern and not has_pattern:
		return false
	if needs_rescue and not has_rescue:
		return false
	return rebuilt >= needs_rebuilds


## False for the ruins that can be rebuilt from the very start (they never get a "New building!").
func starts_locked() -> bool:
	return needs_rescue or needs_pattern or needs_rebuilds > 0


## What the sign says while the ruin is still tangled in zombie yarn.
func unlock_hint() -> String:
	if needs_pattern:
		return "Find a gear pattern first"
	if needs_rescue:
		return "Bring home a rescued plushie"
	if needs_rebuilds == 1:
		return "Rebuild 1 building first"
	return "Rebuild %d buildings first" % needs_rebuilds


func is_unlocked_in(town: TownSave) -> bool:
	var has_pattern: bool = not town.gear.patterns.is_empty()
	return is_unlocked(town.rebuilt_count(), not town.plushies.is_empty(), has_pattern)


## True while the spot shows nothing at all: it waits for a pattern and its "New building!"
## moment hasn't played yet (spec 09 §5).
func is_hidden_in(town: TownSave) -> bool:
	if not needs_pattern or town.building_level(String(id)) > 0:
		return false
	return not town.revealed.has(String(id))
