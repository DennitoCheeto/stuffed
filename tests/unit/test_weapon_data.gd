extends GutTest

const BOOMERANG: WeaponStats = preload("res://data/weapons/peel_boomerang.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const NEEDLES: WeaponStats = preload("res://data/weapons/orbiting_needles.tres")
const SHOTGUN: WeaponStats = preload("res://data/weapons/button_shotgun.tres")
const CLOUD: WeaponStats = preload("res://data/weapons/stuffing_cloud.tres")
const YARN: WeaponStats = preload("res://data/weapons/bouncy_yarn_ball.tres")
const MORTAR: WeaponStats = preload("res://data/weapons/thimble_mortar.tres")


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
	var first: WeaponLevel = SNIPER.at_level(1)
	assert_eq(SNIPER.max_level(), 5)
	assert_eq(first.damage, 15.0)
	assert_eq(first.cooldown, 1.2)
	assert_eq(first.pierce, 2)


func test_ac9_sniper_levels_add_what_their_cards_say() -> void:
	assert_gt(SNIPER.at_level(2).damage, SNIPER.at_level(1).damage, "L2: more damage")
	assert_gt(SNIPER.at_level(3).pierce, SNIPER.at_level(2).pierce, "L3: more pierce")
	assert_lt(SNIPER.at_level(4).cooldown, SNIPER.at_level(3).cooldown, "L4: faster")
	assert_eq(SNIPER.at_level(5).count, 2, "L5: two pins")
	assert_string_contains(SNIPER.at_level(3).card_text, "4")
	assert_string_contains(SNIPER.at_level(4).card_text, "0.9")


func _assert_never_worse(weapon: WeaponStats) -> void:
	assert_eq(weapon.max_level(), 5, "%s has 5 levels" % weapon.id)
	for level: int in range(1, 6):
		assert_ne(weapon.at_level(level).card_text, "", "%s L%d card" % [weapon.id, level])
	for level: int in range(2, 6):
		var before: WeaponLevel = weapon.at_level(level - 1)
		var after: WeaponLevel = weapon.at_level(level)
		var label: String = "%s L%d" % [weapon.id, level]
		assert_true(after.damage >= before.damage, "damage at " + label)
		assert_true(after.cooldown <= before.cooldown, "cooldown at " + label)
		assert_true(after.reach >= before.reach, "range at " + label)
		assert_true(after.count >= before.count, "count at " + label)
		assert_true(after.pierce >= before.pierce, "pierce at " + label)
		assert_true(after.duration >= before.duration, "duration at " + label)
		assert_true(after.area >= before.area, "area at " + label)


func test_ac2_needles_levels_add_what_their_cards_say() -> void:
	_assert_never_worse(NEEDLES)
	assert_eq(NEEDLES.at_level(1).count, 2)
	assert_gt(NEEDLES.at_level(1).duration, 0.0, "needles stay out for a while")
	assert_eq(NEEDLES.at_level(2).count, 3, "L2: 3 needles")
	assert_eq(NEEDLES.at_level(3).damage, 9.0, "L3: damage 6 → 9")
	assert_eq(NEEDLES.at_level(4).duration, 4.0, "L4: 3 → 4 seconds")
	assert_eq(NEEDLES.at_level(5).count, 4, "L5: 4 needles")
	assert_string_contains(NEEDLES.at_level(3).card_text, "6 → 9")
	assert_string_contains(NEEDLES.at_level(4).card_text, "3 → 4")


func test_ac2_shotgun_levels_add_what_their_cards_say() -> void:
	_assert_never_worse(SHOTGUN)
	assert_eq(SHOTGUN.at_level(1).count, 3)
	assert_gt(SHOTGUN.knockback, BOOMERANG.knockback, "pushes harder than the boomerang")
	assert_lt(SHOTGUN.at_level(1).reach, SNIPER.at_level(1).reach, "short range")
	assert_eq(SHOTGUN.at_level(2).count, 5, "L2: 5 buttons")
	assert_eq(SHOTGUN.at_level(3).damage, 9.0, "L3: damage 6 → 9")
	assert_eq(SHOTGUN.at_level(4).pierce, 1, "L4: goes through 1 zombie")
	assert_eq(SHOTGUN.at_level(5).count, 7, "L5: 7 buttons")
	assert_eq(SHOTGUN.at_level(5).cooldown, 1.2, "L5: faster")


func test_ac2_cloud_levels_add_what_their_cards_say() -> void:
	_assert_never_worse(CLOUD)
	assert_gt(CLOUD.at_level(1).area, 0.0, "the cloud has a size")
	assert_lt(CLOUD.at_level(1).cooldown, 0.5, "it hurts a few times a second")
	assert_gt(CLOUD.at_level(2).area, CLOUD.at_level(1).area, "L2: bigger cloud")
	assert_eq(CLOUD.at_level(3).damage, 5.0, "L3: damage 3 → 5")
	assert_eq(CLOUD.at_level(4).cooldown, 0.3, "L4: puffs every 0.3 seconds")
	assert_gt(CLOUD.at_level(5).area, CLOUD.at_level(4).area, "L5: even bigger")
	assert_eq(CLOUD.at_level(5).damage, 6.0, "L5: damage 5 → 6")
	assert_string_contains(CLOUD.at_level(3).card_text, "3 → 5")
	assert_string_contains(CLOUD.at_level(4).card_text, "0.4 → 0.3")


func test_ac2_yarn_levels_add_what_their_cards_say() -> void:
	_assert_never_worse(YARN)
	var first: WeaponLevel = YARN.at_level(1)
	assert_eq(first.pierce + 1, 4, "L1: bounces between 4 zombies")
	assert_gt(first.duration, 0.0, "a ball doesn't bounce forever")
	assert_eq(YARN.at_level(2).pierce + 1, 6, "L2: 6 zombies")
	assert_eq(YARN.at_level(3).damage, 12.0, "L3: damage 8 → 12")
	assert_eq(YARN.at_level(4).count, 2, "L4: 2 balls")
	assert_eq(YARN.at_level(5).pierce + 1, 8, "L5: 8 zombies")
	assert_eq(YARN.at_level(5).cooldown, 1.6, "L5: faster")
	assert_string_contains(first.card_text, "4 zombies")
	assert_string_contains(YARN.at_level(2).card_text, "6 zombies")
	assert_string_contains(YARN.at_level(5).card_text, "8 zombies")


func test_ac2_mortar_levels_add_what_their_cards_say() -> void:
	_assert_never_worse(MORTAR)
	assert_eq(MORTAR.at_level(1).count, 1)
	assert_gt(MORTAR.at_level(1).area, 0.0, "it lands with an area hit")
	assert_eq(MORTAR.at_level(2).count, 2, "L2: 2 thimbles")
	assert_gt(MORTAR.at_level(3).area, MORTAR.at_level(2).area, "L3: bigger blast")
	assert_eq(MORTAR.at_level(4).damage, 20.0, "L4: damage 14 → 20")
	assert_eq(MORTAR.at_level(5).count, 3, "L5: 3 thimbles")
	assert_eq(MORTAR.at_level(5).cooldown, 2.0, "L5: faster")
	assert_string_contains(MORTAR.at_level(4).card_text, "14 → 20")
