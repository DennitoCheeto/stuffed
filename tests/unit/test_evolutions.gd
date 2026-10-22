extends GutTest
## Evolutions (spec 02 §5, AC-7, AC-9, AC-24): which pairs evolve, when an evolution is ready,
## that a gift box gives it, and that an evolved weapon is never offered again.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const RULES: GiftBoxRules = preload("res://data/gift_box_rules.tres")
## Spec 02 §5: evolved weapon id → [weapon, partner item].
const RECIPES: Dictionary[StringName, Array] = {
	&"banana_split": [&"peel_boomerang", &"quick_feet"],
	&"sewing_storm": [&"orbiting_needles", &"long_thread"],
	&"pincushion_volley": [&"sewing_pin_sniper", &"sharp_scissors"],
	&"yarn_bomb": [&"yarn_cannon", &"big_spool"],
}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _evolution(evolved_id: StringName) -> EvolutionDef:
	return POOL.evolution_into(evolved_id)


func test_ac7_the_four_recipes_of_the_spec() -> void:
	assert_eq(POOL.evolutions.size(), 4)
	for evolved_id: StringName in RECIPES:
		var evolution: EvolutionDef = _evolution(evolved_id)
		assert_not_null(evolution, String(evolved_id))
		assert_eq(evolution.weapon, RECIPES[evolved_id][0])
		assert_eq(evolution.partner, RECIPES[evolved_id][1])
		assert_eq(POOL.find(evolution.weapon).kind, UpgradeDef.Kind.WEAPON)
		assert_eq(POOL.find(evolution.partner).kind, UpgradeDef.Kind.ITEM)
		assert_ne(evolution.icon, &"", "has an icon")
		assert_ne(evolution.card_text, "", "says what changes")


func test_ac24_evolved_weapons_live_in_data() -> void:
	for evolution: EvolutionDef in POOL.evolutions:
		var evolved: WeaponStats = evolution.evolved
		assert_eq(evolved.evolved_from, evolution.weapon)
		assert_eq(evolved.max_level(), 1, "one level: it is already the top")
		assert_not_null(evolved.behaviour)
		assert_null(POOL.find(evolved.id), "never offered as a card")


func test_ac7_evolved_weapons_are_clearly_stronger() -> void:
	for evolution: EvolutionDef in POOL.evolutions:
		var base: WeaponStats = POOL.find(evolution.weapon).weapon
		var top: WeaponLevel = base.at_level(base.max_level())
		var evolved: WeaponLevel = evolution.evolved.at_level(1)
		var weapon_name: String = evolution.display_name()
		assert_gt(evolved.damage, top.damage, "%s hits harder" % weapon_name)
		assert_gte(evolved.count, top.count, "%s has at least as many shots" % weapon_name)
		assert_lte(evolved.cooldown, top.cooldown, "%s is not slower" % weapon_name)


func test_ac7_pincushion_volley_has_no_pierce_limit() -> void:
	assert_lt(_evolution(&"pincushion_volley").evolved.at_level(1).pierce, 0)
	assert_gt(_evolution(&"pincushion_volley").evolved.at_level(1).count, 4, "a fan")


func test_ac7_yarn_bomb_slows_and_hurts() -> void:
	var bomb: WeaponStats = _evolution(&"yarn_bomb").evolved
	assert_between(bomb.slow, 0.2, 0.9)
	assert_gt(bomb.linger_damage, 0.0)
	assert_gt(bomb.at_level(1).duration, 1.0, "the sticky yarn stays a while")


func test_ac7_ready_with_a_top_level_weapon_and_its_partner() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 5, &"quick_feet": 1}
	assert_eq(POOL.ready_evolution(levels), _evolution(&"banana_split"))


func test_not_ready_below_the_top_level() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 4, &"quick_feet": 5}
	assert_null(POOL.ready_evolution(levels))


func test_not_ready_without_the_partner() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 5, &"long_thread": 5}
	assert_null(POOL.ready_evolution(levels), "Long Thread is not the boomerang's partner")


func test_not_ready_twice() -> void:
	var levels: Dictionary[StringName, int] = {
		&"peel_boomerang": Player.EVOLVED_LEVEL, &"banana_split": 1, &"quick_feet": 1
	}
	assert_null(POOL.ready_evolution(levels))


func test_ac7_a_gift_box_with_a_ready_weapon_evolves_it() -> void:
	var levels: Dictionary[StringName, int] = {
		&"yarn_cannon": 5, &"big_spool": 2, &"peel_boomerang": 1
	}
	for seed_value: int in 20:
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		assert_true(gift.is_evolution())
		assert_eq(gift.evolution, _evolution(&"yarn_bomb"))
		assert_eq(gift.level_ups.size(), 0, "the evolution is the whole gift")
		assert_false(gift.is_heal())
		var cards: Array[GiftCard] = gift.cards()
		assert_eq(cards.size(), 1, "one evolution card")
		assert_true(cards[0].is_evolution())
		assert_eq(cards[0].from_name, "Yarn Cannon")
		assert_eq(cards[0].from_icon, POOL.find(&"yarn_cannon").icon, "old weapon ...")
		assert_eq(cards[0].icon, _evolution(&"yarn_bomb").icon, "... → new weapon")
		assert_eq(cards[0].title, "Yarn Bomb")
		assert_eq(cards[0].text, _evolution(&"yarn_bomb").card_text)


func test_ac9_weapon_cards_carry_their_partner() -> void:
	assert_eq(POOL.partner_of(POOL.find(&"sewing_pin_sniper")), POOL.find(&"sharp_scissors"))
	assert_null(POOL.partner_of(POOL.find(&"quick_feet")), "items have no partner")
	assert_null(POOL.partner_of(POOL.find(&"thread_whip")), "no evolution yet, no partner shown")
	for seed_value: int in 30:
		for offer: UpgradeOffer in POOL.roll({&"peel_boomerang": 1}, _rng(seed_value)):
			assert_eq(offer.partner, POOL.partner_of(offer.upgrade))


func test_an_evolved_weapon_is_never_offered_or_levelled_again() -> void:
	var levels: Dictionary[StringName, int] = {
		&"peel_boomerang": Player.EVOLVED_LEVEL, &"banana_split": 1, &"quick_feet": 1
	}
	for seed_value: int in 50:
		for offer: UpgradeOffer in POOL.roll(levels, _rng(seed_value)):
			assert_ne(offer.upgrade.id, &"peel_boomerang")
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value))
		for offer: UpgradeOffer in gift.level_ups:
			assert_eq(offer.upgrade.id, &"quick_feet", "only the item can level up")
