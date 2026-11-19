extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §3, §10, AC-106): an evolution plays the sewing reveal on the gift box screen
## (any key jumps to its end), then back in the run: slow motion, a ring pulse from the hero, a big
## first attack and the evolution's own sting, only the first time per evolution kind per run.
## Reduced motion skips the slow motion. The dev menu's "Evolve now" plays it all at once.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const MOMENT: EvolutionMomentRules = preload("res://data/ui/evolution_moment.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")

var run: Run
## Biggest shot size of the watched weapon each time it fired.
var fired: Array[float] = []
var _watched: Weapon


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	GameSettings.reduced_motion = false
	Engine.time_scale = 1.0
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	first_player().invincible = true
	return run


## Readies Banana Split for player 1 and drops its gift box on them.
func _open_split_box() -> EvolutionDef:
	var pool: UpgradePool = run.upgrade_pool
	var evolution: EvolutionDef = pool.evolution_into(&"banana_split")
	var banane: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	var boomerang: Weapon = banane.weapon(evolution.weapon)
	if boomerang == null:
		boomerang = banane.add_weapon(base.weapon)
	boomerang.level = base.top_level()
	banane.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	run.drop_gift_box(banane.global_position)
	return evolution


func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _revealing() -> bool:
	return run.gift_screen.revealing


func _reveal_done() -> bool:
	return run.gift_screen.reveal.is_done()


func _showing_contents() -> bool:
	return run.gift_screen.showing_contents


func _moment_played() -> bool:
	return not run.evolution_moment.moments.is_empty()


func _not_slowed() -> bool:
	return not run.evolution_moment.slowed


func _pulse_on(player: Player) -> EvolutionPulse:
	for child: Node in player.get_children():
		if child is EvolutionPulse:
			return child as EvolutionPulse
	return null


func _press_a_key() -> void:
	sender.key_down(KEY_X)
	await wait_process_frames(1)
	sender.key_up(KEY_X)
	await wait_process_frames(1)


func test_ac106_the_gift_screen_sews_the_evolution_together() -> void:
	await _quiet_run()
	var evolution: EvolutionDef = _open_split_box()
	assert_true(await _wait_until(_revealing, 3.0), "after the lid pops, the reveal plays")
	var reveal: EvolutionReveal = run.gift_screen.reveal
	assert_true(reveal.visible)
	assert_eq(reveal.weapon_icon.icon, run.upgrade_pool.find(&"peel_boomerang").icon, "weapon")
	assert_eq(reveal.item_icon.icon, run.upgrade_pool.find(&"quick_feet").icon, "+ item")
	assert_eq(reveal.evolved_icon.icon, evolution.icon, "→ the evolved weapon")
	assert_false(reveal.shows_stamp(), "no stamp yet")
	var stages: Array[EvolutionReveal.Stage] = []
	while not reveal.is_done():
		if not stages.has(reveal.stage()):
			stages.append(reveal.stage())
		await wait_process_frames(1)
	assert_true(stages.has(EvolutionReveal.Stage.STITCH), "the needle sews them together")
	assert_true(reveal.shows_stamp(), "EVOLVED! stamp")
	assert_eq(reveal.stamp.text, MOMENT.stamp_text)
	assert_almost_eq(reveal.duration(), MOMENT.reveal_seconds, 0.001, "about 1.5 s")
	assert_true(await _wait_until(_showing_contents, 1.0), "then the cards")
	assert_false(reveal.visible)


func test_ac106_any_key_skips_the_reveal_to_its_end() -> void:
	await _quiet_run()
	_open_split_box()
	assert_true(await _wait_until(_revealing, 3.0))
	await wait_process_frames(2)
	assert_false(_reveal_done())
	await _press_a_key()
	assert_true(_reveal_done(), "jumped to the end")
	assert_true(run.gift_screen.reveal.shows_stamp(), "the stamp shows")
	assert_true(await _wait_until(_showing_contents, 1.0), "and the cards follow")


