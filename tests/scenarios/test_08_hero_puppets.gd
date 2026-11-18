extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §6, AC-90): each plushie hero is a puppet drawn from its town plushie's
## look at hero size and walks with its plushie's gait: Pip and BamBam step, Böbö waddles (a big
## side-to-side rock), Robbar hops. The walk eases in and out. Hurt flash, dash, the level-up
## cheer, falling over and standing back up work like Banane's.

const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const WALK_FRAMES: int = 40


func _puppet() -> PlushiePuppet:
	return first_player().get_node("Puppet") as PlushiePuppet


## Walks right for `frames` physics frames and notes what the puppet does: the frames it shows,
## its biggest rock (radians) and its biggest hop (pixels off the ground).
func _walk(frames: int) -> Dictionary:
	var seen: Dictionary[int, bool] = {}
	var rock: float = 0.0
	var hop: float = 0.0
	sender.action_down("p1_move_right")
	for i: int in frames:
		await wait_physics_frames(1)
		var puppet: PlushiePuppet = _puppet()
		seen[puppet.frame] = true
		rock = maxf(rock, absf(puppet.body.rotation))
		hop = maxf(hop, HeroMarker.FEET.y - puppet.body.position.y)
	sender.action_up("p1_move_right")
	return {"frames": seen.size(), "rock": rock, "hop": hop}


func test_ac90_every_plushie_hero_walks_with_its_own_gait() -> void:
	main.town.set_hero(0, "pip")
	var town: Town = await go_to_town()
	town.dev_menu.press(TownDevMenu.UNLOCK_HEROES)
	var walks: Dictionary[String, Dictionary] = {}
	for id: String in ["pip", "bobo", "bambam", "robbar"]:
		while first_player().stats.id != StringName(id):
			town.dev_menu.next_hero()
			await wait_physics_frames(2)
		var puppet: PlushiePuppet = _puppet()
		assert_not_null(puppet, id)
		assert_eq(puppet.look.shape, first_player().stats.plushie.shape, id)
		assert_between(puppet.height(), 45.0, 80.0, "%s is hero-sized" % id)
		assert_eq(puppet.frame, 0, "%s stands still" % id)
		walks[id] = await _walk(WALK_FRAMES)
		assert_gte(walks[id]["frames"], 5, "%s: feet and arms move" % id)
		await wait_physics_frames(1)
		var easing: float = _puppet().stride()
		assert_between(easing, 0.01, 0.99, "%s eases out of the walk" % id)
		await wait_physics_frames(30)
		assert_eq(_puppet().stride(), 0.0, id)
		assert_eq(_puppet().frame, 0, "%s back to standing" % id)
	assert_gt(walks["bobo"]["rock"], walks["pip"]["rock"] * 1.5, "Böbö waddles")
	assert_gt(walks["robbar"]["hop"], 4.0, "Robbar hops")
	for id: String in ["pip", "bobo", "bambam"]:
		assert_lt(walks[id]["hop"], 0.5, "%s keeps its feet on the floor" % id)


func test_ac90_hurt_dash_and_cheer_work_for_a_plushie_hero() -> void:
	main.town.plushies["bambam"] = "in_town"
	main.town.set_hero(0, "bambam")
	var run: Run = await start_run()
	run.spawner.active = false
	var hero: Player = first_player()
	var puppet: PlushiePuppet = _puppet()
	assert_not_null(puppet, "BamBam is a plushie puppet")
	await wait_seconds(0.5)
	hero.take_hit(5.0, "test")
	assert_eq(puppet.state, PlushiePuppet.State.HIT)
	var flash: float = 0.0
	for i: int in 30:
		await wait_frames(1)
		flash = maxf(flash, puppet.flash())
	assert_eq(flash, 1.0, "hit flash")
	await wait_seconds(1.2)
	sender.action_down("p1_move_right")
	await wait_physics_frames(4)
	await tap_action("p1_dash")
	await wait_physics_frames(3)
	sender.action_up("p1_move_right")
	assert_eq(puppet.state, PlushiePuppet.State.DASH)
	assert_gt(absf(puppet.body.scale.x), 1.05, "stretched along the dash")
	await wait_seconds(0.6)
	hero.celebrate()
	await wait_physics_frames(2)
	assert_eq(puppet.state, PlushiePuppet.State.CHEER)
	assert_gte(puppet.frame, puppet.wave_frame(), "waves while cheering")
	assert_gt(HeroMarker.FEET.y - puppet.body.position.y, 1.0, "jumps")


func test_ac90_a_plushie_hero_falls_over_and_stands_back_up() -> void:
	main.town.plushies["robbar"] = "in_town"
	main.town.set_hero(0, "robbar")
	await go_to_town()
	var hero: Player = first_player()
	var puppet: PlushiePuppet = _puppet()
	hero.health = 0.0
	hero.died.emit(hero)
	await wait_physics_frames(40)
	assert_eq(puppet.state, PlushiePuppet.State.DOWN)
	assert_lt(puppet.body.scale.y, 0.7, "squashed flat")
	assert_gt(absf(puppet.body.rotation), 0.2, "tipped over")
	hero.stand_up(hero.global_position)
	await wait_physics_frames(2)
	assert_eq(puppet.state, PlushiePuppet.State.IDLE)
