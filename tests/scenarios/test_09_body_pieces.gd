extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §3, AC-99): the three Body pieces do what they say at each stitch level.
## Raincoat: a dash leaves a puddle for 3 s that slows zombies and pops enemy bullets. Patch Vest:
## a patch catches one hit whole (before the shield), shows on the vest and grows back. Picnic
## Apron: a snack drops behind the hero on a timer and heals whoever is hurt and touches it.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const RAINCOAT: GearDef = preload("res://data/gear/raincoat.tres")
const PATCH_VEST: GearDef = preload("res://data/gear/patch_vest.tres")
const PICNIC_APRON: GearDef = preload("res://data/gear/picnic_apron.tres")
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


func _still_zombie(run: Run, at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(run.spawner.schedule.entries[0].enemy, at)
	zombie.max_health = TOUGH
	zombie.health = TOUGH
	zombie.move_speed = 0.0
	return zombie


func test_ac99_raincoat_dash_leaves_a_puddle_that_slows_and_fizzles() -> void:
	_wear(RAINCOAT, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	var coat: Raincoat = hero.get_node("Raincoat") as Raincoat
	var start: Vector2 = hero.global_position
	var dash: float = hero.stats.dash_distance
	var in_path: Zombie = _still_zombie(run, start + Vector2(dash / 2.0, 10.0))
	var beside: Zombie = _still_zombie(run, start + Vector2(dash / 2.0, 160.0))
	Sfx.history.clear()
	await tap_action("p1_dash")
	await wait_physics_frames(20)
	assert_eq(coat.puddles_made, 1, "one puddle per dash")
	var puddle: RaincoatPuddle = coat.puddles()[0]
	assert_true(puddle.covers(start + Vector2(dash / 2.0, 0.0)), "along the dash path")
	assert_true(Sfx.history.has(RAINCOAT.sound), "splash sound")
	assert_almost_eq(in_path.slow_amount, RAINCOAT.amount(1), 0.001, "30% slower at Lv 1")
	assert_eq(beside.slow_amount, 0.0, "outside the puddle")
	var bullet: EnemyBullet = run.projectiles.spawn(EnemyBullet) as EnemyBullet
	bullet.launch(start + Vector2(dash / 2.0, -120.0), Vector2(0.0, 300.0), 7.0, 8.0, 5.0, "Spit")
	await wait_physics_frames(30)
	assert_eq(puddle.fizzled, 1, "the bullet fizzled in the puddle")
	assert_eq(run.projectiles.hostile_count(), 0)
	await wait_seconds(RAINCOAT.seconds)
	assert_true(coat.puddles().is_empty(), "dried up after 3 s")


func test_ac99_raincoat_slow_at_each_level() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, RAINCOAT, level, spot)
		var zombie: Zombie = _still_zombie(run, spot + Vector2(40.0, 0.0))
		hero.dashed.emit(spot, Vector2.RIGHT)
		hero.dash_landed.emit(spot + Vector2(80.0, 0.0))
		await wait_physics_frames(2)
		assert_almost_eq(zombie.slow_amount, RAINCOAT.amount(level), 0.001, "Lv %d" % level)
		hero.free()
		run.enemies.kill_all()
	assert_eq([RAINCOAT.amount(1), RAINCOAT.amount(3), RAINCOAT.seconds], [0.3, 0.5, 3.0], "spec")


func test_ac99_patch_vest_catches_one_hit_then_grows_back() -> void:
	_wear(PATCH_VEST, 3)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	hero.max_shield = 10.0
	hero.add_shield(10.0)
	var vest: PatchVest = hero.get_node("PatchVest") as PatchVest
	await wait_physics_frames(2)
	var view: HeroGear = hero.get_node("Puppet").get(&"gear_view") as HeroGear
	var vest_sprite: Sprite2D = view.sprite(GearDef.Slot.BODY)
	assert_not_null(vest_sprite, "the vest is shown")
	var with_patch: Rect2 = vest_sprite.region_rect
	assert_true(view.shows_patch(), "with its patch")
	var full: float = hero.health
	Sfx.history.clear()
	assert_false(hero.take_hit(20.0, "Zombie"), "the patch caught it")
	await wait_physics_frames(2)
	assert_eq(hero.health, full, "no damage")
	assert_eq(hero.shield, 10.0, "the patch blocks before the shield")
	assert_false(view.shows_patch(), "the patch is gone")
	assert_ne(vest_sprite.region_rect, with_patch, "the vest without the patch")
	assert_true(Sfx.history.has(PATCH_VEST.sound))
	assert_almost_eq(vest.regrow_left(), PATCH_VEST.amount(3), 0.1, "back in 12 s at Lv 3")
	await wait_seconds(hero.stats.hurt_invulnerability + 0.1)
	assert_true(hero.take_hit(20.0, "Zombie"), "the next hit goes to the shield and health")
	assert_eq(hero.shield, 0.0)
	vest.set(&"_regrow_left", 0.2)
	await wait_seconds(0.5)
	assert_true(hero.patch_up, "grown back")
	assert_eq(vest_sprite.region_rect, with_patch, "and shows again")
	assert_eq(vest.blocks, 1)


func test_ac99_patch_vest_regrow_time_at_each_level() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, PATCH_VEST, level, spot)
		var vest: PatchVest = hero.get_node("PatchVest") as PatchVest
		assert_true(hero.patch_up, "starts with the patch on")
		hero.take_hit(5.0, "Zombie")
		assert_eq(vest.regrow_left(), PATCH_VEST.amount(level), "Lv %d" % level)
		hero.free()
	assert_eq([PATCH_VEST.amount(1), PATCH_VEST.amount(3)], [20.0, 12.0], "spec numbers")


