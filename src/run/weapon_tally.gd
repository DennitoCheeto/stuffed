class_name WeaponTally
extends RefCounted
## What each weapon did in one run, per player (spec 04 §4.1): damage dealt, kills and seconds
## held. An evolved weapon keeps its old weapon's numbers (one row). Damage that no weapon dealt
## (the Party Popper, the pops when the King falls) has its own row, so every row together adds up
## to the run's total damage and kills.

## Sources that are not weapons.
const PARTY_POPPER: StringName = &"party_popper"
const GOAL_POPS: StringName = &"goal_pops"
## Anything else (developer menu "kill all", a shot whose weapon just evolved away).
const OTHER: StringName = &"other"
const NAMES: Dictionary[StringName, String] = {
	PARTY_POPPER: "Party Popper",
	GOAL_POPS: "Victory pops",
	OTHER: "Other",
}

## Every row, in the order they first showed up.
var entries: Array[WeaponTallyEntry] = []
var total_damage: float = 0.0
var total_kills: int = 0


## `weapon` dealt `damage` (already capped at the zombie's health); `killed` = it popped.
func add_hit(weapon: Weapon, damage: float, killed: bool) -> void:
	if weapon == null or not is_instance_valid(weapon) or weapon.player == null:
		add_other(OTHER, damage, killed)
		return
	var entry: WeaponTallyEntry = _row_for(weapon)
	entry.level = weapon.level
	_count(entry, damage, killed)


## Damage or a kill from something that is not a weapon (`source` = PARTY_POPPER ...).
func add_other(source: StringName, damage: float, killed: bool) -> void:
	var entry: WeaponTallyEntry = find(-1, source)
	if entry == null:
		entry = WeaponTallyEntry.new()
		entry.id = source
		entry.display_name = NAMES.get(source, String(source))
		entry.is_weapon = false
		entries.append(entry)
	_count(entry, damage, killed)


## Adds `seconds` of holding to every weapon `player` has right now.
func hold(player: Player, seconds: float) -> void:
	for weapon: Weapon in player.weapons():
		var entry: WeaponTallyEntry = _row_for(weapon)
		entry.level = weapon.level
		entry.seconds += seconds


## `weapon` just replaced its old weapon (`stats.evolved_from`): the old row becomes its row.
func evolve(weapon: Weapon) -> void:
	var player: int = weapon.player.player_index
	var old: WeaponTallyEntry = find(player, weapon.stats.evolved_from)
	if old == null:
		old = _row_for(weapon)
	old.id = weapon.stats.id
	old.display_name = weapon.stats.display_name
	old.level = weapon.level
	old.evolved = true


## The row of weapon `id` for player `player` (-1 = not a weapon), or null.
func find(player: int, id: StringName) -> WeaponTallyEntry:
	for entry: WeaponTallyEntry in entries:
		if entry.player == player and entry.id == id:
			return entry
	return null


## Rows sorted by damage, biggest first (the end screen's order).
func by_damage() -> Array[WeaponTallyEntry]:
	var sorted: Array[WeaponTallyEntry] = entries.duplicate()
	sorted.sort_custom(_more_damage)
	return sorted


## Every row as plain data (RunResult and the run log), biggest damage first.
func to_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: WeaponTallyEntry in by_damage():
		list.append(entry.to_dict())
	return list


static func _more_damage(a: WeaponTallyEntry, b: WeaponTallyEntry) -> bool:
	return a.damage > b.damage


func _row_for(weapon: Weapon) -> WeaponTallyEntry:
	var player: int = weapon.player.player_index
	var entry: WeaponTallyEntry = find(player, weapon.stats.id)
	if entry == null:
		entry = WeaponTallyEntry.new()
		entry.id = weapon.stats.id
		entry.display_name = weapon.stats.display_name
		entry.player = player
		entry.evolved = not weapon.stats.evolved_from.is_empty()
		entries.append(entry)
	return entry


func _count(entry: WeaponTallyEntry, damage: float, killed: bool) -> void:
	entry.damage += damage
	total_damage += damage
	if killed:
		entry.kills += 1
		total_kills += 1
