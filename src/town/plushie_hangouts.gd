class_name PlushieHangouts
extends RefCounted
## Keeps track of the town's plushie spots (`PlushieSpot`, spec 05 §3.4): which ones are open in
## the saved town and which plushie is using one right now (one plushie per spot).

var spots: Array[PlushieSpot] = []
var save: TownSave
## Spot id -> the plushie hanging out there (or on its way).
var taken: Dictionary[StringName, TownPlushie] = {}


func _init(all: Array[PlushieSpot], town_save: TownSave) -> void:
	spots = all
	save = town_save


## Spots that exist in the town now and nobody uses.
func free_spots() -> Array[PlushieSpot]:
	var result: Array[PlushieSpot] = []
	for spot: PlushieSpot in spots:
		if spot.is_open(save) and not taken.has(spot.id):
			result.append(spot)
	return result


## A random free spot (null = none).
func pick(rng: RandomNumberGenerator) -> PlushieSpot:
	var free: Array[PlushieSpot] = free_spots()
	if free.is_empty():
		return null
	return free[rng.randi_range(0, free.size() - 1)]


## Reserves `spot` for `who`. False if someone else has it or it isn't open.
func claim(spot: PlushieSpot, who: TownPlushie) -> bool:
	if not spot.is_open(save) or (taken.has(spot.id) and taken[spot.id] != who):
		return false
	taken[spot.id] = who
	return true


## `who` leaves whatever spot it had.
func release(who: TownPlushie) -> void:
	for id: StringName in taken.keys():
		if taken[id] == who:
			taken.erase(id)


func find(id: StringName) -> PlushieSpot:
	for spot: PlushieSpot in spots:
		if spot.id == id:
			return spot
	return null
