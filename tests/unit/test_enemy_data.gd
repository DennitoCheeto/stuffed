extends GutTest
## Enemy numbers live in data/enemies/*.tres (hard rule 8) and follow the readability rules of
## spec 02 §8: enemy bullets are always slower than the heroes and come after a wind-up.

const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")


func test_ac13_spitter_balls_are_slower_than_banane() -> void:
	assert_not_null(SPITTER.attack, "the spitter has a ranged attack")
	assert_gt(SPITTER.attack.bullet_speed, 0.0)
	assert_lt(SPITTER.attack.bullet_speed, BANANE.move_speed, "you can always run away")


func test_ac13_spitter_always_winds_up_before_a_shot() -> void:
	assert_gte(SPITTER.attack.windup_seconds, 0.4, "long enough to see")
	assert_gt(SPITTER.attack.cooldown_seconds, SPITTER.attack.windup_seconds)


func test_spitter_keeps_its_distance_but_shoots_from_there() -> void:
	var attack: SpitAttack = SPITTER.attack
	assert_gt(attack.keep_distance - attack.distance_band, BANANE.hitbox_radius + SPITTER.radius)
	assert_gt(attack.fire_range, attack.keep_distance + attack.distance_band)


func test_spitter_pattern_is_a_single_ball_then_a_fan_of_three() -> void:
	var attack: SpitAttack = SPITTER.attack
	assert_eq(attack.balls_in_volley(0), 1)
	assert_eq(attack.balls_in_volley(1), 3)
	assert_eq(attack.balls_in_volley(2), 1, "and again")


func test_a_fan_is_centred_on_the_aim() -> void:
	var attack: SpitAttack = SpitAttack.new()
	attack.fan_step_degrees = 20.0
	var fan: Array[Vector2] = attack.directions(Vector2.RIGHT, 3)
	assert_eq(fan.size(), 3)
	assert_almost_eq(fan[1].angle(), 0.0, 0.001, "middle ball straight at you")
	assert_almost_eq(fan[0].angle(), deg_to_rad(-20.0), 0.001)
	assert_almost_eq(fan[2].angle(), deg_to_rad(20.0), 0.001)
	assert_almost_eq(attack.directions(Vector2.UP, 1)[0], Vector2.UP, Vector2.ONE * 0.001)


func test_an_empty_pattern_still_spits_one_ball() -> void:
	var attack: SpitAttack = SpitAttack.new()
	attack.pattern = []
	assert_eq(attack.balls_in_volley(4), 1)
