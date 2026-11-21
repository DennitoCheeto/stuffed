extends GutTest
## M6-13 (spec 10 §12, vision §11, AC-116): the MVP has enough to play. At least 3 heroes, 10
## weapons, 3 evolutions, one area with a boss, 6 buildings, 8 gear pieces and a siege with
## waves; each count only includes things that can really show up in the game.

const ROSTER: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const GEAR: GearRules = preload("res://data/gear/gear_rules.tres")
const SIEGE: SiegeRules = preload("res://data/siege/siege_rules.tres")
const RUN_SCENE: String = "res://src/run/run.tscn"
const SIEGE_SCENE: String = "res://src/siege/siege.tscn"


func test_at_least_3_heroes_each_with_its_own_weapon() -> void:
	assert_gte(ROSTER.heroes.size(), 3)
	var ids: Dictionary[StringName, bool] = {}
	for hero: HeroStats in ROSTER.heroes:
		assert_ne(String(hero.id), "", "every hero has an id")
		assert_not_null(hero.starting_weapon, "%s has a weapon" % hero.id)
		ids[hero.id] = true
	assert_eq(ids.size(), ROSTER.heroes.size(), "no hero twice")


func test_at_least_10_weapons_on_the_cards() -> void:
	var weapons: int = 0
	for upgrade: UpgradeDef in POOL.upgrades:
		if upgrade.kind == UpgradeDef.Kind.WEAPON and upgrade.weapon != null:
			weapons += 1
	assert_gte(weapons, 10)


func test_at_least_3_evolutions_with_both_halves_on_the_cards() -> void:
	assert_gte(POOL.evolutions.size(), 3)
	for evolution: EvolutionDef in POOL.evolutions:
		assert_not_null(POOL.find(evolution.weapon), "%s: weapon card" % evolution.evolved.id)
		assert_not_null(POOL.find(evolution.partner), "%s: partner card" % evolution.evolved.id)
		assert_not_null(evolution.evolved, "an evolved weapon")


func test_one_area_with_a_boss() -> void:
	assert_true(ResourceLoader.exists(RUN_SCENE), "the Bedroom")
	assert_not_null(SCHEDULE.boss, "the King")
	assert_not_null(SCHEDULE.mini_boss, "Big Ted")
	assert_false(SCHEDULE.entries.is_empty(), "zombies to fight")


func test_at_least_6_buildings() -> void:
	assert_gte(LAYOUT.spots.size(), 6)
	for spot: TownSpot in LAYOUT.spots:
		assert_not_null(spot.building, "%s has its building" % spot.id)
		assert_eq(spot.building.levels.size(), 3, "%s has 3 levels" % spot.id)


func test_at_least_8_gear_pieces() -> void:
	assert_gte(GEAR.pieces.size(), 8)


func test_a_siege_with_waves() -> void:
	assert_true(ResourceLoader.exists(SIEGE_SCENE))
	assert_false(SIEGE.wave_list.is_empty())
	var bosses: int = 0
	for wave: SiegeWave in SIEGE.wave_list:
		assert_false(wave.enemies.is_empty(), "every wave has zombies")
		if wave.boss != null:
			bosses += 1
	assert_gte(bosses, 1, "the siege ends with a boss")
