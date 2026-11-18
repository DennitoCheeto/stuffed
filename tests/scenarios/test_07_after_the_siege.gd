extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §6, AC-80): a won siege brings the reward home and damages nothing (knocked-
## down buildings pop back up); a lost one damages every building knocked down in the fight and
## still brings a consolation haul. The end screen tells how the night went. A damaged building
## leans with felt patches, its bonuses and tricks are off in runs, and E repairs it for 25% of
## its level's coins (saved at once).

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const SNACK_BAR: String = "snack_bar"

var siege: Siege


## A town with three buildings (Snack Bar at level 2) and the horde due tonight.
func _make_siege_due() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1, SNACK_BAR: 2}
	main.town.siege_nights = 0


func _start_siege() -> Siege:
	_make_siege_due()
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	if started != null:
		silence_turrets(started)
	return started


## Knocks the Snack Bar down in the fight.
func _knock_down_snack_bar() -> void:
	var building: SiegeBuilding = siege.targets.building(StringName(SNACK_BAR))
	building.hurt(building.max_health * 10.0)
	await wait_physics_frames(1)


func _wait_for_end_screen(seconds: float) -> EndScreen:
	for i: int in roundi(seconds * FPS):
		if main.current_screen is EndScreen:
			break
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	return main.current_screen as EndScreen


## Puts the player next to `building` in town.
func _walk_up_to(building: TownBuilding) -> void:
	var rect: Rect2 = building.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 30.0)
	await wait_physics_frames(3)


func test_ac80_a_won_siege_brings_the_reward_home_and_damages_nothing() -> void:
	siege = await _start_siege()
	main.town.materials = {"coins": 10}
	await _knock_down_snack_bar()
	var look: TownBuilding = siege.town_arena().buildings[StringName(SNACK_BAR)]
	assert_true(look.knocked_down, "knocked down in the fight")
	siege.dev_menu.press(DevMenu.WIN_SIEGE)
	assert_false(look.knocked_down, "pops back up when the night is defended")
	var end: EndScreen = await _wait_for_end_screen(RULES.end_pause_seconds + 2.0)
	assert_not_null(end, "the end screen tells how the night went")
	if end == null:
		return
	assert_eq(end.title_label.text, "Night defended!")
	assert_string_contains(end.stats_label.text, "Waves held: 3 of 3")
	assert_eq(end.brought_home.note_label.text, RULES.won_note)
	assert_false(end.brought_home.damage_label.visible)
	assert_false(end.try_again_button.visible, "the way on is home to the fort")
	assert_eq(end.columns.size(), 1, "best weapon: the weapons and the Star of the run")
	assert_eq(end.brought_home.amount("coins"), 400)
	assert_eq(main.town.material("coins"), 410, "the reward is in the jars")
	assert_eq(main.town.material("stuffing"), 20)
	assert_eq(main.town.material("thread"), 4)
	assert_eq(main.town.damaged.size(), 0, "a won siege damages nothing")
	assert_eq(SaveStore.read().material("coins"), 410, "saved at once")


func test_ac80_every_siege_gives_a_bigger_reward() -> void:
	main.town.sieges_played = 1
	siege = await _start_siege()
	assert_eq(siege.number, 2)
	siege.dev_menu.press(DevMenu.WIN_SIEGE)
	var end: EndScreen = await _wait_for_end_screen(RULES.end_pause_seconds + 2.0)
	assert_not_null(end)
	assert_eq(main.town.material("coins"), 500, "+25% for the second siege")
	assert_eq(main.town.material("stuffing"), 25)


func test_ac80_a_lost_siege_damages_what_was_knocked_down() -> void:
	siege = await _start_siege()
	await _knock_down_snack_bar()
	for i: int in 6:
		siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_true(siege.fort.is_fallen())
	var end: EndScreen = await _wait_for_end_screen(RULES.end_pause_seconds + 2.0)
	assert_not_null(end)
	if end == null:
		return
	assert_eq(end.title_label.text, "The horde got in")
	assert_eq(end.brought_home.note_label.text, RULES.lost_note)
	assert_true(end.brought_home.damage_label.visible)
	assert_string_contains(end.brought_home.damage_label.text, "Snack Bar")
	assert_eq(main.town.damaged, PackedStringArray([SNACK_BAR]), "only what was knocked down")
	assert_false(main.town.is_damaged("lucky_jar"))
	assert_false(main.town.is_damaged("fort"), "the fort is never damaged")
	assert_eq(main.town.building_level(SNACK_BAR), 2, "it keeps its level")
	assert_eq(main.town.material("coins"), 120, "consolation haul = 30% of the reward")
	assert_eq(main.town.material("stuffing"), 6)
	assert_eq(SaveStore.read().damaged, PackedStringArray([SNACK_BAR]), "saved at once")
	end.fort_requested.emit()
	await wait_physics_frames(2)
	var town: Town = main.current_screen as Town
	assert_not_null(town)
	if town != null:
		assert_true(town.buildings[StringName(SNACK_BAR)].damaged, "looks damaged in town")
		assert_eq(town.banner_title.text, "The horde got in")


