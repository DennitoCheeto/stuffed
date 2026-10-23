extends GutTest
## Lucky Jar, Watchtower and Snack Bar rules (spec 03 §6, AC-43): what each level adds to a run.
## The numbers come from data/town/buildings/*.tres.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const LUCKY_JAR: BuildingDef = preload("res://data/town/buildings/lucky_jar.tres")
const WATCHTOWER: BuildingDef = preload("res://data/town/buildings/watchtower.tres")
const SNACK_BAR: BuildingDef = preload("res://data/town/buildings/snack_bar.tres")


func _perks(levels: Dictionary[String, int]) -> TownPerks:
	var save: TownSave = TownSave.new()
	for id: String in levels:
		save.building_levels[id] = levels[id]
	return TownPerks.from_save(save, LAYOUT)


func test_a_new_save_adds_nothing() -> void:
	var perks: TownPerks = _perks({})
	assert_eq(perks.extra_card_uses, 0)
	assert_eq(perks.pickup_range_bonus, 0.0)
	assert_eq(perks.max_health_bonus, 0.0)


func test_ac43_numbers_per_level_come_from_data() -> void:
	for level: int in [1, 2, 3]:
		assert_eq(LUCKY_JAR.reached(level).extra_card_uses, level, "Lucky Jar Lv %d" % level)
		assert_almost_eq(
			WATCHTOWER.reached(level).pickup_range_bonus, 0.1 * level, 0.001, "Watchtower"
		)
		assert_eq(SNACK_BAR.reached(level).max_health_bonus, 10.0 * level, "Snack Bar")
	assert_null(LUCKY_JAR.reached(0), "a ruin does nothing")


func test_ac43_lucky_jar_adds_its_level_to_each_card_control() -> void:
	for level: int in [1, 2, 3]:
		var perks: TownPerks = _perks({"lucky_jar": level})
		assert_eq(perks.extra_card_uses, level)
		var controls: CardControls = CardControls.new(POOL, perks.extra_card_uses)
		assert_eq(controls.rerolls_left, POOL.rerolls_per_run + level, "rerolls")
		assert_eq(controls.skips_left, POOL.skips_per_run + level, "skips")
		assert_eq(controls.banishes_left, POOL.banishes_per_run + level, "banishes")
		assert_eq(controls.max_rerolls(), POOL.rerolls_per_run + level, "dots on the button")


func test_a_dev_refill_keeps_the_lucky_jar_uses() -> void:
	var controls: CardControls = CardControls.new(POOL, 2)
	controls.use_reroll()
	controls.use_skip()
	controls.refill()
	assert_eq(controls.rerolls_left, POOL.rerolls_per_run + 2)
	assert_eq(controls.skips_left, POOL.skips_per_run + 2)


func test_ac43_watchtower_and_snack_bar_reach_the_perks() -> void:
	var perks: TownPerks = _perks({"watchtower": 2, "snack_bar": 3})
	assert_almost_eq(perks.pickup_range_bonus, 0.2, 0.001)
	assert_eq(perks.max_health_bonus, 30.0)
	assert_eq(perks.extra_card_uses, 0, "the Lucky Jar is still a ruin")


func test_effect_texts_match_the_numbers() -> void:
	assert_eq(WATCHTOWER.effect_at(3), "+30% pickup range")
	assert_eq(SNACK_BAR.effect_at(2), "+20 max health")
	assert_eq(LUCKY_JAR.effect_at(0), "", "a ruin has no effect")
