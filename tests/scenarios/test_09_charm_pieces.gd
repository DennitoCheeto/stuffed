extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §3, AC-99): the three Charm pieces do what they say at each stitch level.
## Jingle Bell: every N kills by the hero's own weapons a shockwave pushes and hurts zombies around
## them. Lucky Button: some XP buttons drop golden, worth x5. Wind-up Key: every 20 s the weapons
## fire faster for 4 s while the key spins.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const JINGLE_BELL: GearDef = preload("res://data/gear/jingle_bell.tres")
const LUCKY_BUTTON: GearDef = preload("res://data/gear/lucky_button.tres")
const WIND_UP_KEY: GearDef = preload("res://data/gear/wind_up_key.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const TOUGH: float = 1000.0


## Player 1 wears `piece` at stitch level `level` (Workshop Lv 3, so every slot and level is open).
func _wear(piece: GearDef, level: int) -> void:
	var save: TownSave = main.town
	save.building_levels["sewing_workshop"] = 3
	save.revealed.append("sewing_workshop")
	save.gear.add_pattern(String(piece.id))
	save.gear.stitches[String(piece.id)] = level
	save.gear.put_on(0, piece.slot_name(), String(piece.id))


func _quiet_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


## Another hero (player 2's slot) wearing `piece` at `level` (null = nothing), added to the run.
func _hero_wearing(run: Run, piece: GearDef, level: int, at: Vector2) -> Player:
	var hero: Player = PLAYER_SCENE.instantiate() as Player
	hero.stats = first_player().stats
	hero.player_index = 1
	var worn: WornGear = WornGear.new()
	if piece != null:
		worn.pieces.append(piece)
		worn.levels[piece.id] = level
	hero.gear = worn
	hero.position = at
	run.actors.add_child(hero)
	return hero


func _zombie(run: Run, at: Vector2, health: float) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(run.spawner.schedule.entries[0].enemy, at)
	zombie.max_health = health
	zombie.health = health
	zombie.move_speed = 0.0
	return zombie


## `weapon` kills `count` zombies far away from the hero.
func _kill_with(run: Run, weapon: Weapon, count: int, at: Vector2) -> void:
	for i: int in count:
		var zombie: Zombie = _zombie(run, at + Vector2(i * 4.0, 0.0), 1.0)
		run.enemies.damage(zombie, 5.0, Vector2.ZERO, weapon)


func _note_value(_player: Player, value: int, _chain: int, values: Array[int]) -> void:
	values.append(value)


func test_ac99_jingle_bell_rings_after_enough_own_kills() -> void:
	_wear(JINGLE_BELL, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	var sniper: Weapon = hero.add_weapon(SNIPER)
	sniper.set_physics_process(false)
	var bell: JingleBell = hero.get_node("JingleBell") as JingleBell
	await wait_physics_frames(2)
	var near: Zombie = _zombie(run, hero.global_position + Vector2(80.0, 0.0), TOUGH)
	var far_away: Zombie = _zombie(run, hero.global_position + Vector2(0.0, 400.0), TOUGH)
	var away: Vector2 = hero.global_position + Vector2(-900.0, 0.0)
	var partner: Player = _hero_wearing(run, null, 0, hero.global_position + Vector2(0, -300))
	disarm(partner)
	var partner_sniper: Weapon = partner.add_weapon(SNIPER)
	partner_sniper.set_physics_process(false)
	_kill_with(run, partner_sniper, 10, away)
	_kill_with(run, sniper, 29, away)
	assert_eq(bell.rings, 0, "29 own kills (the partner's don't count)")
	assert_eq(bell.kills, 29)
	Sfx.history.clear()
	_kill_with(run, sniper, 1, away)
	assert_eq(bell.rings, 1, "the 30th kill rings it (Lv 1)")
	assert_eq(bell.kills, 0, "counting starts over")
	assert_almost_eq(near.health, TOUGH - JINGLE_BELL.damage, 0.01, "the shockwave hurts")
	assert_gt(near.knockback.length(), 0.0, "and pushes back")
	assert_eq(far_away.health, TOUGH, "too far away")
	assert_true(Sfx.history.has(JINGLE_BELL.sound))
	assert_not_null(run.enemies.tally.find(-1, WeaponTally.JINGLE_BELL), "own end-screen row")
	await wait_physics_frames(3)
	assert_true(bell.visible, "the ring shows")


func test_ac99_jingle_bell_kills_per_ring_at_each_level() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, JINGLE_BELL, level, spot)
		var bell: JingleBell = hero.get_node("JingleBell") as JingleBell
		assert_eq(bell.kills_per_ring(), roundi(JINGLE_BELL.amount(level)), "Lv %d" % level)
		hero.free()
	assert_eq([JINGLE_BELL.amount(1), JINGLE_BELL.amount(3)], [30.0, 20.0], "spec numbers")
	assert_eq(JINGLE_BELL.radius, 120.0, "about 120 px (spec)")


func test_ac99_lucky_button_drops_golden_buttons_worth_five() -> void:
	_wear(LUCKY_BUTTON, 3)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	run.pickups.golden_rng.seed = 4242
	var far: Vector2 = hero.global_position + Vector2(0.0, 900.0)
	var small: int = run.pickups.rules.button_value(EnemyStats.XpSize.SMALL)
	var golden: Array[XpButton] = []
	for i: int in 300:
		var button: XpButton = run.pickups.drop(EnemyStats.XpSize.SMALL, far)
		if button.golden:
			golden.append(button)
	assert_eq(golden.size(), run.pickups.golden_dropped)
	assert_between(golden.size(), 10, 45, "about 8% of 300 at Lv 3")
	assert_eq(golden[0].value, small * 5, "worth x5")
	var values: Array[int] = []
	run.pickups.collected.connect(_note_value.bind(values))
	golden[0].position = hero.global_position + Vector2(10.0, 0.0)
	await wait_physics_frames(10)
	assert_eq(values, [small * 5] as Array[int], "the hero collected it for x5 XP")


func test_ac99_lucky_button_chance_at_each_level_and_none_without() -> void:
	var run: Run = await _quiet_run()
	assert_eq(GearEffects.golden_odds(get_tree()), Vector2.ZERO, "nobody wears it")
	var far: Vector2 = first_player().global_position + Vector2(0.0, 900.0)
	for i: int in 50:
		assert_false(run.pickups.drop(EnemyStats.XpSize.SMALL, far).golden)
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, LUCKY_BUTTON, level, spot)
		var odds: Vector2 = GearEffects.golden_odds(get_tree())
		assert_eq(odds, Vector2(LUCKY_BUTTON.amount(level), 5.0), "Lv %d" % level)
		hero.free()
	var spec: Array[float] = [LUCKY_BUTTON.amount(1), LUCKY_BUTTON.amount(3), LUCKY_BUTTON.factor]
	assert_eq(spec, [0.04, 0.08, 5.0] as Array[float], "spec numbers")


