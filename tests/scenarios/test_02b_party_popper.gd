extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02b §3, §5, AC-35): grabbing a Party Popper blasts confetti over the whole
## screen: every normal zombie on screen pops and drops its XP, zombies off screen are untouched,
## elites and bosses only lose the share of their health set in data. Soft colours, never the
## red/orange of enemy danger.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const BIG_TED: BigTedDef = preload("res://data/bosses/big_ted.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	first_player().invincible = true
	return run


func _grabbed() -> bool:
	return not run.floor_pickup_log.is_empty()


## Drops a Party Popper on player 1 and waits until it is grabbed (the confetti flies).
func _grab_popper() -> void:
	run.drop_floor_pickup(&"party_popper", first_player().global_position)
	for i: int in 12:
		if _grabbed():
			break
		await wait_physics_frames(1)
	assert_true(_grabbed(), "the popper is grabbed at once")


func _confetti() -> ConfettiBlast:
	for child: Node in run.effects.get_children():
		if child is ConfettiBlast:
			return child
	return null


func test_ac35_zombies_on_screen_pop_and_drop_xp_but_off_screen_ones_stay() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var view: Rect2 = run.spawner.visible_rect()
	var on_screen: Array[Zombie] = []
	for i: int in 6:
		var spot: Vector2 = banane.global_position + Vector2.from_angle(i * TAU / 6.0) * 220.0
		on_screen.append(run.enemies.spawn(SHAMBLER, spot))
	var corner: Zombie = run.enemies.spawn(SHAMBLER, view.position + Vector2(30, 30))
	var far_spot: Vector2 = Vector2(view.end.x + 200.0, banane.global_position.y)
	var far_away: Zombie = run.enemies.spawn(SHAMBLER, far_spot)
	assert_false(view.has_point(far_away.position), "one zombie is off screen")
	run.pickups.buttons.clear()
	Sfx.history.clear()
	await _grab_popper()
	assert_eq(run.hud.banner_title.text, "PARTY POPPER!", "its banner shows")
	assert_true(Sfx.history.has(&"party_popper"), "with its own sound")
	assert_eq(run.floor_pickup_log[0]["name"], "Party Popper", "it is logged")
	for zombie: Zombie in on_screen:
		assert_false(is_instance_valid(zombie) and not zombie.dead, "a zombie on screen pops")
	assert_false(is_instance_valid(corner) and not corner.dead, "even in the screen's corner")
	assert_eq(run.pickups.buttons.size(), 7, "every popped zombie drops its XP")
	assert_true(is_instance_valid(far_away) and not far_away.dead, "the far zombie is untouched")
	if is_instance_valid(far_away):
		assert_eq(far_away.health, far_away.max_health, "at full health")
	assert_eq(run.enemies.alive_count(), 1)


func test_ac35_elites_and_bosses_only_lose_the_share_set_in_data() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var elite: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(200, 0), ELITE)
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, banane.global_position + Vector2(-260, 0))
	await wait_physics_frames(2)
	var elite_before: float = elite.health
	var ted_before: float = ted.health
	await _grab_popper()
	var rules: FloorPickupRules = run.floor_pickup_rules
	assert_false(elite.dead, "the elite survives")
	var elite_share: float = elite.max_health * rules.popper_elite_share
	assert_almost_eq(elite_before - elite.health, elite_share, 0.01, "the elite loses its share")
	assert_false(ted.dead, "Big Ted survives")
	var ted_share: float = ted.max_health * rules.popper_boss_share
	assert_almost_eq(ted_before - ted.health, ted_share, 0.01, "the boss only takes a small hit")
	assert_lt(rules.popper_boss_share, rules.popper_elite_share, "bosses lose less than elites")


func test_ac35_confetti_covers_the_screen_in_soft_colours_then_goes() -> void:
	await _quiet_run()
	var view: Rect2 = run.spawner.visible_rect()
	await _grab_popper()
	var confetti: ConfettiBlast = _confetti()
	assert_not_null(confetti, "confetti flies")
	if confetti == null:
		return
	await wait_seconds(0.8)
	var spread: Rect2 = Rect2(confetti.position, Vector2.ZERO)
	for i: int in confetti.piece_count():
		spread = spread.expand(confetti.position + confetti.piece_offset(i))
		var hue: float = confetti.piece_color(i).h
		var saturated: bool = confetti.piece_color(i).s > 0.3
		assert_false(saturated and (hue < 0.12 or hue > 0.97), "no red/orange bit (%d)" % i)
	assert_gt(spread.size.x, view.size.x * 0.7, "the bits spread over the whole screen width")
	assert_gt(spread.size.y, view.size.y * 0.7, "and height")
	await wait_seconds(run.floor_pickup_rules.popper_seconds)
	assert_null(_confetti(), "then the confetti is gone")


func test_ac35_the_dev_menu_drops_a_party_popper() -> void:
	await _quiet_run()
	run.dev_menu.press("Drop Party Popper")
	assert_eq(run.floor_pickups().size(), 1)
	if run.floor_pickups().is_empty():
		return
	assert_eq(run.floor_pickups()[0].kind.id, &"party_popper")
