extends GutTest
## Snowball Toss and Pip's Chilly Hug in data (spec 08 §3, AC-87, AC-89): five levels, its own
## sound, card icon and Scrapbook page; it joins the cards only once Pip is unlocked.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const SNOWBALL: WeaponStats = preload("res://data/weapons/snowball_toss.tres")
const PIP: HeroStats = preload("res://data/heroes/pip.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")


func test_ac89_snowball_toss_has_five_levels_and_slows() -> void:
	assert_eq(SNOWBALL.max_level(), 5)
	assert_gt(SNOWBALL.slow, 0.0, "slows what it hits")
	assert_gt(SNOWBALL.slow_seconds, 0.0)
	assert_eq(SNOWBALL.sound, &"snowball", "its own sound")
	for level: int in range(1, 6):
		assert_ne(SNOWBALL.at_level(level).card_text, "", "card text for level %d" % level)


func test_ac89_it_has_a_card_icon_and_a_scrapbook_page() -> void:
	var card: UpgradeDef = POOL.find(&"snowball_toss")
	assert_not_null(card, "on the level-up cards")
	assert_eq(card.icon, &"snowball")
	var weapons: ScrapbookPage = SCRAPBOOK.pages()[0]
	assert_not_null(weapons.find("snowball_toss"), "Scrapbook page entry")


func test_ac87_pip_starts_with_snowball_toss_and_has_chilly_hug() -> void:
	assert_eq(PIP.starting_weapon, SNOWBALL)
	assert_eq(PIP.unlocks_weapon, SNOWBALL)
	assert_true(PIP.chilly_hug)
	assert_lt(PIP.chilly_boss_slow, PIP.chilly_slow, "bosses are slowed less")


func test_ac89_snowball_toss_joins_the_cards_once_pip_is_unlocked() -> void:
	var save: TownSave = TownSave.new()
	assert_has(TownPerks.from_save(save, LAYOUT).locked_weapons, &"snowball_toss", "Pip locked")
	save.plushies["pip"] = "waiting"
	assert_does_not_have(TownPerks.from_save(save, LAYOUT).locked_weapons, &"snowball_toss")
