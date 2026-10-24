extends GutTest
## Unit (spec 04 §4.1, §4.4; AC-53, AC-57): the rules behind the end screen's weapon report.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")


func _row(id: String, player: int, damage: float, kills: int = 0, held: float = 0.0) -> Dictionary:
	return {
		"id": id,
		"name": id.capitalize(),
		"player": player,
		"weapon": player >= 0,
		"damage": damage,
		"kills": kills,
		"seconds_held": held,
		"level": 2,
		"evolved": false,
	}


func _result() -> RunResult:
	var result: RunResult = RunResult.new()
	result.weapons = [
		_row("thimble_mortar", 0, 500.0, 5, 50.0),
		_row("party_popper", -1, 300.0, 9),
		_row("peel_boomerang", 0, 900.0, 12, 100.0),
		_row("zipper_ray", 1, 50.0, 1, 10.0),
		_row("goal_pops", -1, 0.0, 0),
		_row("orbiting_needles", 0, 0.0, 0, 20.0),
	]
	result.total_damage = 1750.0
	result.items = [
		{"player": 0, "id": "quick_feet", "name": "Quick Feet", "level": 3},
		{"player": 1, "id": "big_spool", "name": "Big Spool", "level": 1},
	]
	return result


func test_short_numbers() -> void:
	assert_eq(WeaponReport.short_number(0.0), "0")
	assert_eq(WeaponReport.short_number(950.4), "950")
	assert_eq(WeaponReport.short_number(1000.0), "1k")
	assert_eq(WeaponReport.short_number(12345.0), "12.3k")
	assert_eq(WeaponReport.short_number(182400.0), "182.4k")
	assert_eq(WeaponReport.short_number(999_999.0), "1M")
	assert_eq(WeaponReport.short_number(1_234_567.0), "1.23M")


func test_grouped_numbers() -> void:
	assert_eq(WeaponReport.grouped(7), "7")
	assert_eq(WeaponReport.grouped(4321), "4,321")
	assert_eq(WeaponReport.grouped(1234567), "1,234,567")


func test_ac53_rows_are_the_players_weapons_biggest_damage_first() -> void:
	var rows: Array[Dictionary] = WeaponReport.rows_of(_result(), 0)
	var ids: PackedStringArray = []
	for row: Dictionary in rows:
		ids.append(row["id"])
	assert_eq(ids, PackedStringArray(["peel_boomerang", "thimble_mortar", "orbiting_needles"]))
	assert_eq(WeaponReport.star_of(_result(), 0)["id"], "peel_boomerang", "the star")
	assert_eq(WeaponReport.star_of(_result(), 1)["id"], "zipper_ray", "player 2's own star")
	assert_true(WeaponReport.star_of(_result(), 2).is_empty(), "no weapons, no star")


func test_ac53_damage_not_from_a_weapon_is_an_extra_line() -> void:
	var extras: Array[Dictionary] = WeaponReport.extras(_result())
	assert_eq(extras.size(), 1, "empty rows are left out")
	assert_eq(extras[0]["id"], "party_popper")
	assert_eq(EndScreen.extras_text(_result()), "Also: Party Popper: 300 damage, 9 kills")
	assert_eq(EndScreen.extras_text(RunResult.new()), "")


func test_ac53_numbers_of_a_row() -> void:
	var row: Dictionary = _row("peel_boomerang", 0, 900.0, 12, 100.0)
	assert_almost_eq(WeaponReport.dps(row), 9.0, 0.001, "damage per second held")
	assert_eq(WeaponReport.dps(_row("x", 0, 10.0)), 0.0, "never held = 0")
	assert_almost_eq(WeaponReport.share(row, 1800.0), 0.5, 0.001)
	assert_eq(WeaponReport.share(row, 0.0), 0.0)
	assert_eq(WeaponReport.level_text(row), "Lv 2")
	row["evolved"] = true
	assert_eq(WeaponReport.level_text(row), "EVO")


func test_ac53_items_are_tags_per_player() -> void:
	assert_eq(WeaponReport.item_tags(_result(), 0), PackedStringArray(["Quick Feet 3"]))
	assert_eq(WeaponReport.item_tags(_result(), 1), PackedStringArray(["Big Spool 1"]))


func test_ac57_one_column_per_player() -> void:
	var result: RunResult = _result()
	assert_eq(WeaponReport.player_count(result), 2, "player 2 has a row")
	result.player_count = 3
	assert_eq(WeaponReport.player_count(result), 3, "a player without hits still gets one")
	assert_eq(WeaponReport.player_count(RunResult.new()), 1)


func test_icons_of_weapons_and_evolved_weapons() -> void:
	assert_eq(WeaponReport.icon_for(POOL, &"peel_boomerang"), &"boomerang")
	assert_eq(WeaponReport.icon_for(POOL, &"banana_split"), &"split")
	assert_eq(WeaponReport.icon_for(POOL, &"unknown"), &"")


func test_ac53_a_column_shows_the_star_then_the_rows_and_evo() -> void:
	var result: RunResult = _result()
	result.weapons[2]["evolved"] = true
	var column: WeaponColumn = WeaponColumn.new(result, 0, POOL, false)
	add_child_autofree(column)
	assert_eq(column.star["id"], "peel_boomerang")
	assert_eq(column.star_damage_label.text, "900 damage")
	assert_eq(column.star_line_label.text, "EVO · 12 kills · 9 DPS · held 1:40")
	assert_eq(column.rows.size(), 2)
	var mortar: PackedStringArray = ["Thimble Mortar", "Lv 2", "500", "5", "10", "0:50"]
	assert_eq(column.rows[0].texts(), mortar)
	assert_eq(column.item_tags.size(), 1)
	assert_null(column.heading)
