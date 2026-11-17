extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §2, §5, §8, §10, AC-75, AC-76, AC-81): when the horde is due the town turns
## to dusk and the door only offers "Defend the fort"; the siege plays in the town with the run's
## controls (waves from the room edges, XP and cards, Big Ted in the last wave, zombies going for
## the fort, fallen heroes standing back up); it is lost only when the fort falls, and a siege
## cut short by closing the game is still due.

const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const RUN_XP: XpRules = preload("res://data/xp_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var siege: Siege


## A town with two buildings and the horde due tonight.
func _make_siege_due() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0


## Goes to the town and presses E at the door, the way the player does; returns the siege.
func _start_siege() -> Siege:
	_make_siege_due()
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	if started != null:
		silence_turrets(started)
	return started


## Waits up to `seconds` for the town banner to say `title`.
func _wait_for_banner(town: Town, title: String, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if town.is_banner_showing() and town.banner_title.text == title:
			return true
		await wait_physics_frames(1)
	return false


func _wait_for_town(seconds: float) -> Town:
	for i: int in roundi(seconds * FPS):
		if main.current_screen is Town:
			break
		await wait_physics_frames(1)
	await wait_physics_frames(1)
	return main.current_screen as Town


func test_ac75_the_town_turns_to_dusk_and_the_door_offers_the_siege() -> void:
	_make_siege_due()
	var town: Town = await go_to_town()
	await wait_physics_frames(2)
	assert_not_null(town.dusk, "dusk while the horde is due")
	if town.dusk == null:
		return
	assert_eq(town.dusk.tint.color, PALETTE.dusk_tint, "a warm evening tint")
	assert_gt(PALETTE.dusk_tint.v, 0.75, "not dark")
	assert_eq(town.dusk.lit.size(), 3, "fairy lights on the fort and both buildings")
	assert_true(await _wait_for_banner(town, "The horde is coming!", 3.0), "with a banner")
	assert_eq(town.prompt_label.text, "E   Defend the fort", "the hero stands at the door")
	town.enter_bedroom()
	await wait_physics_frames(2)
	assert_true(main.current_screen is Siege, "E starts the siege, not an expedition")


func test_the_horde_banner_waits_for_other_news() -> void:
	# Four buildings: the Party Shop is revealed on arrival ("New building!").
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1, "watchtower": 1}
	main.town.building_levels["snack_bar"] = 1
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	assert_true(await _wait_for_banner(town, "New building!", 3.0), "the reveal first")
	assert_true(await _wait_for_banner(town, "The horde is coming!", 6.0), "then the horde")


func test_ac75_no_expedition_while_the_horde_is_due() -> void:
	_make_siege_due()
	main.start_run()
	await wait_physics_frames(2)
	assert_true(main.current_screen is Town, "Try again goes home instead")
	assert_false(main.current_screen is Run)


func test_no_dusk_before_the_horde_is_due() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 1
	var town: Town = await go_to_town()
	await wait_physics_frames(2)
	assert_null(town.dusk)
	assert_eq(town.prompt_label.text, "E   Go to the Bedroom")


func test_ac76_the_siege_plays_in_the_town_with_the_run_controls() -> void:
	var spawned_at: Array[Vector2] = []
	siege = await _start_siege()
	assert_not_null(siege)
	if siege == null:
		return
	siege.enemies.zombie_added.connect(func(z: Zombie) -> void: spawned_at.append(z.position))
	var hero: Player = first_player()
	assert_true(hero.armed, "the hero fights")
	assert_eq(hero.weapons().size(), 1, "with the starting weapon")
	assert_eq(siege.wave_banners, [0] as Array[int])
	assert_eq(siege.hud.banner_title.text, "Wave 1 of 3")
	assert_eq(siege.town_arena().buildings.size(), siege.layout.spots.size(), "the town room")
	assert_eq(siege.town_arena().buildings[&"lucky_jar"].level, 1)
	assert_not_null(siege.town_arena().dusk, "at dusk")
	hero.invincible = true
	disarm(hero)
	# Enough zombies that a random seed can't put them all on one side by chance.
	for i: int in roundi(10.0 * FPS):
		if spawned_at.size() >= 8:
			break
		await wait_physics_frames(1)
	assert_gte(spawned_at.size(), 8, "wave 1 brings zombies")
	var room: Rect2 = siege.layout.play_rect()
	for at: Vector2 in spawned_at:
		assert_false(room.has_point(at), "they come from outside the room's edges")
	var sides: Dictionary[int, bool] = {}
	for at: Vector2 in spawned_at:
		sides[_side(room, at)] = true
	assert_gt(sides.size(), 1, "from more than one side")


func test_ac76_xp_and_level_ups_come_faster_than_in_a_run() -> void:
	siege = await _start_siege()
	var small: EnemyStats.XpSize = EnemyStats.XpSize.SMALL
	assert_gt(siege.pickups.rules.button_value(small), RUN_XP.button_value(small))
	var hero: Player = first_player()
	var zombie: Zombie = siege.enemies.spawn(SHAMBLER, hero.global_position + Vector2(400, 0))
	siege.enemies.damage(zombie, zombie.max_health * 10.0)
	assert_eq(siege.pickups.buttons.size(), 1, "a popped zombie drops an XP button")
	hero.add_xp(hero.progress.xp_needed())
	await wait_physics_frames(2)
	assert_true(siege.level_up_screen.is_open(), "level-up cards as in a run")


func test_ac76_zombies_go_for_the_fort_and_knock_at_it() -> void:
	siege = await _start_siege()
	var hero: Player = first_player()
	hero.invincible = true
	disarm(hero)
	siege.waves.finished = true
	siege.enemies.kill_all()
	var far: Zombie = siege.enemies.spawn(SHAMBLER, Vector2(150, 750))
	var fort: Rect2 = siege.layout.fort_rect
	var before: float = TownLayout.distance_to(fort, far.position)
	await wait_seconds(1.0)
	assert_lt(TownLayout.distance_to(fort, far.position), before - 20.0, "it walks to the fort")
	var at_wall: Vector2 = Vector2(fort.position.x - SHAMBLER.radius - 2.0, fort.get_center().y)
	siege.enemies.spawn(SHAMBLER, at_wall)
	await wait_seconds(1.0)
	assert_lt(siege.fort.health, siege.fort.max_health, "it knocks at the fort")


func test_ac76_the_last_wave_brings_big_ted() -> void:
	siege = await _start_siege()
	first_player().invincible = true
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	assert_eq(siege.hud.banner_title.text, "Wave 2 of 3")
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	assert_eq(siege.hud.banner_title.text, "Wave 3 of 3")
	siege.waves.wave_time = RULES.wave_list[2].boss_at
	await wait_physics_frames(2)
	var bosses: Array[Zombie] = siege.enemies.bosses()
	assert_eq(bosses.size(), 1)
	if bosses.size() == 1:
		assert_eq(bosses[0].display_name, "Big Ted")
	assert_true(siege.hud.boss_bar.visible)


func test_ac76_a_fallen_hero_stands_back_up_at_the_fort() -> void:
	siege = await _start_siege()
	var hero: Player = first_player()
	hero.global_position = Vector2(300, 300)
	hero.take_hit(hero.max_health * 10.0, "test")
	assert_true(hero.is_dead())
	await wait_seconds(1.0)
	assert_false(siege.over, "the siege goes on while the hero is down")
	assert_true(hero.is_dead())
	await wait_seconds(RULES.stand_up_seconds)
	assert_false(hero.is_dead(), "back up")
	assert_almost_eq(hero.health, hero.max_health, 0.01)
	assert_lt(hero.global_position.distance_to(siege.layout.spawn_position), 40.0, "at the door")
	assert_false(siege.over)


func test_ac76_the_siege_is_lost_only_when_the_fort_falls() -> void:
	siege = await _start_siege()
	var hero: Player = first_player()
	hero.take_hit(hero.max_health * 10.0, "test")
	await wait_physics_frames(5)
	assert_false(siege.over, "a fallen hero doesn't lose the siege")
	for i: int in 4:
		siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_true(siege.fort.is_fallen())
	assert_true(siege.over, "the fort fell")
	assert_eq(siege.hud.banner_title.text, "The horde got in")
	var town: Town = await _wait_for_town(RULES.end_pause_seconds + 2.0)
	assert_not_null(town, "home to the town")
	if town == null:
		return
	assert_eq(town.banner_title.text, "The horde got in")
	assert_null(town.dusk, "the night is over")
	assert_eq(main.town.sieges_played, 1)
	assert_eq(main.town.sieges_won, 0)
	assert_eq(main.town.siege_nights, RULES.nights_between, "the countdown starts again")
	assert_eq(SaveStore.read().siege_nights, RULES.nights_between, "saved")


func test_ac76_winning_the_night() -> void:
	siege = await _start_siege()
	siege.dev_menu.press(DevMenu.WIN_SIEGE)
	assert_true(siege.won)
	assert_eq(siege.hud.banner_title.text, "Night defended!")
	var town: Town = await _wait_for_town(RULES.end_pause_seconds + 2.0)
	assert_not_null(town)
	assert_eq(main.town.sieges_won, 1)
	assert_eq(main.town.siege_nights, RULES.nights_between)
	assert_eq(SaveStore.read().sieges_won, 1, "saved")
	if town != null:
		assert_eq(town.banner_title.text, "Night defended!")
		assert_eq(town.prompt_label.text, "E   Go to the Bedroom", "expeditions again")


func test_ac76_the_last_wave_popped_wins_the_night() -> void:
	siege = await _start_siege()
	first_player().invincible = true
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	assert_true(siege.waves.finished)
	siege.enemies.kill_all()
	await wait_physics_frames(3)
	assert_true(siege.won, "nothing left of the horde")


func test_ac81_a_siege_cut_short_by_closing_the_game_is_still_due() -> void:
	siege = await _start_siege()
	assert_eq(SaveStore.read().siege_nights, 0, "saved on start")
	await wait_seconds(1.0)
	main.save_now()
	assert_eq(SaveStore.read().unfinished_run.size(), 0, "a siege is not an unfinished run")
	main.load_town()
	assert_eq(main.town.siege_nights, 0, "still due")
	assert_eq(main.town.sieges_played, 0)
	main.show_town()
	await wait_physics_frames(2)
	var town: Town = main.current_screen as Town
	assert_eq(town.prompt_label.text, "E   Defend the fort")


func test_the_siege_dev_menu_has_its_buttons() -> void:
	siege = await _start_siege()
	for label: String in [DevMenu.NEXT_WAVE, DevMenu.WIN_SIEGE, DevMenu.HURT_FORT]:
		assert_true(siege.dev_menu.buttons.has(label), label)
	var full: float = siege.fort.health
	siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_almost_eq(siege.fort.health, full - siege.fort.max_health * 0.25, 0.01)
	assert_almost_eq(siege.fort_bar.value, siege.fort.health, 0.01, "the fort bar shows it")
	assert_false(UiColors.is_danger(siege.fort_bar.fill_color()), "the player's side, not danger")
	siege.dev_menu.press(DevMenu.HURT_FORT)
	siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_eq(siege.fort_bar.fill_color(), FortHealthBar.LOW_COLOR, "a warning when nearly down")
	assert_false(UiColors.is_danger(FortHealthBar.LOW_COLOR))


## 0 = above the room, 1 = right, 2 = below, 3 = left.
func _side(room: Rect2, at: Vector2) -> int:
	if at.y < room.position.y:
		return 0
	if at.x > room.end.x:
		return 1
	if at.y > room.end.y:
		return 2
	return 3
