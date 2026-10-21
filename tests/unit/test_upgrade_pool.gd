extends GutTest

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


func _all_maxed_except(keep: Array[StringName]) -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for upgrade: UpgradeDef in POOL.upgrades:
		if not keep.has(upgrade.id):
			levels[upgrade.id] = upgrade.top_level()
	return levels


func test_three_different_cards() -> void:
	for seed_value: int in range(1, 40):
		var ids: Array[StringName] = _ids(POOL.roll({&"peel_boomerang": 1}, _rng(seed_value)))
		assert_eq(ids.size(), 3)
		assert_ne(ids[0], ids[1])
		assert_ne(ids[1], ids[2])
		assert_ne(ids[0], ids[2])


func test_ac19_maxed_upgrades_are_not_offered() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 5, &"quick_feet": 5}
	for seed_value: int in range(1, 40):
		var ids: Array[StringName] = _ids(POOL.roll(levels, _rng(seed_value)))
		assert_does_not_have(ids, &"peel_boomerang")
		assert_does_not_have(ids, &"quick_feet")


func test_ac19_banana_snack_fills_missing_slots() -> void:
	var levels: Dictionary[StringName, int] = _all_maxed_except([&"magnet_pocket"])
	var offers: Array[UpgradeOffer] = POOL.roll(levels, _rng(3))
	assert_eq(_ids(offers), [&"magnet_pocket", &"banana_snack", &"banana_snack"])


func test_ac19_everything_maxed_gives_three_snacks() -> void:
	var offers: Array[UpgradeOffer] = POOL.roll(_all_maxed_except([]), _rng(3))
	assert_eq(_ids(offers), [&"banana_snack", &"banana_snack", &"banana_snack"])


func test_card_texts() -> void:
	var levels: Dictionary[StringName, int] = _all_maxed_except([&"peel_boomerang", &"quick_feet"])
	levels[&"peel_boomerang"] = 1
	var offers: Array[UpgradeOffer] = POOL.roll(levels, _rng(5))
	for offer: UpgradeOffer in offers:
		match offer.upgrade.id:
			&"peel_boomerang":
				assert_eq(offer.level_text(), "Lv 1 → 2")
				assert_eq(offer.description(), "Throws 2 peels at once.")
			&"quick_feet":
				assert_eq(offer.level_text(), "New!")
				assert_eq(offer.description(), "Move speed +10%.")
			&"banana_snack":
				assert_eq(offer.level_text(), "")


func test_same_seed_same_cards() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 1}
	for seed_value: int in [7, 99, 12345]:
		assert_eq(
			_ids(POOL.roll(levels, _rng(seed_value))), _ids(POOL.roll(levels, _rng(seed_value)))
		)


func test_pool_has_the_m1_boosts() -> void:
	var ids: Array[StringName] = []
	for upgrade: UpgradeDef in POOL.upgrades:
		ids.append(upgrade.id)
	for id: StringName in [&"quick_feet", &"extra_stuffing", &"magnet_pocket", &"quick_hands"]:
		assert_has(ids, id)
	assert_eq(POOL.snack.amount, 0.3, "Banana Snack heals 30%")
