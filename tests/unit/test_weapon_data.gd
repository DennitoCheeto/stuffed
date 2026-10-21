extends GutTest

const BOOMERANG: WeaponStats = preload("res://data/weapons/peel_boomerang.tres")


func test_boomerang_has_five_levels_with_card_text() -> void:
	assert_eq(BOOMERANG.id, &"peel_boomerang")
	assert_eq(BOOMERANG.max_level(), 5)
	for level: int in range(1, 6):
		assert_ne(BOOMERANG.at_level(level).card_text, "", "level %d has card text" % level)


func test_boomerang_level_one_matches_the_spec() -> void:
	var first: WeaponLevel = BOOMERANG.at_level(1)
	assert_eq(first.damage, 8.0)
	assert_eq(first.cooldown, 1.4)
	assert_eq(first.reach, 250.0)
	assert_eq(first.count, 1)


func test_boomerang_levels_add_what_the_spec_says() -> void:
	assert_eq(BOOMERANG.at_level(2).count, 2, "L2: a second boomerang")
	assert_gt(BOOMERANG.at_level(3).damage, BOOMERANG.at_level(2).damage, "L3: more damage")
	assert_gt(BOOMERANG.at_level(4).reach, BOOMERANG.at_level(3).reach, "L4: more range")
	assert_lt(BOOMERANG.at_level(5).cooldown, BOOMERANG.at_level(4).cooldown, "L5: faster")


func test_levels_never_get_worse() -> void:
	for level: int in range(2, 6):
		var before: WeaponLevel = BOOMERANG.at_level(level - 1)
		var after: WeaponLevel = BOOMERANG.at_level(level)
		assert_true(after.damage >= before.damage, "damage at L%d" % level)
		assert_true(after.cooldown <= before.cooldown, "cooldown at L%d" % level)
		assert_true(after.reach >= before.reach, "range at L%d" % level)
		assert_true(after.count >= before.count, "count at L%d" % level)


func test_at_level_clamps() -> void:
	assert_eq(BOOMERANG.at_level(0), BOOMERANG.at_level(1))
	assert_eq(BOOMERANG.at_level(99), BOOMERANG.at_level(5))


func test_sniper_level_one_matches_the_spec() -> void:
	var sniper: WeaponStats = load("res://data/weapons/sewing_pin_sniper.tres")
	var first: WeaponLevel = sniper.at_level(1)
	assert_eq(sniper.max_level(), 5)
	assert_eq(first.damage, 15.0)
	assert_eq(first.cooldown, 1.2)
	assert_eq(first.pierce, 2)


func test_ac9_sniper_levels_add_what_their_cards_say() -> void:
	var sniper: WeaponStats = load("res://data/weapons/sewing_pin_sniper.tres")
	assert_gt(sniper.at_level(2).damage, sniper.at_level(1).damage, "L2: more damage")
	assert_gt(sniper.at_level(3).pierce, sniper.at_level(2).pierce, "L3: more pierce")
	assert_lt(sniper.at_level(4).cooldown, sniper.at_level(3).cooldown, "L4: faster")
	assert_eq(sniper.at_level(5).count, 2, "L5: two pins")
	assert_string_contains(sniper.at_level(3).card_text, "4")
	assert_string_contains(sniper.at_level(4).card_text, "0.9")
