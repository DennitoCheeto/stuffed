extends GutTest
## Playable plushies (spec 08 §3, §4, §10, AC-85, AC-87, AC-92): the hero roster, each hero's
## strength and weakness in data, the unlock rule (freed in the Bedroom = playable), and the hero
## choice per player surviving save and reload (older saves play Banane).

const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SAVE: String = "user://test_unit_hero_save.json"


func before_each() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _hero(id: String) -> HeroStats:
	return HEROES.find(StringName(id))


func test_banane_comes_first_and_every_rescue_plushie_is_a_hero() -> void:
	assert_eq(HEROES.starter().id, &"banane")
	assert_null(HEROES.starter().plushie, "Banane is no rescued plushie")
	assert_eq(HEROES.heroes.size(), RESCUE.plushies.size() + 1)
	for plushie: PlushieDef in RESCUE.plushies:
		var hero: HeroStats = _hero(plushie.id)
		assert_not_null(hero, "%s is a hero" % plushie.id)
		assert_eq(hero.plushie, plushie)
		assert_eq(hero.display_name, plushie.display_name)


func test_ac87_every_hero_has_its_own_starting_weapon_and_only_banane_slips() -> void:
	var weapons: Array[StringName] = []
	for hero: HeroStats in HEROES.heroes:
		assert_not_null(hero.starting_weapon, String(hero.id))
		assert_false(weapons.has(hero.starting_weapon.id), "%s has its own weapon" % hero.id)
		weapons.append(hero.starting_weapon.id)
		assert_eq(hero.slippery, hero.id == &"banane", "Slippery stays Banane's")
	assert_eq(_hero("bambam").starting_weapon.id, &"sewing_pin_sniper")
	assert_eq(_hero("robbar").starting_weapon.id, &"bouncy_yarn_ball")


func test_ac87_strengths_and_weaknesses_are_in_the_data() -> void:
	var banane: HeroStats = HEROES.starter()
	var bobo: HeroStats = _hero("bobo")
	var robbar: HeroStats = _hero("robbar")
	for hero: HeroStats in HEROES.heroes:
		if hero != bobo:
			assert_gt(bobo.max_health, hero.max_health, "Böbö has the most health")
			assert_lt(bobo.move_speed, hero.move_speed, "Böbö is the slowest")
		if hero != robbar:
			assert_gt(robbar.move_speed, hero.move_speed, "Robbar is the fastest")
			assert_lt(robbar.max_health, hero.max_health, "Robbar has the least health")
			assert_lt(robbar.hitbox_radius, hero.hitbox_radius, "Robbar is the smallest target")
			assert_lt(robbar.dash_cooldown, hero.dash_cooldown, "Robbar dashes most often")
	assert_lt(_hero("bambam").pickup_range, banane.pickup_range, "BamBam: small pickup range")


func test_ac85_freeing_a_plushie_unlocks_its_hero() -> void:
	var save: TownSave = TownSave.new()
	assert_eq(HEROES.unlocked(save), [HEROES.starter()] as Array[HeroStats])
	var haul: RunHaul = RunHaul.new()
	haul.rescued = "pip"
	save.bank(haul, 1.0)
	assert_eq(save.plushies["pip"], "waiting", "still waiting for the Hospital")
	assert_true(HEROES.is_unlocked(_hero("pip"), save), "playable right after the rescue")
	assert_false(HEROES.is_unlocked(_hero("bobo"), save))
	save.plushies["bobo"] = "in_town"
	assert_eq(HEROES.unlocked(save).size(), 3)


func test_ac85_a_locked_or_unknown_saved_hero_plays_banane() -> void:
	var save: TownSave = TownSave.new()
	assert_eq(HEROES.hero_for(save, 0), HEROES.starter(), "nothing picked yet")
	save.set_hero(0, "robbar")
	assert_eq(HEROES.hero_for(save, 0), HEROES.starter(), "Robbar isn't rescued yet")
	save.plushies["robbar"] = "in_town"
	assert_eq(HEROES.hero_for(save, 0), _hero("robbar"))
	save.set_hero(0, "nobody")
	assert_eq(HEROES.hero_for(save, 0), HEROES.starter())


func test_next_unlocked_cycles_through_the_open_heroes() -> void:
	var save: TownSave = TownSave.new()
	save.plushies["bobo"] = "waiting"
	assert_eq(HEROES.next_unlocked(save, HEROES.starter()), _hero("bobo"))
	assert_eq(HEROES.next_unlocked(save, _hero("bobo")), HEROES.starter())


func test_ac92_hero_choice_survives_save_and_reload() -> void:
	var town: TownSave = TownSave.new()
	town.plushies["pip"] = "in_town"
	town.plushies["bobo"] = "waiting"
	town.set_hero(1, "bobo")
	town.set_hero(0, "pip")
	assert_eq(town.heroes, PackedStringArray(["pip", "bobo"]))
	assert_true(SaveStore.write(town))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.to_dict(), town.to_dict())
	assert_eq(HEROES.hero_for(loaded, 0), _hero("pip"))
	assert_eq(HEROES.hero_for(loaded, 1), _hero("bobo"))


func test_ac92_an_older_save_plays_banane() -> void:
	var town: TownSave = TownSave.new()
	town.plushies["pip"] = "in_town"
	var data: Dictionary = town.to_dict()
	data["version"] = 5
	data.erase("heroes")
	var loaded: TownSave = TownSave.from_dict(data)
	assert_eq(loaded.heroes.size(), 0)
	assert_eq(HEROES.hero_for(loaded, 0), HEROES.starter())


func test_town_perks_hand_each_player_their_hero() -> void:
	var town: TownSave = TownSave.new()
	town.plushies["robbar"] = "in_town"
	town.set_hero(0, "robbar")
	var perks: TownPerks = TownPerks.from_save(town, LAYOUT)
	assert_eq(perks.hero(0), _hero("robbar"))
	assert_null(perks.hero(1), "player 2 never picked: the hero scene's own (Banane)")
	assert_null(TownPerks.new().hero(0), "a run without a town keeps Banane")
