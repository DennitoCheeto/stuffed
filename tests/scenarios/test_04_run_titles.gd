extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §4.2, AC-54): after a real run the end screen sticks on the run titles it
## earned (rarest first, at most 2) as stickers that slap on with the sticker sound; a title never
## earned before gets a "New!" sticker, the next time it doesn't (remembered in the save). The
## run log lists the titles. A hit restarts the "no damage" stopwatch.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Seconds the starting weapon gets to work on the zombies.
const FIGHT_SECONDS: float = 3.0
## Long enough for every sticker to slap on (Star delay + a gap per sticker + the slap).
const SLAP_WAIT: float = 2.5

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	for player: Player in Players.all(run.get_tree()):
		player.invincible = true
	return run


## A ring of shamblers for the starting weapon (the only weapon: all of the damage).
func _fight() -> void:
	var hero: Player = first_player()
	for i: int in 12:
		var at: Vector2 = Vector2.from_angle(TAU * i / 12.0) * (140.0 + 40.0 * (i % 3))
		run.enemies.spawn(SHAMBLER, hero.global_position + at)
	await wait_seconds(FIGHT_SECONDS)


## Opens `count` gift boxes at the hero's feet, closing each moment.
func _open_gift_boxes(count: int) -> void:
	for i: int in count:
		run.pickups.buttons.clear()
		run.drop_gift_box(first_player().position)
		await _wait_for_gift_moment()
		run.gift_screen.close()
		await wait_physics_frames(2)
	assert_eq(run.gift_boxes_opened, count, "the run counted the boxes")


func _wait_for_gift_moment() -> void:
	var left: int = 120
	while not run.gift_screen.is_open() and left > 0:
		left -= 1
		await wait_physics_frames(1)
	assert_true(run.gift_screen.is_open(), "the gift box opened")


func _give_up() -> EndScreen:
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(3)
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end, "the end screen is shown")
	return end


func _texts(stickers: Array[Sticker]) -> PackedStringArray:
	var texts: PackedStringArray = []
	for sticker: Sticker in stickers:
		texts.append(sticker.label.text)
	return texts


func test_ac54_earned_titles_slap_on_and_new_only_the_first_time() -> void:
	await _quiet_run()
	await _fight()
	await _open_gift_boxes(3)
	Sfx.history.clear()
	var end: EndScreen = await _give_up()
	if end == null:
		return
	var weapon: String = str(WeaponReport.star_of(end.result, 0).get("id", ""))
	var expected: PackedStringArray = ["weapon_star:" + weapon, "gift_grabber"]
	assert_eq(end.result.titles, expected, "weapon title, then Gift Grabber (list order)")
	var words: String = end.result.weapon_titles.get(weapon, "")
	assert_ne(words, "", "the weapon has its own title")
	assert_eq(_texts(end.title_stickers), PackedStringArray([words, "Gift Grabber"]))
	assert_eq(end.new_stickers.size(), 2, "both are new")
	assert_eq(_texts(end.new_stickers), PackedStringArray(["New!", "New!"]))
	for sticker: Sticker in end.slap_order:
		assert_eq(sticker.get_parent(), end.sticker_row, "on the page next to the title")
		assert_almost_eq(sticker.fade, 0.0, 0.01, "hidden until it slaps on")
	await wait_seconds(SLAP_WAIT)
	for sticker: Sticker in end.slap_order:
		assert_almost_eq(sticker.fade, 1.0, 0.01, "slapped on")
		assert_false(sticker.is_slapping(), "and settled")
	assert_eq(Sfx.history.count(&"sticker"), end.slap_order.size() + 1, "a thwap each (+ the Star)")
	assert_true(main.town.titles_seen.has("gift_grabber"), "remembered")
	assert_true(SaveStore.read().titles_seen.has("gift_grabber"), "and saved")
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	if not entries.is_empty():
		assert_eq(PackedStringArray(entries[0]["titles"]), expected, "the run log lists them")

	# The same titles again (back to the fort, into the Bedroom): no "New!" this time.
	await _quiet_run()
	await _fight()
	await _open_gift_boxes(3)
	end = await _give_up()
	if end == null:
		return
	assert_eq(end.result.titles, expected)
	assert_eq(end.new_stickers.size(), 0, "seen before: no New!")


func test_ac54_a_run_with_nothing_special_gets_the_fallback() -> void:
	await _quiet_run()
	var end: EndScreen = await _give_up()
	if end == null:
		return
	assert_eq(end.result.titles, PackedStringArray(["steady_paws"]))
	assert_string_starts_with(end.title_stickers[0].label.text, "Steady Paws")


func test_ac54_a_hit_restarts_the_no_damage_stopwatch() -> void:
	await _quiet_run()
	var hero: Player = first_player()
	hero.invincible = false
	run.elapsed = 200.0
	assert_true(hero.take_hit(1.0, "test"), "the hero got hit")
	assert_almost_eq(run.unhurt.longest, 200.0, 0.5, "200 s without damage before the hit")
	run.elapsed = 250.0
	var result: RunResult = run.make_result("quit")
	assert_almost_eq(result.longest_unhurt_seconds, 200.0, 0.5, "the new stretch is shorter")
	assert_true(RunTitleRules.fits(_untouchable(), result), "3+ minutes: Untouchable!")


func _untouchable() -> RunTitleDef:
	for def: RunTitleDef in Main.RUN_TITLES.titles:
		if def.id == &"untouchable":
			return def
	return null
