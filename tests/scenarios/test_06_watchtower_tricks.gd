extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, AC-69): the Watchtower's tricks work in a run. Spyglass: edge arrows
## also point to elites and bosses off screen. Magnet Whistle: on level-up every XP button on
## screen flies to the hero. Treasure Map: a big gift box hides away from the start screen, clear
## of furniture, and an edge arrow shows the way.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const TREASURE_MAP: TrickDef = preload("res://data/town/tricks/treasure_map.tres")
## Far enough right of the hero to be off screen (the test window is 1920 wide).
const OFF_SCREEN: Vector2 = Vector2(2600.0, 0.0)

var run: Run


func _quiet_run(tricks: Array[String]) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.enemies.calm = true
	return run


func _spawn_elite(at: Vector2) -> Zombie:
	return run.enemies.spawn(SHAMBLER, at, run.spawner.schedule.elite_rules)


func _arrows_of(color: Color) -> int:
	var count: int = 0
	for arrow_color: Color in run.pickup_arrows.colors:
		if arrow_color == color:
			count += 1
	return count


func test_ac69_without_spyglass_no_arrow_to_elites() -> void:
	await _quiet_run([])
	_spawn_elite(first_player().global_position + OFF_SCREEN)
	await wait_process_frames(3)
	assert_eq(_arrows_of(PickupArrows.THREAT_COLOR), 0)
	assert_false(run.tricks.fired(&"spyglass"))


func test_ac69_spyglass_points_to_off_screen_elites_and_bosses() -> void:
	await _quiet_run(["spyglass"])
	var banane: Player = first_player()
	_spawn_elite(banane.global_position + Vector2(200.0, 0.0))
	await wait_process_frames(3)
	assert_eq(_arrows_of(PickupArrows.THREAT_COLOR), 0, "an elite on screen needs no arrow")
	assert_false(run.tricks.fired(&"spyglass"))
	run.enemies.spawn(SHAMBLER, banane.global_position - OFF_SCREEN)
	_spawn_elite(banane.global_position + OFF_SCREEN)
	await wait_process_frames(3)
	assert_eq(_arrows_of(PickupArrows.THREAT_COLOR), 1, "only the elite off screen, no shambler")
	var index: int = Array(run.pickup_arrows.colors).find(PickupArrows.THREAT_COLOR)
	assert_gt(run.pickup_arrows.directions[index].x, 0.9, "it points right, towards the elite")
	assert_eq(run.pickup_arrows.sizes[index], 1.0)
	assert_true(run.tricks.fired(&"spyglass"), "noted for the banner and log")
	assert_eq(run.hud.trick_banner.title.text, "Spyglass!")
	run.enemies.spawn_boss(run.spawner.schedule.boss, banane.global_position - OFF_SCREEN)
	await wait_process_frames(3)
	assert_eq(_arrows_of(PickupArrows.THREAT_COLOR), 2, "the boss gets one too")
	assert_has(Array(run.pickup_arrows.sizes), PickupArrows.BOSS_SCALE, "a bigger one")
	assert_false(UiColors.is_danger(PickupArrows.THREAT_COLOR), "never danger red (AC-73)")


func _whistle_setup() -> Array[XpButton]:
	var banane: Player = first_player()
	var near: XpButton = run.pickups.drop(
		EnemyStats.XpSize.SMALL, banane.global_position + Vector2(0.0, 500.0)
	)
	var far: XpButton = run.pickups.drop(
		EnemyStats.XpSize.SMALL, banane.global_position + OFF_SCREEN
	)
	await wait_physics_frames(2)
	assert_null(near.target, "out of pickup range: it lies still")
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	return [near, far]


func test_ac69_without_magnet_whistle_buttons_stay() -> void:
	await _quiet_run([])
	var buttons: Array[XpButton] = await _whistle_setup()
	assert_null(buttons[0].target)
	assert_false(run.tricks.fired(&"magnet_whistle"))


func test_ac69_magnet_whistle_pulls_on_screen_buttons_on_level_up() -> void:
	await _quiet_run(["magnet_whistle"])
	var banane: Player = first_player()
	Sfx.history.clear()
	var buttons: Array[XpButton] = await _whistle_setup()
	assert_eq(buttons[0].target, banane, "the button on screen flies to the hero")
	assert_null(buttons[1].target, "the one off screen stays")
	assert_true(run.tricks.fired(&"magnet_whistle"), "noted for the banner and log")
	assert_has(Sfx.history, RunTricks.WHISTLE_SOUND, "a soft whistle")
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	run.level_up_screen.picked.emit(run.level_up_screen.offers[0])
	await wait_seconds(1.5)
	assert_eq(run.pickups.buttons.size(), 1, "the near one was collected")


func test_ac69_without_treasure_map_no_hidden_box() -> void:
	await _quiet_run([])
	assert_null(run.tricks.treasure)
	assert_eq(_arrows_of(GiftBoxLook.GLOW_COLOR), 0)


func test_ac69_treasure_map_hides_a_big_box_with_an_arrow() -> void:
	await _quiet_run(["treasure_map"])
	var banane: Player = first_player()
	var box: GiftBox = run.tricks.treasure
	assert_not_null(box)
	assert_true(box.big, "a big gift box")
	assert_true(box.treasure)
	var start_screen: Rect2 = run.tricks.start_rect(run.arena.center())
	assert_false(start_screen.grow(TREASURE_MAP.amount).has_point(box.position), "far away")
	assert_true(run.arena.play_rect().has_point(box.position), "inside the room")
	var radius: float = run.gift_box_rules.treasure_stand_radius
	assert_false(run.enemies.obstacles.blocks(box.position, radius), "not in furniture")
	assert_true(run.tricks.fired(&"treasure_map"), "the banner names it at the start")
	await wait_process_frames(3)
	assert_eq(_arrows_of(GiftBoxLook.GLOW_COLOR), 1, "an arrow shows the way")
	var index: int = Array(run.pickup_arrows.colors).find(GiftBoxLook.GLOW_COLOR)
	var toward: Vector2 = banane.global_position.direction_to(box.position)
	assert_gt(run.pickup_arrows.directions[index].dot(toward), 0.95, "towards the box")
	banane.global_position = box.position
	await wait_physics_frames(3)
	assert_eq(run.gift_boxes_opened, 1, "it opens like any gift box")


func test_ac69_treasure_spots_are_always_free_and_far() -> void:
	await _quiet_run(["treasure_map"])
	var start_screen: Rect2 = run.tricks.start_rect(run.arena.center())
	var far: Rect2 = start_screen.grow(TREASURE_MAP.amount)
	var radius: float = run.gift_box_rules.treasure_stand_radius
	var inside: Rect2 = run.arena.play_rect().grow(-run.gift_box_rules.treasure_wall_margin)
	for attempt: int in 200:
		var spot: Vector2 = run.tricks.treasure_spot(TREASURE_MAP.amount)
		assert_false(far.has_point(spot), "away from the start screen: %s" % spot)
		assert_false(run.enemies.obstacles.blocks(spot, radius), "not in furniture: %s" % spot)
		assert_true(inside.has_point(spot), "inside the wall margin: %s" % spot)
