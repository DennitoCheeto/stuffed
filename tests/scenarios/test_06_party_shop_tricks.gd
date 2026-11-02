extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, §3.1, AC-69, AC-71, AC-73): the Party Shop's tricks work in a run.
## Confetti Rush: touching a floor pickup makes the hero run faster for a few seconds. Double Fun:
## some floor pickups are doubles (two toys, an extra ring) that are stronger or longer. Pocket
## Pickup: the hero carries one floor pickup (shown in a HUD pocket) and uses it with Q; touching
## another one with a full pocket uses the new one at once. In co-op every hero has a pocket.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const CONFETTI_RUSH: TrickDef = preload("res://data/town/tricks/confetti_rush.tres")
const DOUBLE_FUN: TrickDef = preload("res://data/town/tricks/double_fun.tres")
const PICKUP_RULES: FloorPickupRules = preload("res://data/floor_pickup_rules.tres")
## Double Fun's chance is checked over this many rolls.
const ROLLS: int = 2000

var run: Run


func _quiet_run(tricks: Array[String], heroes: int = 1) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	main.player_count = heroes
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.enemies.calm = true
	for hero: Player in Players.all(get_tree()):
		disarm(hero)
	return run


## Drops floor pickup `id` on `hero` and waits until someone touched it.
func _touch(id: StringName, hero: Player, double: bool = false) -> void:
	var before: int = run.floor_pickups().size()
	run.drop_floor_pickup(id, hero.global_position, double)
	for i: int in 12:
		await wait_physics_frames(1)
		if run.floor_pickups().size() <= before:
			return
	fail_test("the pickup was never touched")


func _logged(id: String) -> int:
	var count: int = 0
	for entry: Dictionary in run.floor_pickup_log:
		if entry["id"] == id:
			count += 1
	return count


## The speed `hero` walks at while holding right for a few frames.
func _walk_speed(hero: Player) -> float:
	sender.action_down("p1_move_right")
	await wait_physics_frames(3)
	var speed: float = hero.velocity.length()
	sender.action_up("p1_move_right")
	await wait_physics_frames(1)
	return speed


func test_ac69_without_confetti_rush_pickups_dont_speed_you_up() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	await _touch(&"magnet", banane)
	assert_eq(banane.speed_boost_left(), 0.0)
	assert_almost_eq(await _walk_speed(banane), banane.stats.move_speed, 0.5)
	assert_false(run.tricks.fired(&"confetti_rush"))


func test_ac69_confetti_rush_makes_you_run_faster_for_a_bit() -> void:
	await _quiet_run(["confetti_rush"])
	var banane: Player = first_player()
	assert_gt(CONFETTI_RUSH.amount, 0.0, "the speed lives in data")
	assert_gt(CONFETTI_RUSH.seconds, 0.0, "the time lives in data")
	var normal: float = await _walk_speed(banane)
	await _touch(&"magnet", banane)
	assert_true(run.tricks.fired(&"confetti_rush"))
	assert_string_contains(run.hud.trick_banner.title.text, "Confetti Rush!")
	var fast: float = await _walk_speed(banane)
	assert_almost_eq(fast, normal * (1.0 + CONFETTI_RUSH.amount), 0.5, "25% faster")
	var started: float = run.elapsed
	while run.elapsed < started + CONFETTI_RUSH.seconds:
		await wait_physics_frames(1)
	assert_almost_eq(await _walk_speed(banane), normal, 0.5, "back to normal afterwards")


func test_ac69_without_double_fun_there_are_no_doubles() -> void:
	await _quiet_run([])
	var doubles: int = 0
	for i: int in ROLLS:
		if run.tricks.rolls_double():
			doubles += 1
	assert_eq(doubles, 0, "never a double")
	var pickup: FloorPickup = run.drop_floor_pickup(&"magnet", Vector2(-5000.0, -5000.0))
	assert_false(pickup.double)
	assert_null(pickup.twin, "one toy")


func test_ac69_double_fun_makes_some_pickups_doubles() -> void:
	await _quiet_run(["double_fun"])
	assert_gt(DOUBLE_FUN.amount, 0.0, "the chance lives in data")
	var doubles: int = 0
	for i: int in ROLLS:
		if run.tricks.rolls_double():
			doubles += 1
	var share: float = float(doubles) / ROLLS
	assert_almost_eq(share, DOUBLE_FUN.amount, 0.04, "about 15% are doubles")


func test_ac69_a_double_snow_globe_freezes_longer_and_looks_double() -> void:
	await _quiet_run(["double_fun"])
	var banane: Player = first_player()
	var far: Vector2 = banane.global_position + Vector2(600.0, 0.0)
	var pickup: FloorPickup = run.drop_floor_pickup(&"snow_globe", far, true)
	assert_true(pickup.double)
	assert_not_null(pickup.twin, "two toys on the floor")
	pickup.position = banane.global_position
	for i: int in 6:
		await wait_physics_frames(1)
	assert_eq(run.hud.banner_title.text, "DOUBLE SNOW GLOBE!")
	var longer: float = PICKUP_RULES.freeze_seconds * PICKUP_RULES.double_freeze_scale
	assert_gt(longer, PICKUP_RULES.freeze_seconds)
	assert_gt(run.enemies.freeze_left, PICKUP_RULES.freeze_seconds, "frozen longer than normal")
	assert_lte(run.enemies.freeze_left, longer)
	assert_true(run.floor_pickup_log[0]["double"], "logged as a double")
	assert_true(run.tricks.fired(&"double_fun"))
	assert_string_contains(run.hud.trick_banner.title.text, "Double Fun!")