func test_ac99_wind_up_key_fires_faster_for_four_seconds_and_spins() -> void:
	_wear(WIND_UP_KEY, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	var key: WindUpKey = hero.get_node("WindUpKey") as WindUpKey
	assert_almost_eq(key.next_in(), WIND_UP_KEY.every, 0.5, "every 20 s")
	var normal: float = hero.attack_speed
	Sfx.history.clear()
	key.set(&"_next_in", 0.1)
	await wait_physics_frames(12)
	assert_true(key.is_wound_up())
	assert_almost_eq(hero.attack_speed, normal + 0.4, 0.001, "40% faster at Lv 1")
	assert_true(Sfx.history.has(WIND_UP_KEY.sound))
	assert_eq(hero.get_node("Overlay").call(&"key_icon"), key, "the key icon under the bar (#331)")
	assert_ne(key.spin, 0.0, "the key icon spins")
	await wait_seconds(WIND_UP_KEY.seconds)
	assert_false(key.is_wound_up(), "4 s later it has run down")
	assert_almost_eq(hero.attack_speed, normal, 0.001, "back to normal")
	await wait_physics_frames(2)
	assert_eq(key.spin, 0.0, "the key icon stops")
	assert_almost_eq(key.next_in(), WIND_UP_KEY.every, 0.5, "the next wind-up is 20 s away")
	assert_gt(run.elapsed, WIND_UP_KEY.seconds)


func test_ac99_wind_up_key_boost_at_each_level() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, WIND_UP_KEY, level, spot)
		await wait_physics_frames(1)
		var normal: float = hero.attack_speed
		(hero.get_node("WindUpKey") as WindUpKey).wind_up()
		var share: float = WIND_UP_KEY.amount(level)
		assert_almost_eq(hero.attack_speed, normal + share, 0.001, "Lv %d" % level)
		hero.free()
	assert_eq([WIND_UP_KEY.amount(1), WIND_UP_KEY.amount(3)], [0.4, 0.7], "spec numbers")
	assert_eq([WIND_UP_KEY.every, WIND_UP_KEY.seconds], [20.0, 4.0], "spec numbers")
