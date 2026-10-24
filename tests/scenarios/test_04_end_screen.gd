extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §4.1, §4.4; AC-53, AC-57): after a real run the end screen lists every weapon
## with level/EVO, damage, kills, DPS and time held, biggest damage first, the top one as the Star
## of the run (a photo with its sticker); items are tags; the run log has the `weapons` field. With
## two players each gets a column with their own Star of the run. (It fits: test_04_fit_check.)

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Seconds the weapons get to work on the zombies.
const FIGHT_SECONDS: float = 4.0

var run: Run


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	for player: Player in Players.all(run.get_tree()):
		player.invincible = true
	return run


## Rings of shamblers around every hero, then time for the weapons to work.
func _fight() -> void:
	for player: Player in Players.all(run.get_tree()):
		for i: int in 12:
			var at: Vector2 = Vector2.from_angle(TAU * i / 12.0) * (140.0 + 40.0 * (i % 3))
			run.enemies.spawn(SHAMBLER, player.global_position + at)
	await wait_seconds(FIGHT_SECONDS)


## Gives up from the pause menu and returns the end screen.
func _give_up() -> EndScreen:
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(3)
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end, "the end screen is shown")
	return end


func _ids(rows: Array[Dictionary]) -> PackedStringArray:
	var ids: PackedStringArray = []
	for row: Dictionary in rows:
		ids.append(str(row["id"]))
	return ids


func _assert_star(column: WeaponColumn, result: RunResult) -> void:
	var expected: Dictionary = WeaponReport.star_of(result, column.player)
	assert_false(column.star.is_empty(), "player %d has a Star of the run" % (column.player + 1))
	if column.star.is_empty():
		return
	assert_eq(column.star["id"], expected["id"], "the star is the weapon with the most damage")
	assert_eq(int(column.star["player"]), column.player, "their own weapon")
	assert_eq(column.star_photo.caption.text, str(expected["name"]), "shown as a photo")
	assert_eq(column.star_sticker.label.text, "Star of the run", "with its sticker")
	var damage: String = WeaponReport.short_number(float(expected["damage"]))
	assert_eq(column.star_damage_label.text, "%s damage" % damage)
	var kills: String = WeaponReport.grouped(int(expected["kills"]))
	assert_string_contains(column.star_line_label.text, "%s kills" % kills)
	assert_string_contains(column.star_line_label.text, " DPS")
	assert_string_contains(column.star_line_label.text, "held ")


func test_ac53_every_weapon_with_its_numbers_and_the_star_of_the_run() -> void:
	await _quiet_run()
	assert_true(run.dev_menu.give(&"thimble_mortar", 3), "a mortar at level 3")
	assert_true(run.dev_menu.give(&"orbiting_needles", 2), "needles at level 2")
	assert_true(run.dev_menu.give(&"quick_feet", 2), "an item")
	await _fight()
	var end: EndScreen = await _give_up()
	if end == null:
		return
	var result: RunResult = end.result
	assert_eq(end.columns.size(), 1, "one player, one column")
	var column: WeaponColumn = end.columns[0]
	assert_null(column.heading, "no 'Player 1' heading when playing alone")
	var expected: Array[Dictionary] = WeaponReport.rows_of(result, 0)
	assert_eq(expected.size(), 3, "three weapons in the run")
	assert_eq(_ids(column.listed()), _ids(expected), "every weapon, biggest damage first")
	var shown: Array[Dictionary] = column.listed()
	for i: int in range(1, shown.size()):
		assert_gte(float(shown[i - 1]["damage"]), float(shown[i]["damage"]), "biggest first")
	_assert_star(column, result)
	assert_eq(column.rows.size(), expected.size() - 1, "the others are rows")
	for row: WeaponRow in column.rows:
		var weapon: Dictionary = row.row
		var texts: PackedStringArray = row.texts()
		assert_eq(texts[0], str(weapon["name"]))
		assert_eq(texts[1], "Lv %d" % int(weapon["level"]))
		assert_eq(texts[2], WeaponReport.short_number(float(weapon["damage"])))
		assert_eq(texts[3], WeaponReport.grouped(int(weapon["kills"])))
		assert_eq(texts[4], WeaponReport.short_number(WeaponReport.dps(weapon)))
		assert_eq(texts[5], TimeFormat.clock(float(weapon["seconds_held"])))
	var mortar: Dictionary = {}
	for weapon: Dictionary in expected:
		if weapon["id"] == "thimble_mortar":
			mortar = weapon
	assert_eq(int(mortar.get("level", 0)), 3, "the level it ended at")
	assert_gt(float(mortar.get("seconds_held", 0.0)), FIGHT_SECONDS - 0.5, "held the whole fight")
	assert_eq(end.item_tag_texts(), PackedStringArray(["Quick Feet 2"]), "items are tags")
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1, "the run was logged")
	if entries.is_empty():
		return
	var logged: Array[Dictionary] = []
	logged.assign(entries[0]["weapons"])
	assert_eq(_ids(WeaponReport.rows_of(_logged_result(logged), 0)), _ids(expected))


func test_ac53_an_evolved_weapon_shows_evo() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.evolve(run.upgrade_pool.evolution_into(&"banana_split"))
	await _fight()
	var end: EndScreen = await _give_up()
	if end == null:
		return
	var column: WeaponColumn = end.columns[0]
	assert_eq(column.star.get("id"), "banana_split", "the only weapon is the star")
	assert_string_starts_with(column.star_line_label.text, "EVO · ", "EVO instead of a level")


func test_ac57_two_players_get_a_column_and_a_star_each() -> void:
	main.player_count = 2
	await _quiet_run()
	var players: Array[Player] = Players.all(run.get_tree())
	assert_eq(players.size(), 2)
	players[1].add_weapon(run.upgrade_pool.find(&"thimble_mortar").weapon)
	await _fight()
	var end: EndScreen = await _give_up()
	if end == null:
		return
	assert_eq(end.columns.size(), 2, "one column per player")
	for index: int in end.columns.size():
		var column: WeaponColumn = end.columns[index]
		assert_eq(column.player, index)
		assert_not_null(column.heading, "a heading per column")
		if column.heading != null:
			assert_eq(column.heading.label.text, "Player %d" % (index + 1))
		_assert_star(column, end.result)
		for weapon: Dictionary in column.listed():
			assert_eq(int(weapon["player"]), index, "only this player's weapons")
	assert_eq(_ids(end.columns[1].listed()).size(), 2, "player 2 had two weapons")


## A RunResult holding only `weapons` (to sort the logged rows the same way).
func _logged_result(weapons: Array[Dictionary]) -> RunResult:
	var result: RunResult = RunResult.new()
	result.weapons = weapons
	return result
