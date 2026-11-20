extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §3, AC-99): the three Head pieces do what they say at each stitch level.
## Pin Cushion Hat: pins and buttons pierce more zombies (other weapons don't). Lookout Cap:
## standing still 1 s grows the pickup range until the hero moves. Propeller Cap: the dash goes
## farther and lands with a thump that hurts zombies around the hero.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const PIN_CUSHION_HAT: GearDef = preload("res://data/gear/pin_cushion_hat.tres")
const LOOKOUT_CAP: GearDef = preload("res://data/gear/lookout_cap.tres")
const PROPELLER_CAP: GearDef = preload("res://data/gear/propeller_cap.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const SHOTGUN: WeaponStats = preload("res://data/weapons/button_shotgun.tres")
const VOLLEY: WeaponStats = preload("res://data/weapons/pincushion_volley.tres")
const YARN_BALL: WeaponStats = preload("res://data/weapons/bouncy_yarn_ball.tres")
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


## Another hero (player 2's slot) wearing `piece` at `level`, added to the run.
func _hero_wearing(run: Run, piece: GearDef, level: int) -> Player:
	var hero: Player = PLAYER_SCENE.instantiate() as Player
	hero.stats = first_player().stats
	hero.player_index = 1
	var worn: WornGear = WornGear.new()
	worn.pieces.append(piece)
	worn.levels[piece.id] = level
	hero.gear = worn
	run.actors.add_child(hero)
	return hero


func _tough_zombie(run: Run, at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(run.spawner.schedule.entries[0].enemy, at)
	zombie.max_health = TOUGH
	zombie.health = TOUGH
	return zombie


func test_ac99_pin_cushion_hat_pins_pierce_more_at_each_level() -> void:
	var run: Run = await _quiet_run()
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, PIN_CUSHION_HAT, level)
		var extra: int = roundi(PIN_CUSHION_HAT.amount(level))
		var sniper: Weapon = hero.add_weapon(SNIPER)
		var shotgun: Weapon = hero.add_weapon(SHOTGUN)
		var volley: Weapon = hero.add_weapon(VOLLEY)
		var yarn: Weapon = hero.add_weapon(YARN_BALL)
		assert_eq(hero.extra_pierce, extra, "Lv %d" % level)
		assert_eq(
			sniper.current().pierce, SNIPER.at_level(1).pierce + extra, "sniper Lv %d" % level
		)
		assert_eq(shotgun.current().pierce, SHOTGUN.at_level(1).pierce + extra, "buttons")
		assert_lt(volley.current().pierce, 0, "the volley already pierces everything")
		assert_eq(yarn.current().pierce, YARN_BALL.at_level(1).pierce, "not a pin: unchanged")
		hero.free()
	assert_eq(PIN_CUSHION_HAT.amount(3), 2.0, "+2 at Lv 3 (spec)")


func test_ac99_pin_cushion_hat_one_pin_goes_through_more_zombies() -> void:
	_wear(PIN_CUSHION_HAT, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	var sniper: Weapon = hero.add_weapon(SNIPER)
	sniper.set_physics_process(false)
	var line: Array[Zombie] = []
	for i: int in 6:
		line.append(_tough_zombie(run, hero.global_position + Vector2(80.0 + i * 36.0, 0.0)))
	var pin: PinProjectile = run.projectiles.spawn(PinProjectile) as PinProjectile
	pin.launch(sniper, Vector2.RIGHT)
	await wait_physics_frames(30)
	var hurt: int = 0
	for zombie: Zombie in line:
		if zombie.health < TOUGH:
			hurt += 1
	assert_eq(hurt, SNIPER.at_level(1).pierce + 1 + 1, "pierce 2 + 1 from the hat = 4 zombies")


func test_ac99_lookout_cap_standing_still_grows_the_pickup_range() -> void:
	_wear(LOOKOUT_CAP, 2)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	var cap: LookoutCap = hero.get_node("LookoutCap") as LookoutCap
	var normal: float = hero.pickup_range
	var spot: Vector2 = hero.global_position + Vector2(normal + 20.0, 0.0)
	var button: XpButton = run.pickups.drop(EnemyStats.XpSize.SMALL, spot)
	await wait_physics_frames(24)
	assert_eq(GearEffects.pickup_reach(hero), normal, "not yet: under 1 s still")
	assert_eq(button.position, spot, "out of the normal range")
	assert_false(cap.visible)
	await wait_physics_frames(40)
	assert_almost_eq(GearEffects.pickup_reach(hero), normal * 1.8, 0.01, "x1.8 at Lv 2")
	assert_true(cap.visible, "the ring shows the bigger reach")
	assert_ne(button.position, spot, "the button flies in now")
	await hold_action("p1_move_right", 4)
	assert_eq(GearEffects.pickup_reach(hero), normal, "moving ends it")
	assert_false(cap.visible)


func test_ac99_lookout_cap_factor_at_each_level() -> void:
	var run: Run = await _quiet_run()
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, LOOKOUT_CAP, level)
		await wait_physics_frames(roundi(LOOKOUT_CAP.seconds * FPS) + 6)
		var factor: float = LOOKOUT_CAP.amount(level)
		assert_almost_eq(
			GearEffects.pickup_reach(hero), hero.pickup_range * factor, 0.01, "Lv %d" % level
		)
		hero.free()
	assert_eq([LOOKOUT_CAP.amount(1), LOOKOUT_CAP.amount(3)], [1.6, 2.2], "spec numbers")


func test_ac99_propeller_cap_dashes_farther_and_thumps_on_landing() -> void:
	_wear(PROPELLER_CAP, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	var cap: PropellerCap = hero.get_node("PropellerCap") as PropellerCap
	var start: Vector2 = hero.global_position
	var far: float = hero.stats.dash_distance * 1.3
	var near_landing: Zombie = _tough_zombie(run, start + Vector2(far, 40.0))
	var far_away: Zombie = _tough_zombie(run, start + Vector2(-200.0, 0.0))
	Sfx.history.clear()
	await tap_action("p1_dash")
	await wait_physics_frames(20)
	assert_almost_eq(hero.global_position.x - start.x, far, 1.0, "+30% at Lv 1")
	assert_eq(cap.thumps, 1, "one thump where it landed")
	assert_almost_eq(near_landing.health, TOUGH - PROPELLER_CAP.damage, 0.01, "hurt by the thump")
	assert_eq(far_away.health, TOUGH, "too far away")
	assert_true(Sfx.history.has(PROPELLER_CAP.sound), "thump sound")
	var row: WeaponTallyEntry = run.enemies.tally.find(-1, WeaponTally.PROPELLER_CAP)
	assert_not_null(row, "its own row on the end screen")


func test_ac99_propeller_cap_dash_distance_at_each_level() -> void:
	var run: Run = await _quiet_run()
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, PROPELLER_CAP, level)
		var share: float = PROPELLER_CAP.amount(level)
		var expected: float = hero.stats.dash_distance * (1.0 + share)
		assert_almost_eq(GearEffects.dash_distance(hero), expected, 0.01, "Lv %d" % level)
		hero.free()
	assert_eq([PROPELLER_CAP.amount(1), PROPELLER_CAP.amount(3)], [0.3, 0.5], "spec numbers")