func test_ac99_picnic_apron_drops_snacks_that_heal_a_hurt_partner() -> void:
	_wear(PICNIC_APRON, 1)
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	disarm(hero)
	var apron: PicnicApron = hero.get_node("PicnicApron") as PicnicApron
	assert_almost_eq(apron.next_in(), PICNIC_APRON.amount(1), 0.5, "every 60 s at Lv 1")
	hero.facing = Vector2.RIGHT
	apron.set(&"_next_in", 0.1)
	await wait_physics_frames(12)
	assert_eq(apron.dropped, 1, "the timer dropped a snack")
	var snack: ApronSnack = apron.snacks()[0]
	assert_lt(snack.global_position.x, hero.global_position.x, "behind the hero")
	assert_almost_eq(apron.next_in(), PICNIC_APRON.amount(1), 0.5, "the timer starts over")
	await wait_physics_frames(10)
	assert_eq(apron.eaten, 0, "a hero at full health walks over it")
	var partner: Player = _hero_wearing(run, null, 0, snack.global_position + Vector2(0, 200))
	await wait_physics_frames(2)
	partner.health = partner.max_health * 0.5
	Sfx.history.clear()
	partner.global_position = snack.global_position
	await wait_physics_frames(3)
	assert_eq(apron.eaten, 1, "the hurt partner ate it")
	assert_almost_eq(partner.health, partner.max_health * 0.65, 0.01, "heals 15%")
	assert_true(apron.snacks().is_empty())
	assert_true(Sfx.history.has(PICNIC_APRON.sound))


func test_ac99_picnic_apron_gap_and_snack_cap() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(0.0, 300.0)
	for level: int in [1, 2, 3]:
		var hero: Player = _hero_wearing(run, PICNIC_APRON, level, spot)
		var apron: PicnicApron = hero.get_node("PicnicApron") as PicnicApron
		assert_eq(apron.gap(), PICNIC_APRON.amount(level), "Lv %d" % level)
		hero.free()
	assert_eq([PICNIC_APRON.amount(1), PICNIC_APRON.amount(3)], [60.0, 40.0], "spec numbers")
	var keeper: Player = _hero_wearing(run, PICNIC_APRON, 3, spot)
	var keeper_apron: PicnicApron = keeper.get_node("PicnicApron") as PicnicApron
	for i: int in PicnicApron.MAX_SNACKS:
		keeper_apron.drop()
	keeper_apron.set(&"_next_in", 0.05)
	await wait_physics_frames(10)
	assert_eq(keeper_apron.snacks().size(), PicnicApron.MAX_SNACKS, "no more than 3 wait")
	assert_eq(PICNIC_APRON.factor, 0.15, "heals 15% (spec)")
