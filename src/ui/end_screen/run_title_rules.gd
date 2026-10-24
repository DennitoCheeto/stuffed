class_name RunTitleRules
extends Resource
## Which titles a run earns (spec 04 §4.2): every title whose condition fits, rarest first, at
## most `max_titles`, never two "bad" ones, and the fallback when nothing nice fits.

## The weapon title's words when a weapon has no run title of its own.
const WEAPON_TEXT_FALLBACK: String = "%s Fan"

## In order: on equal rarity the earlier one goes first.
@export var titles: Array[RunTitleDef] = []
## Given when no other title fits (or only a bad one did): always something nice.
@export var fallback: RunTitleDef
@export var max_titles: int = 2
## Seconds between two title stickers slapping on (after the Star of the run).
@export var slap_gap: float = 0.25


## The titles `result` earned, rarest first.
func pick(result: RunResult) -> Array[RunTitle]:
	var fitting: Array[RunTitle] = []
	for def: RunTitleDef in titles:
		var title: RunTitle = earned(def, result)
		if title != null:
			fitting.append(title)
	var order: Array[RunTitle] = fitting.duplicate()
	order.sort_custom(_before.bind(fitting))
	var chosen: Array[RunTitle] = []
	var has_bad: bool = false
	var has_nice: bool = false
	for title: RunTitle in order:
		if chosen.size() >= max_titles:
			break
		if title.bad and has_bad:
			continue
		has_bad = has_bad or title.bad
		has_nice = has_nice or not title.bad
		chosen.append(title)
	if not has_nice and fallback != null:
		if chosen.size() >= max_titles:
			chosen.pop_back()
		chosen.append(_title_of(fallback, result, ""))
	return chosen


## The title `def` gives `result`, or null if the run didn't earn it.
func earned(def: RunTitleDef, result: RunResult) -> RunTitle:
	if def.check == RunTitleDef.Check.WEAPON_SHARE:
		var weapon: String = top_weapon(result, def.amount)
		if weapon.is_empty():
			return null
		return _title_of(def, result, weapon)
	if fits(def, result):
		return _title_of(def, result, "")
	return null


## Whether `result` meets `def`'s condition (not for WEAPON_SHARE: see top_weapon).
static func fits(def: RunTitleDef, result: RunResult) -> bool:
	var goal_time: float = result.survived_seconds - result.endless_seconds
	var health: float = result.lowest_health_at_goal
	var ok: bool = false
	match def.check:
		RunTitleDef.Check.UNHURT_SECONDS:
			ok = result.longest_unhurt_seconds >= def.amount
		RunTitleDef.Check.CLOSE_CALL:
			ok = result.won and health >= 0.0 and health < def.amount
		RunTitleDef.Check.FAST_KING:
			ok = result.won and goal_time < def.amount
		RunTitleDef.Check.EVOLUTIONS:
			ok = result.evolutions.size() >= def.amount
		RunTitleDef.Check.GIFT_BOXES:
			ok = result.gift_boxes_opened >= def.amount
		RunTitleDef.Check.FLOOR_PICKUPS:
			ok = pickups_of(result, def.pickup_id) >= def.amount
		RunTitleDef.Check.RESCUE:
			ok = not result.rescued_plushie().is_empty()
		RunTitleDef.Check.ENDLESS_SECONDS:
			ok = result.endless_seconds >= def.amount
		RunTitleDef.Check.NEW_ENTRIES:
			ok = result.new_scrapbook_entries >= def.amount
		RunTitleDef.Check.STUFFED_BEFORE:
			ok = result.run_end() == "died" and result.survived_seconds < def.amount
		RunTitleDef.Check.ALWAYS:
			ok = true
	return ok


## The weapon id that did at least `share` of the whole run's damage (all players together), or
## "" if none did.
static func top_weapon(result: RunResult, share: float) -> String:
	if result.total_damage <= 0.0:
		return ""
	var damage: Dictionary[String, float] = {}
	for row: Dictionary in result.weapons:
		if row.get("weapon", true):
			var id: String = str(row["id"])
			damage[id] = damage.get(id, 0.0) + float(row.get("damage", 0))
	for id: String in damage:
		if damage[id] >= share * result.total_damage:
			return id
	return ""


## How many floor pickups of kind `id` the run grabbed.
static func pickups_of(result: RunResult, id: StringName) -> int:
	var count: int = 0
	for entry: Dictionary in result.floor_pickups:
		if str(entry.get("id", "")) == String(id):
			count += 1
	return count


func _title_of(def: RunTitleDef, result: RunResult, weapon: String) -> RunTitle:
	var words: String = def.text.replace("{kills}", WeaponReport.grouped(result.kills))
	var id: String = String(def.id)
	if not weapon.is_empty():
		words = words.replace("{weapon}", _weapon_text(result, weapon))
		id += ":" + weapon
	return RunTitle.new(id, words, def.rarity, def.bad)


static func _weapon_text(result: RunResult, weapon: String) -> String:
	var words: String = result.weapon_titles.get(weapon, "")
	if not words.is_empty():
		return words
	for row: Dictionary in result.weapons:
		if str(row["id"]) == weapon:
			return WEAPON_TEXT_FALLBACK % str(row.get("name", weapon))
	return WEAPON_TEXT_FALLBACK % weapon


## Rarest first; on equal rarity the one listed first (in `listed`).
static func _before(a: RunTitle, b: RunTitle, listed: Array[RunTitle]) -> bool:
	if a.rarity != b.rarity:
		return a.rarity > b.rarity
	return listed.find(a) < listed.find(b)
