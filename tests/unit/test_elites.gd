extends GutTest
## Elites (spec 02 §8, §10): bigger, tougher, one telegraphed pattern, about 3-4 per run before
## the boss, spread out. Numbers live in data/elite_rules.tres and data/spawn_schedule.tres.

const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const RUN_RULES: RunRules = preload("res://data/run_rules.tres")
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")
## The mini-boss arrives at 4:00 (spec 02 §9): no elite right on top of it.
const MINI_BOSS_SECONDS: float = 240.0


func test_elites_are_bigger_and_tougher() -> void:
	assert_gte(ELITE.health_multiplier, 5.0, "much more health")
	assert_gte(ELITE.size, 1.3, "visibly bigger")
	assert_gte(ELITE.contact_damage_multiplier, 1.0)
	assert_lt(ELITE.knockback_multiplier, 1.0, "harder to push")
	assert_eq(ELITE.xp_button, EnemyStats.XpSize.BIG)


func test_elite_pattern_is_telegraphed_and_dodgeable() -> void:
	var attack: SpitAttack = ELITE.attack
	assert_not_null(attack, "one pattern")
	assert_gte(attack.windup_seconds, 0.6, "a long, visible wind-up")
	assert_gt(attack.cooldown_seconds, attack.windup_seconds)
	assert_lt(attack.bullet_speed, BANANE.move_speed, "slower than Banane")
	assert_gte(attack.balls_in_volley(0), 6, "a ring of balls")


func test_three_or_four_elites_before_the_boss() -> void:
	assert_between(SCHEDULE.elites_before(RUN_RULES.goal_seconds), 3, 4)


func test_elites_are_spread_out() -> void:
	assert_gte(SCHEDULE.elite_time(0), 60.0, "not in the first minute")
	for index: int in SCHEDULE.elites_before(RUN_RULES.goal_seconds):
		var at: float = SCHEDULE.elite_time(index)
		assert_not_null(SCHEDULE.elite_enemy(index))
		assert_gt(absf(at - MINI_BOSS_SECONDS), 20.0, "not with the mini-boss")
		if index > 0:
			assert_gte(at - SCHEDULE.elite_time(index - 1), 60.0, "at least a minute apart")


func test_elite_types_are_already_in_the_horde_at_their_time() -> void:
	for index: int in SCHEDULE.elites.size():
		var enemy: EnemyStats = SCHEDULE.elite_enemy(index)
		if enemy == SCHEDULE.shambler:
			continue
		var entry: SpawnEntry = SCHEDULE.entry_named(enemy.display_name)
		assert_lte(entry.start_seconds, SCHEDULE.elite_time(index), enemy.display_name)


func test_elites_keep_coming_in_endless() -> void:
	var last: int = SCHEDULE.elites.size() - 1
	var gap: float = SCHEDULE.elite_time(last + 1) - SCHEDULE.elite_time(last)
	assert_eq(gap, SCHEDULE.elite_repeat_seconds)
	assert_eq(SCHEDULE.elite_time(last + 3), SCHEDULE.elite_time(last) + 3.0 * gap)
	assert_eq(SCHEDULE.elite_enemy(last + 1), SCHEDULE.elite_enemy(0), "types cycle")


func test_no_elites_without_a_list() -> void:
	var schedule: SpawnSchedule = SpawnSchedule.new()
	assert_eq(schedule.elite_time(0), INF)
	assert_eq(schedule.elites_before(1000.0), 0)


func test_an_elite_zombie_uses_the_elite_numbers() -> void:
	var shambler: EnemyStats = SCHEDULE.shambler
	var zombie: Zombie = Zombie.new()
	zombie.setup(shambler, 1.0, 1.0, 0.0, ELITE)
	assert_true(zombie.is_elite())
	assert_eq(zombie.max_health, shambler.max_health * ELITE.health_multiplier)
	assert_eq(zombie.health, zombie.max_health)
	assert_eq(zombie.radius(), shambler.radius * ELITE.size)
	assert_eq(zombie.contact_damage, shambler.contact_damage * ELITE.contact_damage_multiplier)
	assert_eq(zombie.attack, ELITE.attack)
	assert_eq(zombie.display_name, "Elite Shambler")
	assert_eq(zombie.xp_button(), ELITE.xp_button)
	assert_eq(zombie.puppet.elite_marks.size(), 2, "gold patch and crown")
	zombie.free()


func test_a_normal_zombie_is_unchanged() -> void:
	var shambler: EnemyStats = SCHEDULE.shambler
	var zombie: Zombie = Zombie.new()
	zombie.setup(shambler, 1.0, 1.0, 0.0)
	assert_false(zombie.is_elite())
	assert_eq(zombie.max_health, shambler.max_health)
	assert_eq(zombie.radius(), shambler.radius)
	assert_null(zombie.attack)
	assert_eq(zombie.display_name, "Shambler")
	assert_eq(zombie.puppet.elite_marks.size(), 0)
	zombie.free()