func test_ac80_giving_up_counts_as_lost() -> void:
	siege = await _start_siege()
	await _knock_down_snack_bar()
	siege.pause()
	siege.pause_menu.quit_button.pressed.emit()
	var end: EndScreen = await _wait_for_end_screen(2.0)
	assert_not_null(end)
	assert_true(main.town.is_damaged(SNACK_BAR))
	assert_eq(main.town.sieges_won, 0)


func test_ac80_a_damaged_buildings_bonuses_and_tricks_are_off_until_repaired() -> void:
	main.town.building_levels = {SNACK_BAR: 2, "lucky_jar": 1}
	main.town.tricks = PackedStringArray(["second_helping", "shiny_card"])
	main.town.damaged = PackedStringArray([SNACK_BAR])
	var run: Run = await start_run()
	assert_eq(run.perks.max_health_bonus, 0.0, "the Snack Bar's bonus is off")
	assert_false(run.perks.has_trick(&"second_helping"), "its trick is off")
	assert_true(run.perks.has_trick(&"shiny_card"), "other buildings' tricks still work")
	assert_true(run.perks.extra_card_uses > 0, "other buildings' bonuses still work")
	main.town.repair(SNACK_BAR)
	var repaired: TownPerks = TownPerks.from_save(main.town, Main.TOWN_LAYOUT)
	assert_eq(repaired.max_health_bonus, 20.0, "back on after the repair")
	assert_true(repaired.has_trick(&"second_helping"))


func test_ac80_repair_costs_a_quarter_of_the_levels_coins() -> void:
	main.town.building_levels = {SNACK_BAR: 2, "lucky_jar": 1}
	main.town.damaged = PackedStringArray([SNACK_BAR])
	main.town.materials = {"coins": 150}
	var town: Town = await go_to_town()
	var building: TownBuilding = town.buildings[StringName(SNACK_BAR)]
	assert_true(building.damaged)
	assert_eq(building.repair_cost(), {"coins": 200}, "25% of level 2's 800 coins")
	assert_true(building.price_tag.visible, "the repair price hangs under it")
	await _walk_up_to(building)
	assert_eq(town.card.now_label.text, RULES.damaged_card)
	assert_string_contains(town.card.level_label.text, "Damaged")
	assert_eq(town.prompt_label.text, "Needs 50 more coins")
	tap_action("p1_interact")
	await wait_physics_frames(2)
	assert_true(main.town.is_damaged(SNACK_BAR), "not enough coins: still damaged")
	assert_eq(main.town.material("coins"), 150)
	main.town.materials = {"coins": 250}
	town.refresh()
	await wait_physics_frames(2)
	assert_eq(town.prompt_label.text, "E   Repair")
	tap_action("p1_interact")
	await wait_physics_frames(2)
	assert_false(main.town.is_damaged(SNACK_BAR), "repaired")
	assert_false(building.damaged, "stands straight again")
	assert_true(building.is_busy(), "the stitch-up moment")
	assert_eq(main.town.material("coins"), 50)
	assert_eq(main.town.building_level(SNACK_BAR), 2, "same level")
	var saved: TownSave = SaveStore.read()
	assert_false(saved.is_damaged(SNACK_BAR), "saved at once")
	assert_eq(saved.material("coins"), 50)


func test_ac80_a_damaged_building_cannot_be_upgraded_before_its_repair() -> void:
	main.town.building_levels = {SNACK_BAR: 1, "lucky_jar": 1}
	main.town.damaged = PackedStringArray([SNACK_BAR])
	main.town.materials = {"coins": 9999, "stuffing": 999, "thread": 999}
	var town: Town = await go_to_town()
	var building: TownBuilding = town.buildings[StringName(SNACK_BAR)]
	assert_false(town.try_build(building))
	assert_eq(main.town.building_level(SNACK_BAR), 1)
	assert_false(building.shows_can_build(), "no 'Can build!' while damaged")
	town.interact(building)
	assert_false(main.town.is_damaged(SNACK_BAR), "E repairs first")
	assert_eq(main.town.building_level(SNACK_BAR), 1)
