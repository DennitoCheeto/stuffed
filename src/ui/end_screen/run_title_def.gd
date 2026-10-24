class_name RunTitleDef
extends Resource
## One run title (spec 04 §4.2): its words, when a run earns it and how rare it is. The list lives
## in data/ui/run_titles.tres (RunTitleRules), so new titles take minutes.

## What a run must have done. `amount` is the number in the condition.
enum Check {
	## One weapon did at least `amount` (0.6 = 60%) of all damage. Words: the weapon's run title.
	WEAPON_SHARE,
	## Some hero took no damage for `amount` seconds in a row.
	UNHURT_SECONDS,
	## Beat the King with less than `amount` (0.15 = 15%) of the health left.
	CLOSE_CALL,
	## Beat the King before `amount` seconds.
	FAST_KING,
	## At least `amount` evolutions.
	EVOLUTIONS,
	## Opened at least `amount` gift boxes.
	GIFT_BOXES,
	## Grabbed at least `amount` floor pickups of kind `pickup_id`.
	FLOOR_PICKUPS,
	## Freed a tangled plushie.
	RESCUE,
	## At least `amount` seconds in endless.
	ENDLESS_SECONDS,
	## At least `amount` new Scrapbook entries in the run.
	NEW_ENTRIES,
	## Got stuffed (lost) before `amount` seconds.
	STUFFED_BEFORE,
	## Always fits (the fallback).
	ALWAYS,
}

## Stable name for the save ("seen before") and the run log.
@export var id: StringName = &""
## The sticker's words. "{weapon}" becomes the weapon's run title, "{kills}" the zombies stuffed.
@export var text: String = ""
@export var check: Check = Check.ALWAYS
@export var amount: float = 0.0
## For FLOOR_PICKUPS: the floor pickup id (FloorPickupDef.id).
@export var pickup_id: StringName = &""
## Higher = rarer; the rarest titles go on the page first.
@export var rarity: int = 1
## A gentle joke about a bad run: a page never gets two of them.
@export var bad: bool = false
