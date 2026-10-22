extends GutTest
## Spec 02 §7: reroll / skip / banish counts and banished cards (AC-10, AC-12).

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids(offers: Array[UpgradeOffer]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for offer: UpgradeOffer in offers:
		ids.append(offer.upgrade.id)
	return ids


func test_counts_per_run_come_from_data() -> void:
	assert_eq(POOL.rerolls_per_run, 3)
	assert_eq(POOL.skips_per_run, 3)
	assert_eq(POOL.banishes_per_run, 2)
	assert_gt(POOL.skip_heal, 0.0, "a skip heals a little")
	var controls: CardControls = CardControls.new(POOL)
	assert_eq(controls.rerolls_left, 3)
	assert_eq(controls.skips_left, 3)
	assert_eq(controls.banishes_left, 2)


func test_ac10_rerolls_run_out() -> void:
	var controls: CardControls = CardControls.new(POOL)
	for used: int in 3:
		assert_true(controls.use_reroll(), "reroll %d works" % (used + 1))
	assert_eq(controls.rerolls_left, 0)
	assert_false(controls.use_reroll(), "no reroll with 0 left")
	assert_eq(controls.rerolls_left, 0, "never below 0")


func test_ac11_skips_run_out() -> void:
	var controls: CardControls = CardControls.new(POOL)
	for used: int in 3:
		assert_true(controls.use_skip())
	assert_false(controls.use_skip(), "no skip with 0 left")
	assert_eq(controls.skips_left, 0)


func test_ac12_banishes_run_out_and_remember_the_card() -> void:
	var controls: CardControls = CardControls.new(POOL)
	assert_true(controls.banish(&"quick_feet"))
	assert_false(controls.banish(&"quick_feet"), "banishing twice uses nothing")
	assert_eq(controls.banishes_left, 1)
	assert_true(controls.banish(&"thick_felt"))
	assert_false(controls.banish(&"big_spool"), "no banish with 0 left")
	assert_eq(controls.banished, [&"quick_feet", &"thick_felt"] as Array[StringName])


func test_ac12_a_banished_card_is_never_offered() -> void:
	var banished: Array[StringName] = [&"peel_boomerang", &"quick_feet"]
	for seed_value: int in range(1, 200):
		var levels: Dictionary[StringName, int] = {&"peel_boomerang": 1}
		var offers: Array[UpgradeOffer] = POOL.roll(levels, _rng(seed_value), banished)
		var ids: Array[StringName] = _ids(offers)
		assert_does_not_have(ids, &"peel_boomerang")
		assert_does_not_have(ids, &"quick_feet")


func test_ac12_banished_card_stays_out_even_when_cards_run_short() -> void:
	var levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeDef in POOL.upgrades:
		if upgrade.id != &"magnet_pocket":
			levels[upgrade.id] = upgrade.top_level()
	var offers: Array[UpgradeOffer] = POOL.roll(levels, _rng(1), [&"magnet_pocket"])
	var snacks: Array[StringName] = [&"banana_snack", &"banana_snack", &"banana_snack"]
	assert_eq(_ids(offers), snacks)


func test_ac10_reroll_avoids_the_cards_it_replaces() -> void:
	for seed_value: int in range(1, 60):
		var first: Array[StringName] = _ids(POOL.roll({}, _rng(seed_value)))
		var rerolled: Array[StringName] = _ids(POOL.roll({}, _rng(seed_value + 1000), [], first))
		assert_eq(rerolled.size(), 3)
		for id: StringName in first:
			assert_does_not_have(rerolled, id, "a reroll shows new cards")


func test_ac10_reroll_repeats_cards_rather_than_offering_snacks() -> void:
	var keep: Array[StringName] = [&"magnet_pocket", &"quick_feet", &"big_spool", &"thick_felt"]
	var levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeDef in POOL.upgrades:
		if not keep.has(upgrade.id):
			levels[upgrade.id] = upgrade.top_level()
	var avoid: Array[StringName] = [&"magnet_pocket", &"quick_feet", &"big_spool"]
	var ids: Array[StringName] = _ids(POOL.roll(levels, _rng(4), [], avoid))
	assert_eq(ids[0], &"thick_felt", "the one fresh card comes first")
	assert_does_not_have(ids, &"banana_snack", "old cards fill up before snacks")


func test_one_card_can_be_drawn() -> void:
	var offers: Array[UpgradeOffer] = POOL.roll({}, _rng(2), [], [], 1)
	assert_eq(offers.size(), 1)


func test_ac23_used_counts_for_the_run_log() -> void:
	var controls: CardControls = CardControls.new(POOL)
	controls.use_reroll()
	controls.use_reroll()
	controls.use_skip()
	controls.banish(&"quick_feet")
	controls.banish(&"quick_feet")
	assert_eq(controls.rerolls_used, 2)
	assert_eq(controls.skips_used, 1)
	assert_eq(controls.banishes_used, 1, "a failed banish is not counted")


func test_ac22_refill_restores_the_counts_but_keeps_what_was_used() -> void:
	var controls: CardControls = CardControls.new(POOL)
	for i: int in 5:
		controls.use_reroll()
	controls.refill()
	assert_eq(controls.rerolls_left, POOL.rerolls_per_run)
	assert_eq(controls.rerolls_used, POOL.rerolls_per_run, "only the real uses")
	assert_true(controls.use_reroll(), "usable again")
