class_name PlushieSpot
extends Resource
## A place in the Pillow Fort where rescued plushies like to hang out (spec 05 §3.4): reading by
## the fort, sitting at the Snack Bar table, napping at the Hospital, waving from the Watchtower
## lookout. One plushie at a time. Spots at a building only open once it is built far enough.
## Positions live in data/town/pillow_fort.tres.

## What a plushie does there.
enum Pose { READ, SIT, NAP, WAVE }

@export var id: StringName = &""
@export var pose: Pose = Pose.SIT
## Where the plushie's feet are while it hangs out (town pixels).
@export var at: Vector2 = Vector2.ZERO
## Where it walks to first and climbs up from (a lookout on a tower). Zero = it walks straight
## to `at`, which must then be on free floor.
@export var approach: Vector2 = Vector2.ZERO
## The building spot id this place belongs to (empty = always open, like the fort).
@export var building: StringName = &""
## The building level it needs (the table comes with the Snack Bar's Lv 2, ...).
@export var needs_level: int = 1


## Where the walk ends: the climb's foot, or the spot itself.
func walk_target() -> Vector2:
	return at if approach == Vector2.ZERO else approach


func needs_climb() -> bool:
	return approach != Vector2.ZERO


## True when the place exists in `save`'s town (its building stands at the level it needs).
func is_open(save: TownSave) -> bool:
	if building == &"":
		return true
	return save.building_level(String(building)) >= needs_level
