extends GutTest
## Gift box contents (spec 02 §6, AC-8): without anything to evolve, a box gives 1-3 level-ups of
## things the player already has; if everything is maxed, a big heal.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const RULES: GiftBoxRules = preload("res://data/gift_box_rules.tres")
const SEEDS: int = 200


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## The same upgrades, all at their top level.
func _all_maxed(levels: Dictionary[StringName, int]) -> Dictionary[StringName, int]:
	var maxed: Dictionary[StringName, int] = {}
	for id: StringName in levels:
		maxed[id] = POOL.find(id).top_level()
	return maxed


func test_ac8_one_to_three_level_ups_of_owned_things_only() -> void:
	var levels: Dictionary[StringName, int] = {
		&"peel_boomerang": 2, &"orbiting_needles": 1, &"quick_feet": 3, &"thick_felt": 1
	}
	var counts: Array[int] = [0, 0, 0, 0]
	for seed_value: int in SEEDS:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		assert_false(gift.is_heal(), "something to level up, so no heal")
		assert_eq(gift.heal_share, 0.0)
		assert_between(gift.level_ups.size(), 1, 3)
		counts[gift.level_ups.size()] += 1
		for offer: UpgradeOffer in gift.level_ups:
			assert_true(levels.has(offer.upgrade.id), "%s is owned" % offer.upgrade.id)
			assert_ne(offer.upgrade.kind, UpgradeDef.Kind.SNACK)
	assert_gt(counts[1], 0, "sometimes one")
	assert_gt(counts[2], 0, "sometimes two")
	assert_gt(counts[3], 0, "sometimes three")
	assert_gt(counts[1], counts[3], "one is more common than three")


func test_ac8_level_ups_continue_from_the_current_level() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 2, &"quick_feet": 3}
	for seed_value: int in SEEDS:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		var reached: Dictionary[StringName, int] = levels.duplicate()
		for offer: UpgradeOffer in gift.level_ups:
			assert_eq(offer.next_level, reached[offer.upgrade.id] + 1)
			reached[offer.upgrade.id] = offer.next_level


func test_ac8_different_things_while_possible() -> void:
	var levels: Dictionary[StringName, int] = {
		&"peel_boomerang": 1, &"zipper_ray": 1, &"big_spool": 1, &"quick_hands": 1
	}
	for seed_value: int in SEEDS:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		var ids: Array[StringName] = []
		for offer: UpgradeOffer in gift.level_ups:
			assert_does_not_have(ids, offer.upgrade.id, "no repeats with 4 to choose from")
			ids.append(offer.upgrade.id)


func test_ac8_never_past_the_top_level() -> void:
	# Only one level left anywhere: a box can give just that one. (Thick Felt is nobody's
	# evolution partner, so nothing evolves here.)
	var levels: Dictionary[StringName, int] = _all_maxed({&"peel_boomerang": 0, &"thick_felt": 0})
	levels[&"thick_felt"] = 4
	for seed_value: int in SEEDS:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		assert_eq(gift.level_ups.size(), 1)
		assert_eq(gift.level_ups[0].upgrade.id, &"thick_felt")
		assert_eq(gift.level_ups[0].next_level, 5)


func test_ac8_the_same_thing_twice_when_it_is_the_only_one() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 1}
	var saw_two: bool = false
	for seed_value: int in SEEDS:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		for index: int in gift.level_ups.size():
			assert_eq(gift.level_ups[index].next_level, 2 + index, "Lv 2, then 3, then 4")
		saw_two = saw_two or gift.level_ups.size() >= 2
	assert_true(saw_two, "more than one level-up of the only weapon")


func test_ac8_everything_maxed_gives_a_big_heal() -> void:
	var levels: Dictionary[StringName, int] = _all_maxed(
		{&"peel_boomerang": 0, &"zipper_ray": 0, &"magnet_pocket": 0, &"thick_felt": 0}
	)
	for seed_value: int in 20:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		assert_true(gift.is_heal())
		assert_eq(gift.level_ups.size(), 0)
		assert_eq(gift.heal_share, RULES.heal_share)
	assert_gte(RULES.heal_share, 0.3, "a big heal")
	assert_gt(RULES.heal_share, POOL.skip_heal, "bigger than a skip")


func test_ac27_heal_card_shows_the_amount() -> void:
	var gift: GiftContents = GiftContents.new()
	gift.heal_share = 0.5
	gift.heal_amount = 60.0
	var cards: Array[GiftCard] = gift.cards()
	assert_eq(cards.size(), 1)
	assert_eq(cards[0].title, "Big heal!")
	assert_eq(cards[0].level_text, "+60 health")
	assert_eq(cards[0].icon, GiftContents.HEAL_ICON)


func test_ac27_one_card_per_level_up_with_icon_name_and_level() -> void:
	var gift: GiftContents = GiftContents.new()
	var boomerang: UpgradeDef = POOL.find(&"peel_boomerang")
	gift.level_ups.append(UpgradeOffer.new(boomerang, 3))
	gift.level_ups.append(UpgradeOffer.new(boomerang, 4))
	var cards: Array[GiftCard] = gift.cards()
	assert_eq(cards.size(), 2, "one card each, even for the same upgrade")
	assert_eq(cards[0].icon, boomerang.icon)
	assert_eq(cards[0].title, "Peel Boomerang")
	assert_eq(cards[0].level_text, "Lv 2 → 3")
	assert_eq(cards[1].level_text, "Lv 3 → 4")
	assert_false(cards[0].is_evolution())


func test_count_follows_the_weights() -> void:
	var rules: GiftBoxRules = GiftBoxRules.new()
	rules.level_up_weights = PackedFloat32Array([0.0, 1.0, 0.0])
	for seed_value: int in 20:
		assert_eq(rules.roll_count(_rng(seed_value)), 2)


func test_opening_is_about_one_second_and_confirm_waits_a_moment() -> void:
	assert_between(RULES.opening_seconds, 0.7, 1.3, "spec 02 §20: about 1 second")
	assert_lt(RULES.skip_delay, RULES.opening_seconds)
	assert_almost_eq(RULES.confirm_delay, 0.5, 0.05, "spec 02 §20: 0.5 s before confirming")


func test_the_boss_big_box_gives_more() -> void:
	assert_gt(RULES.big_box_extra_level_ups, 0, "spec 02 §6: more from the boss's box")
	assert_gt(RULES.big_box_scale, 1.0, "and it looks bigger")
	var levels: Dictionary[StringName, int] = {
		&"peel_boomerang": 1, &"orbiting_needles": 1, &"quick_feet": 1, &"thick_felt": 1
	}
	var extra: int = RULES.big_box_extra_level_ups
	for seed_value: int in SEEDS:
		var normal: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		var big: GiftContents = RULES.contents(levels, POOL, _rng(seed_value), extra)
		assert_eq(big.level_ups.size(), normal.level_ups.size() + extra)
