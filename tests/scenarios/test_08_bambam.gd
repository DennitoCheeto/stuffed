extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §3, AC-87, AC-88): BamBam starts with the Sewing Pin Sniper and a small
## pickup range. Big Heart: every level-up heals him and every hero nearby (co-op) by a share of
## their max health, and a heart pulse pushes the zombies close by back.

const BAMBAM: HeroStats = preload("res://data/heroes/bambam.tres")
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")


func _start_as_bambam(players: int = 1) -> Run:
	main.town.plushies["bambam"] = "in_town"
	main.town.set_hero(0, "bambam")
	main.player_count = players
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


func test_ac87_bambam_starts_with_the_sniper_and_a_small_pickup_range() -> void:
	await _start_as_bambam()
	var bambam: Player = first_player()
	assert_eq(bambam.stats, BAMBAM)
	assert_not_null(bambam.weapon(&"sewing_pin_sniper"))
	assert_lt(bambam.pickup_range, BANANE.pickup_range, "smaller than Banane's")


func test_ac88_a_level_up_heals_heroes_nearby_and_pushes_zombies_back() -> void:
	var run: Run = await _start_as_bambam(2)
	var players: Array[Player] = Players.all(get_tree())
	assert_eq(players.size(), 2)
	var bambam: Player = first_player()
	var partner: Player = players[1] if players[0] == bambam else players[0]
	for hero: Player in players:
		disarm(hero)
	partner.global_position = bambam.global_position + Vector2(120, 0)
	bambam.health = bambam.max_health * 0.5
	partner.health = partner.max_health * 0.5
	var zombie: Zombie = run.enemies.spawn(
		run.spawner.schedule.entries[0].enemy, bambam.global_position + Vector2(0, 90)
	)
	await wait_physics_frames(2)
	var heart: BigHeart = bambam.get_node("BigHeart") as BigHeart
	bambam.progress.leveled_up.emit(2)
	assert_eq(heart.pulses, 1)
	var share: float = BAMBAM.big_heart_heal
	assert_almost_eq(bambam.health, bambam.max_health * (0.5 + share), 0.01, "heals him")
	assert_almost_eq(partner.health, partner.max_health * (0.5 + share), 0.01, "and his partner")
	assert_eq(heart.pushed, 1, "the pulse pushed the zombie")
	assert_gt(zombie.knockback.y, 0.0, "away from him")
	assert_true(heart.visible, "the heart pulse shows")
