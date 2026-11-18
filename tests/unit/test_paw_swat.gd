extends GutTest
## Paw Swat and Böbö's Bear Hug in data (spec 08 §3, AC-87, AC-89): five levels, its own sound,
## card icon and Scrapbook page; it joins the cards only once Böbö is unlocked.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const PAW: WeaponStats = preload("res://data/weapons/paw_swat.tres")
const BOBO: HeroStats = preload("res://data/heroes/bobo.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")


func test_ac89_paw_swat_has_five_levels_and_its_own_sound() -> void:
	assert_eq(PAW.max_level(), 5)
	assert_eq(PAW.sound, &"paw")
	for level: int in range(1, 6):
		assert_ne(PAW.at_level(level).card_text, "", "card text for level %d" % level)
		assert_gt(PAW.at_level(level).spread_degrees, 90.0, "a wide swipe")


func test_ac89_it_has_a_card_icon_and_a_scrapbook_page() -> void:
	var card: UpgradeDef = POOL.find(&"paw_swat")
	assert_not_null(card)
	assert_eq(card.icon, &"paw")
	assert_not_null(SCRAPBOOK.pages()[0].find("paw_swat"))


func test_ac87_bobo_starts_with_paw_swat_and_hugs() -> void:
	assert_eq(BOBO.starting_weapon, PAW)
	assert_eq(BOBO.unlocks_weapon, PAW)
	assert_true(BOBO.bear_hug)
	assert_lt(BOBO.damage_taken, 1.0, "takes less damage")


func test_ac89_paw_swat_joins_the_cards_once_bobo_is_unlocked() -> void:
	var save: TownSave = TownSave.new()
	assert_has(TownPerks.from_save(save, LAYOUT).locked_weapons, &"paw_swat")
	save.plushies["bobo"] = "in_town"
	assert_does_not_have(TownPerks.from_save(save, LAYOUT).locked_weapons, &"paw_swat")
