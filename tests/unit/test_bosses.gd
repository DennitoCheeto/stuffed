extends GutTest
## Big Ted, the mini-boss, and the Sock Puppet King, the boss (spec 02 §9, AC-17, AC-18, AC-24).
## Both telegraph their patterns and make spawning lighter while alive. Numbers live in
## data/bosses/*.tres.

const BIG_TED: BigTedDef = preload("res://data/bosses/big_ted.tres")
const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")
const KING: SockKingDef = preload("res://data/bosses/sock_puppet_king.tres")
const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")


func test_big_ted_is_the_mini_boss_at_4_00() -> void:
	assert_eq(SCHEDULE.mini_boss, BIG_TED)
	assert_eq(BIG_TED.at_seconds, 240.0)
	assert_eq(BIG_TED.enemy.display_name, "Big Ted")
	assert_false(BIG_TED.banner.is_empty(), "announced with a banner")


func test_big_ted_is_a_giant_zombie_teddy() -> void:
	assert_eq(BIG_TED.enemy.look, EnemyStats.Look.SHAMBLER, "the teddy look")
	assert_gt(BIG_TED.enemy.radius * BIG_TED.size, SHAMBLER.radius * ELITE.size * 1.5)
	var elite_health: float = SHAMBLER.max_health * ELITE.health_multiplier
	assert_gt(BIG_TED.enemy.max_health, elite_health * 10.0, "a real fight, not an elite")
	assert_eq(BIG_TED.enemy.knockback_taken, 0.0, "can't be pushed around")
	assert_lt(BIG_TED.enemy.move_speed, BANANE.move_speed, "walks slower than Banane")


func test_his_patterns_are_telegraphed_and_dodgeable() -> void:
	assert_gte(BIG_TED.charge_windup_seconds, 0.6, "the red line shows long enough to step aside")
	assert_gt(BIG_TED.charge_recover_seconds, 0.0, "a moment to hit back after a charge")
	var stomp: SpitAttack = BIG_TED.stomp
	assert_gte(stomp.windup_seconds, 0.6, "the stomp ring shows first")
	assert_lt(stomp.bullet_speed, BANANE.move_speed, "stomp balls are slower than Banane")
	var balls: int = stomp.balls_in_volley(0)
	assert_gte(balls, 8, "a ring of balls")
	assert_almost_eq(balls * stomp.fan_step_degrees, 360.0, 0.01, "evenly all around")


func test_spawning_is_lighter_while_he_is_alive() -> void:
	assert_between(BIG_TED.spawn_rate_scale, 0.1, 0.8)


func test_charge_stops_at_the_arena_edge() -> void:
	var area: Rect2 = Rect2(0, 0, 1000, 600)
	var from: Vector2 = Vector2(800, 300)
	assert_almost_eq(BigTedBrain._room_ahead(from, Vector2.RIGHT, area), 200.0, 0.01)
	assert_almost_eq(BigTedBrain._room_ahead(from, Vector2.LEFT, area), 800.0, 0.01)
	assert_almost_eq(BigTedBrain._room_ahead(from, Vector2.DOWN, area), 300.0, 0.01)
	var diagonal: Vector2 = Vector2(1, 1).normalized()
	assert_almost_eq(BigTedBrain._room_ahead(from, diagonal, area), 200.0 * sqrt(2.0), 0.01)


func test_the_sock_puppet_king_is_the_boss_at_the_goal() -> void:
	assert_eq(SCHEDULE.boss, KING)
	assert_eq(KING.enemy.display_name, "Sock Puppet King")
	assert_eq(KING.enemy.look, EnemyStats.Look.SOCK_KING, "a zombie sock puppet with a crown")
	assert_gt(KING.enemy.max_health, BIG_TED.enemy.max_health, "tougher than Big Ted")
	assert_eq(KING.enemy.knockback_taken, 0.0)
	assert_lt(KING.enemy.move_speed, BANANE.move_speed)
	assert_false(KING.banner.is_empty())
	assert_between(KING.spawn_rate_scale, 0.1, 0.8, "lighter spawning while he's alive")


func test_his_sock_spiral_is_slow_and_even() -> void:
	var spiral: SpitAttack = KING.spiral
	assert_gte(spiral.windup_seconds, 0.6, "he glows first")
	assert_lt(spiral.bullet_speed, BANANE.move_speed, "slower than Banane")
	var arms: int = spiral.balls_in_volley(0)
	assert_gte(arms, 2)
	assert_almost_eq(arms * spiral.fan_step_degrees, 360.0, 0.01, "arms evenly around him")
	assert_gt(KING.spiral_turn_degrees, 0.0, "it turns")
	assert_lt(KING.spiral_turn_degrees, 180.0, "slowly")


func test_he_summons_a_ring_of_runners_and_lunges_when_angry() -> void:
	assert_eq(KING.summon_enemy, RUNNER)
	assert_gte(KING.summon_count, 4)
	assert_gte(KING.summon_windup_seconds, 0.6, "the marks show first")
	assert_eq(KING.angry_below, 0.5, "angry at half health")
	assert_gte(KING.lunge_windup_seconds, 0.6, "the landing spot shows first")
	assert_gt(KING.lunge_radius, 0.0)
	assert_gt(KING.lunge_damage, 0.0)


func test_boss_music_is_a_track() -> void:
	assert_true(MusicPlayer.TRACKS.has(&"boss"))