func test_ac69_a_double_magnet_keeps_pulling_new_buttons() -> void:
	await _quiet_run(["double_fun"])
	var banane: Player = first_player()
	await _touch(&"magnet", banane, true)
	await wait_seconds(1.0)
	var later: XpButton = run.pickups.drop(
		EnemyStats.XpSize.SMALL, banane.global_position + Vector2(700.0, 0.0)
	)
	await wait_physics_frames(2)
	assert_eq(later.target, banane, "a new button still flies to the hero")
	await wait_seconds(PICKUP_RULES.double_magnet_seconds)
	var too_late: XpButton = run.pickups.drop(
		EnemyStats.XpSize.SMALL, banane.global_position + Vector2(-700.0, 0.0)
	)
	await wait_physics_frames(2)
	assert_null(too_late.target, "the magnet stops after its time")


func test_ac69_a_double_party_popper_hits_elites_harder() -> void:
	await _quiet_run(["double_fun"])
	var banane: Player = first_player()
	var elite: Zombie = run.enemies.spawn(
		SHAMBLER, banane.global_position + Vector2(200.0, 0.0), run.spawner.schedule.elite_rules
	)
	elite.max_health = 1000.0
	elite.health = 1000.0
	await _touch(&"party_popper", banane, true)
	var share: float = PICKUP_RULES.popper_elite_share * PICKUP_RULES.double_popper_scale
	assert_almost_eq(elite.health, 1000.0 * (1.0 - share), 1.0, "twice the normal hit")


func test_ac69_without_pocket_pickup_there_is_no_pocket() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	assert_false(run.hud.pocket.visible, "no pocket on the HUD")
	await _touch(&"snow_globe", banane)
	assert_eq(_logged("snow_globe"), 1, "used at once")
	assert_null(banane.pocket)


func test_ac69_pocket_pickup_keeps_one_pickup_for_q() -> void:
	await _quiet_run(["pocket_pickup"])
	var banane: Player = first_player()
	assert_true(run.hud.pocket.visible, "an empty pocket next to the health bar")
	assert_false(run.hud.pocket.is_full())
	Sfx.history.clear()
	await _touch(&"snow_globe", banane)
	assert_eq(_logged("snow_globe"), 0, "not used yet")
	assert_false(run.enemies.is_frozen())
	assert_eq(banane.pocket.id, &"snow_globe", "it went into the pocket")
	assert_true(run.hud.pocket.is_full(), "the pocket shows it")
	assert_eq(run.hud.pocket.key_label.text, "Q")
	assert_eq(run.hud.banner_title.text, RunTricks.POCKET_TITLE)
	assert_string_contains(run.hud.banner_subtitle.text, "Q")
	assert_true(Sfx.history.has(RunTricks.POCKET_SOUND), "a soft pocket sound")
	assert_true(run.tricks.fired(&"pocket_pickup"))
	await _touch(&"magnet", banane)
	assert_eq(_logged("magnet"), 1, "with a full pocket the new one works at once")
	assert_eq(banane.pocket.id, &"snow_globe", "the pocket keeps the first one")
	await tap_action("p1_use_pocket")
	await wait_physics_frames(1)
	assert_eq(_logged("snow_globe"), 1, "Q uses it")
	assert_true(run.enemies.is_frozen(), "the horde freezes")
	assert_null(banane.pocket, "the pocket is empty again")
	assert_true(run.hud.pocket.visible, "the empty pocket stays")
	assert_false(run.hud.pocket.is_full())
	assert_false(UiColors.is_danger(PocketPatch.FILL), "never danger red (AC-73)")


func test_ac69_a_pocketed_double_stays_a_double() -> void:
	await _quiet_run(["pocket_pickup", "double_fun"])
	var banane: Player = first_player()
	await _touch(&"snow_globe", banane, true)
	assert_true(banane.pocket_double)
	assert_true(run.hud.pocket.double_label.visible, "x2 on the pocket")
	await tap_action("p1_use_pocket")
	await wait_physics_frames(1)
	assert_eq(run.hud.banner_title.text, "DOUBLE SNOW GLOBE!")
	assert_gt(run.enemies.freeze_left, PICKUP_RULES.freeze_seconds)


func test_ac71_every_hero_has_their_own_pocket() -> void:
	add_controls(1)
	await _quiet_run(["pocket_pickup"], 2)
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2)
	heroes[1].global_position = heroes[0].global_position + Vector2(400.0, 0.0)
	await wait_physics_frames(1)
	await _touch(&"snow_globe", heroes[1])
	assert_not_null(heroes[1].pocket, "player 2 carries it")
	assert_null(heroes[0].pocket, "player 1's pocket stays empty")
	assert_false(run.hud.pocket.is_full(), "the HUD shows player 1's pocket")
	await tap_action("p1_use_pocket")
	assert_eq(_logged("snow_globe"), 0, "player 1's key doesn't use player 2's pocket")
	await tap_action("p2_use_pocket")
	await wait_physics_frames(1)
	assert_eq(_logged("snow_globe"), 1, "player 2's key does")
	assert_eq(run.floor_pickup_log[0]["player"], 1, "for player 2")
	assert_null(heroes[1].pocket)
