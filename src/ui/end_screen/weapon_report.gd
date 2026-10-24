class_name WeaponReport
extends RefCounted
## The rules of the end screen's weapon report (spec 04 §4.1), read from a RunResult: whose rows go
## where, the Star of the run, and the short numbers ("12.3k", "1.23M").
## Rows are RunResult.weapons dictionaries (WeaponTallyEntry.to_dict).


## The weapon rows of player `player`, biggest damage first.
static func rows_of(result: RunResult, player: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in result.weapons:
		if row.get("weapon", true) and int(row.get("player", 0)) == player:
			rows.append(row)
	rows.sort_custom(_more_damage)
	return rows


## The Star of the run of `player`: their weapon with the most damage ({} = no weapon).
static func star_of(result: RunResult, player: int) -> Dictionary:
	var rows: Array[Dictionary] = rows_of(result, player)
	return rows[0] if not rows.is_empty() else {}


## Damage that no weapon dealt (Party Popper, Victory pops ...), biggest first; empty rows left out.
static func extras(result: RunResult) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in result.weapons:
		var counts: bool = float(row.get("damage", 0)) > 0.0 or int(row.get("kills", 0)) > 0
		if not row.get("weapon", true) and counts:
			rows.append(row)
	rows.sort_custom(_more_damage)
	return rows


## How many weapon columns the end screen shows (one per player, at least one).
static func player_count(result: RunResult) -> int:
	var count: int = maxi(result.player_count, 1)
	for row: Dictionary in result.weapons:
		count = maxi(count, int(row.get("player", 0)) + 1)
	return count


## The items player `player` had, as "Quick Feet 3" tags.
static func item_tags(result: RunResult, player: int) -> PackedStringArray:
	var tags: PackedStringArray = []
	for item: Dictionary in result.items:
		if int(item.get("player", 0)) == player:
			tags.append("%s %d" % [item["name"], int(item["level"])])
	return tags


## Share of the whole run's damage (0..1) for the damage bar.
static func share(row: Dictionary, total_damage: float) -> float:
	if total_damage <= 0.0:
		return 0.0
	return clampf(float(row.get("damage", 0)) / total_damage, 0.0, 1.0)


## Damage per second held (0 if never held).
static func dps(row: Dictionary) -> float:
	var held: float = float(row.get("seconds_held", 0.0))
	return float(row.get("damage", 0)) / held if held > 0.0 else 0.0


## "EVO" for an evolved weapon, else "Lv 5".
static func level_text(row: Dictionary) -> String:
	return "EVO" if row.get("evolved", false) else "Lv %d" % int(row.get("level", 1))


## Big numbers made short: 950 -> "950", 12345 -> "12.3k", 1234567 -> "1.23M".
static func short_number(value: float) -> String:
	var whole: int = roundi(value)
	if whole < 1000:
		return str(whole)
	if whole < 999_950:
		return "%sk" % _trim("%.1f" % (whole / 1000.0))
	return "%sM" % _trim("%.2f" % (whole / 1_000_000.0))


## Thousands with commas: 4321 -> "4,321".
static func grouped(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out


## The icon of weapon `id` in `pool` (evolved weapons use their evolution's icon).
static func icon_for(pool: UpgradePool, id: StringName) -> StringName:
	var upgrade: UpgradeDef = pool.find(id)
	if upgrade != null:
		return upgrade.icon
	var evolution: EvolutionDef = pool.evolution_into(id)
	return evolution.icon if evolution != null else &""


static func _more_damage(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("damage", 0)) > float(b.get("damage", 0))


## "12.0" -> "12", "1.50" -> "1.5".
static func _trim(number: String) -> String:
	if not number.contains("."):
		return number
	return number.rstrip("0").trim_suffix(".")
