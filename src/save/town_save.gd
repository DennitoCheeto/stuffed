class_name TownSave
extends RefCounted
## Everything the game remembers between sessions (spec 03 §9): the town's materials, building
## levels, plushies, Scrapbook, run count and a run that was still going when the game closed.
## Written to disk by SaveStore. Unlocks (weapons, rerolls, ...) follow from the building levels.

## Bump when the meaning of a field changes; from_dict upgrades older saves.
const VERSION: int = 2
## Plushie ids of the placeholder plushies (version 1) -> the real plushies that replaced them.
const OLD_PLUSHIE_IDS: Dictionary[String, String] = {
	"kitty": "pip",
	"bear": "bobo",
	"bunny": "bambam",
	"froggy": "robbar",
}

## Material id ("coins", "stuffing", "thread") -> amount in the town's jars.
var materials: Dictionary[String, int] = {}
## Building id -> level (0 = still a ruin, 1-3 = rebuilt).
var building_levels: Dictionary[String, int] = {}
## Plushie id -> "waiting" (in the tent) or "in_town" (moved in), in the order they came home.
var plushies: Dictionary[String, String] = {}
## Scrapbook page -> ids seen on it (e.g. "weapons" -> ["peel_boomerang"]).
var seen: Dictionary[String, PackedStringArray] = {}
## Buildings whose "New building!" moment was shown (the yarn fell away).
var revealed: PackedStringArray = []
## Runs started with this town (the first one is run 1).
var runs_started: int = 0
## Banane's chosen starting weapon ("" = his own).
var start_weapon: String = ""
## The haul of a run that was still going when last saved (RunHaul.to_dict(); empty = none).
var unfinished_run: Dictionary = {}


func material(id: String) -> int:
	return materials.get(id, 0)


func building_level(id: String) -> int:
	return building_levels.get(id, 0)


## How many buildings are rebuilt (level 1 or more).
func rebuilt_count() -> int:
	var count: int = 0
	for id: String in building_levels:
		if building_levels[id] > 0:
			count += 1
	return count


## Rebuilds and upgrades done so far (the sum of all building levels).
func total_levels() -> int:
	var total: int = 0
	for id: String in building_levels:
		total += building_levels[id]
	return total


## Material id -> how much is still missing to pay `cost` (empty = the jars hold enough).
func missing(cost: Dictionary[String, int]) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for id: String in cost:
		if material(id) < cost[id]:
			result[id] = cost[id] - material(id)
	return result


func can_afford(cost: Dictionary[String, int]) -> bool:
	return missing(cost).is_empty()


## Takes `cost` out of the jars. Does nothing and returns false if they don't hold enough.
func spend(cost: Dictionary[String, int]) -> bool:
	if not can_afford(cost):
		return false
	for id: String in cost:
		materials[id] = material(id) - cost[id]
	return true


## Plushies that moved into town.
func plushies_in_town() -> int:
	var count: int = 0
	for id: String in plushies:
		if plushies[id] == "in_town":
			count += 1
	return count


## Plushies still waiting in the tent for a Hospital bed (first come, first served).
func waiting_plushies() -> PackedStringArray:
	var result: PackedStringArray = []
	for id: String in plushies:
		if plushies[id] == "waiting":
			result.append(id)
	return result


## Adds `share` of a run's haul to the jars (rounded up; coins get `coin_bonus` more, from
## plushies in town) and takes in its freed plushie.
func bank(haul: RunHaul, share: float, coin_bonus: float = 0.0) -> void:
	var kept: Dictionary[String, int] = haul.kept(share, coin_bonus)
	for id: String in kept:
		materials[id] = material(id) + kept[id]
	if not haul.rescued.is_empty() and not plushies.has(haul.rescued):
		plushies[haul.rescued] = "waiting"


## A run that never finished (the game closed) counts as given up: `share` of it is banked.
## Returns true if there was one.
func settle_unfinished_run(share: float, coin_bonus: float = 0.0) -> bool:
	if unfinished_run.is_empty():
		return false
	bank(RunHaul.from_dict(unfinished_run), share, coin_bonus)
	unfinished_run = {}
	return true


func mark_seen(page: String, id: String) -> void:
	var ids: PackedStringArray = seen.get(page, PackedStringArray())
	if not ids.has(id):
		ids.append(id)
	seen[page] = ids


func has_seen(page: String, id: String) -> bool:
	return seen.has(page) and seen[page].has(id)


func to_dict() -> Dictionary:
	var pages: Dictionary = {}
	for page: String in seen:
		pages[page] = Array(seen[page])
	return {
		"version": VERSION,
		"materials": materials.duplicate(),
		"building_levels": building_levels.duplicate(),
		"plushies": plushies.duplicate(),
		"seen": pages,
		"revealed": Array(revealed),
		"runs_started": runs_started,
		"start_weapon": start_weapon,
		"unfinished_run": unfinished_run.duplicate(true),
	}


## Reads a saved dictionary; missing fields keep their defaults, so older saves still load.
static func from_dict(data: Dictionary) -> TownSave:
	var save: TownSave = TownSave.new()
	for key: String in _dict(data, "materials"):
		save.materials[key] = int(data["materials"][key])
	for key: String in _dict(data, "building_levels"):
		save.building_levels[key] = int(data["building_levels"][key])
	var old: bool = int(data.get("version", VERSION)) < 2
	for key: String in _dict(data, "plushies"):
		var id: String = OLD_PLUSHIE_IDS.get(key, key) if old else key
		save.plushies[id] = str(data["plushies"][key])
	for key: String in _dict(data, "seen"):
		var ids: Variant = data["seen"][key]
		if ids is Array:
			save.seen[key] = PackedStringArray(ids as Array)
	var shown: Variant = data.get("revealed", [])
	if shown is Array:
		save.revealed = PackedStringArray(shown as Array)
	save.runs_started = int(data.get("runs_started", 0))
	save.start_weapon = str(data.get("start_weapon", ""))
	var unfinished: Variant = data.get("unfinished_run", {})
	if unfinished is Dictionary:
		var saved: Dictionary = unfinished as Dictionary
		if not saved.is_empty():
			var haul: RunHaul = RunHaul.from_dict(saved)
			if old:
				haul.rescued = OLD_PLUSHIE_IDS.get(haul.rescued, haul.rescued)
			save.unfinished_run = haul.to_dict()
	return save


## The keys of a nested dictionary field as strings (none if it's missing or not a dictionary).
static func _dict(data: Dictionary, field: String) -> PackedStringArray:
	var value: Variant = data.get(field, {})
	var keys: PackedStringArray = []
	if value is Dictionary:
		for key: Variant in value as Dictionary:
			keys.append(str(key))
	return keys
