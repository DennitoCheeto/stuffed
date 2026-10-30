extends GutTest
## Lucky Jar rules (spec 06 §3.1): a shiny card gives 2 levels, never shines on the snack or one
## level from max, and says so on its level tag. With Lucky Gift a box gives 2-4 level-ups, and
## the gift box screen narrows its cards when 6 share the row.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const RULES: GiftBoxRules = preload("res://data/gift_box_rules.tres")
const LUCKY_GIFT: TrickDef = preload("res://data/town/tricks/lucky_gift.tres")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_shiny_card_gives_two_levels() -> void:
	var quick_feet: UpgradeDef = POOL.find(&"quick_feet")
	var offer: UpgradeOffer = UpgradeOffer.new(quick_feet, 2)
	assert_eq(offer.levels(), 1)
	assert_eq(offer.level_text(), "Lv 1 → 2")
	offer.shiny = true
	assert_eq(offer.levels(), UpgradeOffer.SHINY_LEVELS)
	assert_eq(offer.reached_level(), 3)
	assert_eq(offer.level_text(), "Lv 1 → 3")


func test_a_new_shiny_card_starts_at_lv_2() -> void:
	var offer: UpgradeOffer = UpgradeOffer.new(POOL.find(&"big_spool"), 1)
	offer.shiny = true
	assert_eq(offer.level_text(), "New! Lv 2")


func test_never_shiny_one_level_from_max_or_on_the_snack() -> void:
	var quick_feet: UpgradeDef = POOL.find(&"quick_feet")
	var top: int = quick_feet.top_level()
	assert_true(UpgradeOffer.new(quick_feet, top - 1).can_shine(), "room for 2 levels")
	assert_false(UpgradeOffer.new(quick_feet, top).can_shine(), "one level from max")
	assert_false(UpgradeOffer.new(POOL.snack, 1).can_shine(), "the snack")
	var sniper: UpgradeDef = POOL.find(&"sewing_pin_sniper")
	assert_true(UpgradeOffer.new(sniper, 1).can_shine(), "a new weapon")
	assert_false(UpgradeOffer.new(sniper, sniper.top_level()).can_shine())


func test_lucky_gift_boxes_give_two_to_four_level_ups() -> void:
	var levels: Dictionary[StringName, int] = {&"peel_boomerang": 1, &"quick_feet": 1}
	var seen: Dictionary[int, bool] = {}
	for seed_value: int in 200:
		var extra: int = int(LUCKY_GIFT.amount)
		var gift: GiftContents = RULES.contents(levels, POOL, _rng(seed_value), extra)
		var count: int = gift.level_ups.size()
		assert_between(count, 2, 4, "seed %d" % seed_value)
		seen[count] = true
	assert_eq(seen.size(), 3, "2, 3 and 4 all come up: %s" % [seen.keys()])


func test_gift_cards_keep_their_width_up_to_five_and_narrow_for_six() -> void:
	for count: int in range(1, 6):
		assert_eq(GiftBoxScreen.card_width(count), GiftCardView.CARD_SIZE.x, "%d cards" % count)
	var six: float = GiftBoxScreen.card_width(6)
	assert_lt(six, GiftCardView.CARD_SIZE.x)
	var row: float = six * 6 + GiftBoxScreen.CARD_GAP * 5
	assert_true(row <= GiftBoxScreen.ROW_WIDTH, "6 cards fit the row (%d px)" % row)
