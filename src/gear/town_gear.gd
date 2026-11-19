class_name TownGear
extends RefCounted
## The town's sewn-on gear in the save (spec 09 §8, §9): what the town owns (patterns found,
## pieces sewn and their stitch levels, shared by everyone) and what each player slot wears and
## hides. Part of `TownSave` (`save.gear`); the rules for changing it are in `GearBook`.

## Gear ids whose sewing pattern was found, in the order they were found.
var patterns: PackedStringArray = []
## Gear id -> stitch level (1-3). Pieces not sewn yet aren't listed.
var stitches: Dictionary[String, int] = {}
## Per player slot (0 = player 1): slot name ("head", "body", "charm") -> gear id worn there.
var worn: Array[Dictionary] = []
## Per player slot: slot names whose piece isn't drawn on the hero (it still works).
var hidden: Array[PackedStringArray] = []


func has_pattern(id: String) -> bool:
	return patterns.has(id)


## Remembers pattern `id`. Returns true if it is new.
func add_pattern(id: String) -> bool:
	if patterns.has(id):
		return false
	patterns.append(id)
	return true


## The stitch level of piece `id` (0 = not sewn).
func stitch_level(id: String) -> int:
	return stitches.get(id, 0)


func is_sewn(id: String) -> bool:
	return stitch_level(id) > 0


## The gear id player `player` wears in slot `slot` ("" = nothing).
func worn_in(player: int, slot: String) -> String:
	if player < 0 or player >= worn.size():
		return ""
	return str(worn[player].get(slot, ""))


## The player slot wearing piece `id` (-1 = nobody).
func wearer_of(id: String) -> int:
	for player: int in worn.size():
		if worn[player].values().has(id):
			return player
	return -1


## Player `player` wears piece `id` in `slot` (no rules checked: see `GearBook.wear`).
func put_on(player: int, slot: String, id: String) -> void:
	while worn.size() <= player:
		worn.append({})
	worn[player][slot] = id


func take_off(player: int, slot: String) -> void:
	if player < worn.size():
		worn[player].erase(slot)


func is_hidden(player: int, slot: String) -> bool:
	return player >= 0 and player < hidden.size() and hidden[player].has(slot)


## True when player `player` hides gear slot `slot` (a `GearDef.Slot`; -1 = every slot hidden).
func slot_hidden(player: int, slot: int) -> bool:
	if slot >= 0:
		return is_hidden(player, GearDef.SLOT_NAMES[slot])
	for slot_name: String in GearDef.SLOT_NAMES:
		if not is_hidden(player, slot_name):
			return false
	return true


## Hides (or shows again) what player `player` wears in `slot`.
func set_hidden(player: int, slot: String, on: bool) -> void:
	while hidden.size() <= player:
		hidden.append(PackedStringArray())
	var slots: PackedStringArray = hidden[player]
	var at: int = slots.find(slot)
	if on and at < 0:
		slots.append(slot)
	elif not on and at >= 0:
		slots.remove_at(at)
	hidden[player] = slots


## "Hide all" / "Show all" for player `player`.
func set_all_hidden(player: int, on: bool) -> void:
	for slot: String in GearDef.SLOT_NAMES:
		set_hidden(player, slot, on)


## Nothing owned, worn or hidden.
func clear() -> void:
	patterns.clear()
	stitches.clear()
	worn.clear()
	hidden.clear()


## Writes the save fields `patterns`, `gear`, `worn` and `hidden` into `data`.
func write_to(data: Dictionary) -> void:
	data["patterns"] = Array(patterns)
	data["gear"] = stitches.duplicate()
	var worn_list: Array = []
	for slots: Dictionary in worn:
		worn_list.append(slots.duplicate())
	data["worn"] = worn_list
	var hidden_list: Array = []
	for slots: PackedStringArray in hidden:
		hidden_list.append(Array(slots))
	data["hidden"] = hidden_list


## Reads what `write_to` wrote; missing or broken fields (saves before version 7) are empty.
static func read_from(data: Dictionary) -> TownGear:
	var gear: TownGear = TownGear.new()
	var found: Variant = data.get("patterns", [])
	if found is Array:
		gear.patterns = PackedStringArray(found as Array)
	var sewn: Variant = data.get("gear", {})
	if sewn is Dictionary:
		for key: Variant in sewn as Dictionary:
			var at: int = int((sewn as Dictionary)[key])
			if at > 0:
				gear.stitches[str(key)] = at
	var worn_list: Variant = data.get("worn", [])
	if worn_list is Array:
		for slots: Variant in worn_list as Array:
			gear.worn.append(_slots_from(slots))
	var hidden_list: Variant = data.get("hidden", [])
	if hidden_list is Array:
		for slots: Variant in hidden_list as Array:
			var names: PackedStringArray = []
			if slots is Array:
				names = PackedStringArray(slots as Array)
			gear.hidden.append(names)
	return gear


## One player's worn slots as slot name -> gear id strings (empty if broken).
static func _slots_from(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key: Variant in value as Dictionary:
			result[str(key)] = str((value as Dictionary)[key])
	return result
