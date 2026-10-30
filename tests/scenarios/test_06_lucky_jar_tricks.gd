extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, §3.1, AC-69, AC-73): the Lucky Jar's tricks work in a run. Shiny Card:
## sometimes one card shines and gives 2 levels (never the snack, never one level from max).
## Lucky Gift: gift boxes give one more level-up. Four of a Kind: level-ups show 4 cards, and
## key 4, reroll and banish work with them.

const SHINY_CARD: TrickDef = preload("res://data/town/tricks/shiny_card.tres")
const FOUR_OF_A_KIND: TrickDef = preload("res://data/town/tricks/four_of_a_kind.tres")
const GIFT_RULES: GiftBoxRules = preload("res://data/gift_box_rules.tres")

var run: Run


func _quiet_run(tricks: Array[String]) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	disarm(first_player())
	return run


func _open_level_up(hero: Player) -> LevelUpScreen:
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)
	return run.level_up_screen


func _press(action: String) -> void:
	sender.action_down(action)
	await wait_process_frames(2)
	sender.action_up(action)
	await wait_process_frames(2)


## A seed whose first roll lands under `chance` (a lucky level-up for Shiny Card).
func _lucky_seed(chance: float) -> int:
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	for seed_value: int in range(1, 10000):
		probe.seed = seed_value
		if probe.randf() < chance:
			return seed_value
	return 0


func _shiny_offers(screen: LevelUpScreen) -> Array[UpgradeOffer]:
	var shiny: Array[UpgradeOffer] = []
	for offer: UpgradeOffer in screen.offers:
		if offer.shiny:
			shiny.append(offer)
	return shiny


func _level_of(hero: Player, id: StringName) -> int:
	return int(hero.upgrade_levels().get(id, 0))


func test_ac69_shiny_card_gives_two_levels() -> void:
	await _quiet_run(["shiny_card"])
	var banane: Player = first_player()
	run.tricks.rng.seed = _lucky_seed(SHINY_CARD.amount)
	var screen: LevelUpScreen = await _open_level_up(banane)
	var shiny: Array[UpgradeOffer] = _shiny_offers(screen)
	assert_eq(shiny.size(), 1, "one card shines on a lucky level-up")
	if shiny.is_empty():
		return
	var offer: UpgradeOffer = shiny[0]
	var card: UpgradeCard = screen.cards[screen.offers.find(offer)]
	assert_true(card.shiny_tag.visible, "the card says so")
	assert_eq(card.shiny_tag.label.text, "+2 levels")
	assert_true(card.sparkle.visible, "gold sparkle")
	var before: int = _level_of(banane, offer.upgrade.id)
	screen.choose(screen.offers.find(offer))
	await wait_physics_frames(2)
	assert_eq(_level_of(banane, offer.upgrade.id), before + 2, "2 levels at once")
	assert_true(run.tricks.fired(&"shiny_card"), "the banner names it")


func test_ac69_shiny_card_comes_on_about_one_level_up_in_ten() -> void:
	await _quiet_run(["shiny_card"])
	var banane: Player = first_player()
	var lucky: int = 0
	for i: int in 2000:
		run.tricks.start_level_up(banane)
		lucky += 1 if run.tricks.shiny_level_up else 0
	assert_almost_eq(lucky / 2000.0, SHINY_CARD.amount, 0.03, "the chance in data")


func test_ac69_without_the_trick_no_card_shines() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	for i: int in 200:
		run.tricks.start_level_up(banane)
		assert_false(run.tricks.shiny_level_up)
	var screen: LevelUpScreen = await _open_level_up(banane)
	assert_eq(_shiny_offers(screen).size(), 0)


func test_ac69_shiny_never_on_the_snack_or_one_level_from_max() -> void:
	await _quiet_run(["shiny_card"])
	var banane: Player = first_player()
	var pool: UpgradePool = run.upgrade_pool
	var weapon: UpgradeDef = pool.find(&"sewing_pin_sniper")
	var near_max: UpgradeOffer = UpgradeOffer.new(weapon, weapon.top_level())
	var snack: UpgradeOffer = UpgradeOffer.new(pool.snack, 1)
	run.tricks.shiny_level_up = true
	var offers: Array[UpgradeOffer] = [near_max, snack]
	run.tricks.dealt(offers, banane)
	assert_false(near_max.shiny, "one level from max stays a normal card")
	assert_false(snack.shiny, "the snack never shines")
	var fine: UpgradeOffer = UpgradeOffer.new(weapon, weapon.top_level() - 1)
	offers.append(fine)
	run.tricks.dealt(offers, banane)
	assert_true(fine.shiny, "the card with room for 2 levels shines")


