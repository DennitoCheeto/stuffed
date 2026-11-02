extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, AC-69, AC-71, AC-73): the Snack Bar's tricks work in a run. Picnic:
## beating the mini-boss heals every hero to full. Second Helping: healing past full health
## becomes a shield (up to its number) that takes hits first, shown as a light outline on the
## health bar. Spare Stuffing: once per run per hero, a fall becomes a pop back up with half
## health and a soft shockwave; a heart patch shows on the HUD until it's used.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SECOND_HELPING: TrickDef = preload("res://data/town/tricks/second_helping.tres")
const SPARE_STUFFING: TrickDef = preload("res://data/town/tricks/spare_stuffing.tres")
const DEADLY: float = 99999.0

var run: Run


func _quiet_run(tricks: Array[String], heroes: int = 1) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	main.player_count = heroes
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.enemies.calm = true
	return run


func _beat_mini_boss() -> void:
	var boss: Zombie = run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	run.enemies.damage(boss, boss.max_health * 10.0)
	await wait_process_frames(2)


## Waits until `hero` can be hurt again (after-hit invulnerability).
func _wait_hurtable(hero: Player) -> void:
	while hero.hurt_invulnerable_left() > 0.0:
		await wait_physics_frames(1)


func test_ac69_without_picnic_the_mini_boss_heals_nobody() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	banane.take_hit(40.0, "test")
	var hurt_health: float = banane.health
	await _beat_mini_boss()
	assert_gt(run.mini_boss_defeated_at, 0.0, "the mini-boss is down")
	assert_eq(banane.health, hurt_health)
	assert_false(run.tricks.fired(&"picnic"))


func test_ac69_ac71_picnic_heals_every_hero_to_full() -> void:
	add_controls(1)
	await _quiet_run(["picnic"], 2)
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2)
	heroes[0].take_hit(40.0, "test")
	heroes[1].take_hit(70.0, "test")
	await _beat_mini_boss()
	for hero: Player in heroes:
		assert_eq(hero.health, hero.max_health, "hero %d is full" % hero.player_index)
	assert_true(run.tricks.fired(&"picnic"))
	assert_eq(run.hud.trick_banner.title.text, "Picnic!")


func test_ac69_without_second_helping_extra_healing_is_lost() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	banane.heal(30.0)
	assert_eq(banane.shield, 0.0)
	assert_false(run.hud.shield_outline.visible)
	assert_false(run.tricks.fired(&"second_helping"))


func test_ac69_second_helping_turns_extra_healing_into_a_shield() -> void:
	await _quiet_run(["second_helping"])
	var banane: Player = first_player()
	var biggest: float = SECOND_HELPING.amount
	assert_gt(biggest, 0.0, "the shield's size lives in data")
	assert_false(run.hud.shield_outline.visible, "no shield yet")
	banane.take_hit(10.0, "test")
	banane.heal(15.0)
	assert_eq(banane.health, banane.max_health)
	assert_almost_eq(banane.shield, 5.0, 0.01, "only what went past full")
	assert_true(run.tricks.fired(&"second_helping"))
	assert_eq(run.hud.trick_banner.title.text, "Second Helping!")
	banane.heal(biggest * 3.0)
	assert_eq(banane.shield, biggest, "never more than the biggest shield")
	await wait_process_frames(1)
	assert_true(run.hud.shield_outline.visible, "an outline on the health bar")
	assert_almost_eq(run.hud.shield_outline.share(), 1.0, 0.01, "a full ring")
	assert_string_contains(run.hud.health_label.text, "+%d" % roundi(biggest))
	await _wait_hurtable(banane)
	banane.take_hit(biggest + 5.0, "test")
	assert_eq(banane.shield, 0.0, "the shield took the hit first")
	assert_almost_eq(banane.health, banane.max_health - 5.0, 0.01, "the rest hurt")
	await wait_process_frames(1)
	assert_false(run.hud.shield_outline.visible)
	assert_false(UiColors.is_danger(run.hud.shield_outline.color), "never danger red (AC-73)")


func test_ac69_without_spare_stuffing_a_fall_is_a_fall() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	assert_false(run.hud.spare_heart.visible)
	banane.take_hit(DEADLY, "test")
	assert_true(banane.is_dead())


func test_ac69_spare_stuffing_pops_the_hero_back_up_once() -> void:
	await _quiet_run(["spare_stuffing"])
	var banane: Player = first_player()
	disarm(banane)
	assert_true(run.hud.spare_heart.visible, "the heart patch shows until it's used")
	var near: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(120.0, 0.0))
	var far_away: Vector2 = banane.global_position + Vector2(0.0, 900.0)
	var far: Zombie = run.enemies.spawn(SHAMBLER, far_away)
	await wait_physics_frames(2)
	var start_distance: float = near.position.distance_to(banane.global_position)
	Sfx.history.clear()
	banane.take_hit(DEADLY, "test")
	assert_false(banane.is_dead(), "popped back up")
	assert_almost_eq(banane.health, banane.max_health * SPARE_STUFFING.amount, 0.01, "half")
	assert_false(run.over)
	assert_false(banane.has_spare_stuffing(), "used up")
	assert_true(run.tricks.fired(&"spare_stuffing"))
	assert_eq(run.hud.trick_banner.title.text, "Spare Stuffing!")
	assert_has(Sfx.history, RunTricks.SPARE_SOUND)
	assert_gt(near.knockback.x, 0.0, "the nearby zombie is pushed away from the hero")
	assert_eq(far.knockback, Vector2.ZERO, "zombies far away are not")
	var waves: Array[SpareShockwave] = _shockwaves()
	assert_eq(waves.size(), 1, "a shockwave")
	assert_false(UiColors.is_danger(waves[0].color), "never danger red (AC-73)")
	run.enemies.calm = false
	await wait_physics_frames(15)
	assert_gt(near.position.distance_to(banane.global_position), start_distance + 60.0, "flew off")
	run.enemies.calm = true
	await wait_process_frames(1)
	assert_false(run.hud.spare_heart.visible, "the heart patch is gone")
	await _wait_hurtable(banane)
	banane.take_hit(DEADLY, "test")
	assert_true(banane.is_dead(), "only once per run")
	assert_true(run.over)


func test_ac71_spare_stuffing_is_per_hero_in_coop() -> void:
	add_controls(1)
	await _quiet_run(["spare_stuffing"], 2)
	var heroes: Array[Player] = Players.all(get_tree())
	heroes[1].take_hit(DEADLY, "test")
	assert_false(heroes[1].is_dead(), "player 2 popped back up")
	assert_false(heroes[1].has_spare_stuffing())
	assert_true(heroes[0].has_spare_stuffing(), "player 1 still has theirs")
	assert_true(run.hud.spare_heart.visible, "player 1's HUD heart stays")
	assert_eq(int(run.tricks.moments[0]["player"]), 1, "noted for player 2")
	heroes[0].take_hit(DEADLY, "test")
	assert_false(heroes[0].is_dead(), "player 1 pops back up too")
	assert_false(run.hud.spare_heart.visible)
	assert_eq(_shockwaves().size(), 2, "one shockwave each")


func test_ac73_heart_patch_is_rose_not_danger() -> void:
	assert_false(UiColors.is_danger(SpareHeartPatch.FILL))


func _shockwaves() -> Array[SpareShockwave]:
	var waves: Array[SpareShockwave] = []
	for child: Node in run.effects.get_children():
		if child is SpareShockwave:
			waves.append(child as SpareShockwave)
	return waves
