extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#172 part 2, vision §6): in a real run the hero is drawn over zombies, own shots,
## bursts and damage numbers, the hero ring stays on the floor, own shots lie under the zombies
## and pickups under the shots; enemy bullets are on top of everything.


func test_the_run_draws_the_clarity_ladder() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	var hero: Player = first_player()
	var stats: EnemyStats = run.spawner.schedule.entries[0].enemy
	var zombie: Zombie = run.enemies.spawn(stats, hero.position + Vector2(300, 0))
	await wait_physics_frames(2)
	var marker: Node = hero.get_node("Marker")
	var pickups: Node = run.get_node("Pickups")
	var own_shots: Node = run.projectiles.get_node("Friendly")
	var bullets: Node = run.projectiles.get_node("Hostile")
	assert_eq(WorldLayers.absolute_z(marker), WorldLayers.FLOOR_MARKS, "ring on the floor")
	assert_eq(WorldLayers.absolute_z(pickups), WorldLayers.PICKUPS)
	assert_eq(WorldLayers.absolute_z(own_shots), WorldLayers.OWN_SHOTS)
	assert_eq(WorldLayers.absolute_z(zombie), WorldLayers.ENEMIES)
	assert_eq(WorldLayers.absolute_z(hero), WorldLayers.HEROES, "the hero over the crowd")
	assert_eq(WorldLayers.absolute_z(bullets), WorldLayers.ENEMY_BULLETS, "danger on top")
	for node: String in ["Effects", "DamageNumbers"]:
		assert_lt(WorldLayers.absolute_z(run.get_node(node)), WorldLayers.HEROES, node)
	assert_gt(WorldLayers.absolute_z(marker), WorldLayers.absolute_z(run.get_node("Arena")))
