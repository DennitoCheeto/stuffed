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
	levels[&"magnet_pocket"] = 1
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


func test_pool_has_the_eight_m2_items() -> void:
	var items: Array[StringName] = []
	for upgrade: UpgradeDef in POOL.upgrades:
		if upgrade.kind == UpgradeDef.Kind.ITEM:
			items.append(upgrade.id)
			assert_eq(upgrade.max_level, 5, "%s has 5 levels" % upgrade.id)
			assert_ne(upgrade.card_text, "", "%s has a card line" % upgrade.id)
			assert_gt(upgrade.amount, 0.0, "%s does something" % upgrade.id)
	for id: StringName in [&"sharp_scissors", &"long_thread", &"big_spool", &"thick_felt"]:
		assert_has(items, id)
	assert_eq(items.size(), 8)


func test_slot_counts_live_in_the_pool_data() -> void:
	assert_eq(POOL.max_weapons, 6)
	assert_eq(POOL.max_items, 6)


## A pool with `weapons` fake weapons and `items` fake items (ids w0.. and i0..), weight 1.
func _big_pool(weapons: int, items: int) -> UpgradePool:
	var pool: UpgradePool = UpgradePool.new()
	pool.snack = POOL.snack
	var weapon_stats: WeaponStats = POOL.find(&"peel_boomerang").weapon
	for i: int in weapons:
		var weapon: UpgradeDef = UpgradeDef.new()
		weapon.id = StringName("w%d" % i)
		weapon.kind = UpgradeDef.Kind.WEAPON
		weapon.weapon = weapon_stats
		pool.upgrades.append(weapon)
	for i: int in items:
		var item: UpgradeDef = UpgradeDef.new()
		item.id = StringName("i%d" % i)
		item.kind = UpgradeDef.Kind.ITEM
		pool.upgrades.append(item)
	return pool


func _owning(prefix: String, count: int, level: int) -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = {}
	for i: int in count:
		levels[StringName("%s%d" % [prefix, i])] = level
	return levels


func test_ac4_full_weapon_slots_offer_only_owned_weapons() -> void:
	var pool: UpgradePool = _big_pool(10, 0)
	var levels: Dictionary[StringName, int] = _owning("w", 6, 1)
	for seed_value: int in range(1, 60):
		for id: StringName in _ids(pool.roll(levels, _rng(seed_value))):
			assert_true(levels.has(id), "%s is owned" % id)


func test_ac4_full_item_slots_offer_only_owned_items() -> void:
	var pool: UpgradePool = _big_pool(0, 10)
	var levels: Dictionary[StringName, int] = _owning("i", 6, 2)
	for seed_value: int in range(1, 60):
		for id: StringName in _ids(pool.roll(levels, _rng(seed_value))):
			assert_true(levels.has(id), "%s is owned" % id)


func test_ac4_five_weapons_still_get_new_weapons() -> void:
	var pool: UpgradePool = _big_pool(10, 0)
	var levels: Dictionary[StringName, int] = _owning("w", 5, 1)
	var saw_new: bool = false
	for seed_value: int in range(1, 60):
		for id: StringName in _ids(pool.roll(levels, _rng(seed_value))):
			saw_new = saw_new or not levels.has(id)
	assert_true(saw_new, "a sixth weapon can still be offered")


func test_ac4_full_weapons_do_not_block_new_items() -> void:
	var pool: UpgradePool = _big_pool(8, 8)
	var levels: Dictionary[StringName, int] = _owning("w", 6, 1)
	var saw_new_item: bool = false
	for seed_value: int in range(1, 60):
		for id: StringName in _ids(pool.roll(levels, _rng(seed_value))):
			assert_true(levels.has(id) or String(id).begins_with("i"), "%s: no new weapon" % id)
			saw_new_item = saw_new_item or String(id).begins_with("i")
	assert_true(saw_new_item)


func test_ac4_full_and_maxed_slots_give_snacks() -> void:
	var pool: UpgradePool = _big_pool(8, 8)
	var levels: Dictionary[StringName, int] = _owning("w", 6, 5)
	levels.merge(_owning("i", 6, 5))
	assert_eq(_ids(pool.roll(levels, _rng(4))), [&"banana_snack", &"banana_snack", &"banana_snack"])


func test_card_weights_change_the_odds() -> void:
	var pool: UpgradePool = _big_pool(0, 4)
	pool.cards_per_level_up = 1
	pool.upgrades[0].weight = 7.0
	pool.upgrades[3].weight = 0.0
	var counts: Dictionary[StringName, int] = {}
	for seed_value: int in range(1, 401):
		var id: StringName = _ids(pool.roll({}, _rng(seed_value)))[0]
		counts[id] = counts.get(id, 0) + 1
	assert_false(counts.has(&"i3"), "weight 0 is never offered")
	assert_gt(counts.get(&"i0", 0), 250, "weight 7 out of 9 shows up most of the time")
	assert_gt(counts.get(&"i1", 0), 10, "the others still show up")