func test_ac69_shiny_stays_with_the_level_up_after_a_reroll() -> void:
	await _quiet_run(["shiny_card"])
	var banane: Player = first_player()
	run.tricks.rng.seed = _lucky_seed(SHINY_CARD.amount)
	var screen: LevelUpScreen = await _open_level_up(banane)
	await _press("reroll_cards")
	assert_eq(_shiny_offers(screen).size(), 1, "the new cards get the shine")


func test_ac73_shiny_look_has_no_danger_colour() -> void:
	assert_false(UiColors.is_danger(UpgradeCard.SHINY_COLOR))
	for color: Color in ShinySparkle.COLORS:
		assert_false(UiColors.is_danger(color), "%s" % color)
	assert_false(UiColors.is_danger(UiColors.GOLD_INK))


func test_ac69_lucky_gift_gives_one_more_level_up() -> void:
	await _quiet_run(["lucky_gift"])
	var banane: Player = first_player()
	var weapons: int = 0
	for upgrade: UpgradeDef in run.upgrade_pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.WEAPON and weapons < 5:
			run.dev_menu.give(upgrade.id, 1)
			weapons += 1
	run.upgrade_rng.seed = 42
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	probe.seed = 42
	var normal: int = GIFT_RULES.roll_count(probe)
	run.pickups.buttons.clear()
	run.drop_gift_box(banane.position)
	await _wait_for_gift()
	assert_eq(run.gift_screen.cards.size(), normal + 1, "one more than the box rolled")
	assert_true(run.tricks.fired(&"lucky_gift"))
	run.gift_screen.close()


func test_ac69_without_lucky_gift_the_box_gives_what_it_rolled() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	for id: StringName in [&"quick_feet", &"big_spool", &"thick_felt"]:
		run.dev_menu.give(id, 1)
	run.upgrade_rng.seed = 42
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	probe.seed = 42
	var normal: int = GIFT_RULES.roll_count(probe)
	run.pickups.buttons.clear()
	run.drop_gift_box(banane.position)
	await _wait_for_gift()
	assert_eq(run.gift_screen.cards.size(), normal)
	run.gift_screen.close()


func test_ac69_four_of_a_kind_shows_four_cards() -> void:
	await _quiet_run(["four_of_a_kind"])
	var banane: Player = first_player()
	var screen: LevelUpScreen = await _open_level_up(banane)
	var count: int = int(FOUR_OF_A_KIND.amount)
	assert_eq(screen.offers.size(), count, "4 cards")
	assert_eq(screen.cards.size(), count)
	assert_true(run.tricks.fired(&"four_of_a_kind"))
	await _press("reroll_cards")
	assert_eq(screen.offers.size(), count, "a reroll deals 4 again")
	await _press("banish_card")
	assert_string_contains(screen.title_label.text, "1, 2, 3 or 4")
	var victim: StringName = screen.offers[3].upgrade.id
	await _press("pick_card_4")
	assert_eq(screen.offers.size(), count, "banish works on card 4")
	assert_ne(screen.offers[3].upgrade.id, victim, "card 4 was replaced")
	var picked: UpgradeOffer = screen.offers[3]
	var before: int = _level_of(banane, picked.upgrade.id)
	await _press("pick_card_4")
	await wait_physics_frames(2)
	assert_false(screen.is_open(), "key 4 picks the 4th card")
	assert_eq(_level_of(banane, picked.upgrade.id), before + picked.levels())


func test_ac69_without_four_of_a_kind_three_cards() -> void:
	await _quiet_run([])
	var screen: LevelUpScreen = await _open_level_up(first_player())
	assert_eq(screen.offers.size(), run.upgrade_pool.cards_per_level_up)
	assert_false(run.tricks.fired(&"four_of_a_kind"))


func _wait_for_gift() -> void:
	var left: int = 300
	while not run.gift_screen.showing_contents and left > 0:
		left -= 1
		await wait_process_frames(1)
	assert_true(run.gift_screen.showing_contents, "the gift shows its contents")