func test_ac106_back_in_the_run_slow_motion_pulse_big_shot_and_sting() -> void:
	await _quiet_run()
	_open_split_box()
	assert_true(await _wait_until(_showing_contents, 4.0))
	var banane: Player = first_player()
	var split: Weapon = banane.weapon(&"banana_split")
	assert_false(_moment_played(), "nothing while the gift screen is up")
	Sfx.history.clear()
	run.gift_screen.close()
	assert_true(await _wait_until(_moment_played, 1.0), "the moment plays once it closes")
	assert_true(run.evolution_moment.slowed, "slow motion")
	assert_lt(Engine.time_scale, 1.0)
	assert_not_null(_pulse_on(banane), "a ring pulses from the hero")
	assert_true(Sfx.history.has(split.stats.sting), "its own sting")
	assert_eq(split.attack_boost, MOMENT.big_attack_scale, "the first attack will be big")
	await wait_seconds(MOMENT.slow_seconds + 0.3)
	assert_true(await _wait_until(_not_slowed, 1.0), "the slow motion ends")
	assert_eq(Engine.time_scale, 1.0, "normal speed again")
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(150, 0))
	zombie.health = 100000.0
	zombie.move_speed = 0.0
	fired.clear()
	_watched = split
	split.fired.connect(_on_fired)
	await _wait_until(_fired_twice, 6.0)
	assert_gte(fired.size(), 2, "it attacked twice")
	if fired.size() >= 2:
		assert_gt(fired[0], fired[1] * 1.3, "the first attack is drawn much bigger")
	assert_eq(split.attack_boost, 1.0, "only the first one")


func _on_fired() -> void:
	fired.append(_biggest_shot(_watched))


func _fired_twice() -> bool:
	return fired.size() >= 2


func _biggest_shot(weapon: Weapon) -> float:
	var biggest: float = 0.0
	for shot: Projectile in run.projectiles.fired_by(weapon):
		biggest = maxf(biggest, shot.scale.x)
	return biggest


func test_ac106_only_the_first_time_per_evolution_kind() -> void:
	await _quiet_run()
	_open_split_box()
	assert_true(await _wait_until(_showing_contents, 4.0))
	run.gift_screen.close()
	assert_true(await _wait_until(_moment_played, 1.0))
	var split: Weapon = first_player().weapon(&"banana_split")
	run.evolution_moment.evolved(split)
	await wait_process_frames(3)
	assert_eq(run.evolution_moment.moments.size(), 1, "the same kind again: no second moment")
	assert_true(run.evolution_moment.has_played(&"banana_split"))


func test_ac106_reduced_motion_skips_the_slow_motion() -> void:
	await _quiet_run()
	GameSettings.reduced_motion = true
	_open_split_box()
	assert_true(await _wait_until(_showing_contents, 4.0))
	run.gift_screen.close()
	assert_true(await _wait_until(_moment_played, 1.0))
	assert_false(run.evolution_moment.slowed, "no slow motion")
	assert_eq(Engine.time_scale, 1.0)
	assert_false(run.evolution_moment.moments[0]["slowed"])
	assert_not_null(_pulse_on(first_player()), "the pulse still shows")


func test_dev_menu_evolve_now_plays_the_moment() -> void:
	await _quiet_run()
	run.dev_menu.press(DevMenu.EVOLVE_NOW)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0), "its gift box opens at once")
	assert_true(run.gift_screen.evolution, "with an evolution")
	run.gift_screen.close()
	assert_true(await _wait_until(_moment_played, 1.0), "and the moment plays")
	var evolved: StringName = StringName(run.evolution_moment.moments[0]["weapon"])
	assert_not_null(first_player().weapon(evolved))


## Rule 9 / spec 10 §11: the pulse ring is never a danger colour and zombies keep the strongest
## contrast on every floor (dusk too).
func test_the_pulse_stays_quieter_than_zombies() -> void:
	var pulse: Color = MOMENT.pulse_color
	assert_false(UiColors.is_danger(pulse), pulse.to_html())
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for group: Array in PALETTE.floor_groups():
		for floor_color: Color in group:
			for shade: Color in [floor_color, floor_color * PALETTE.dusk_tint]:
				var floor: float = WorldPalette.brightness(shade)
				var gap: float = absf(floor - WorldPalette.brightness(pulse))
				assert_lt(gap, absf(floor - ink), "pulse on %s" % shade.to_html())
