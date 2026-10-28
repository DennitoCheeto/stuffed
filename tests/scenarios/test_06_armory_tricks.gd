extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, AC-69): the Toy Box Armory's tricks work in a run. Head Start: the
## starting weapon starts at Lv 2. Show-and-Tell: the first level-up offers only weapons the hero
## doesn't have (normal cards if there aren't enough). Second Toy: a second, unlocked weapon.

const HEAD_START: TrickDef = preload("res://data/town/tricks/head_start.tres")

var run: Run


func _quiet_run(tricks: Array[String]) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


func _open_level_up(hero: Player) -> LevelUpScreen:
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	return run.level_up_screen


func _owned_ids(hero: Player) -> Array[StringName]:
	var ids: Array[StringName] = []
	for weapon: Weapon in hero.weapons():
		ids.append(weapon.stats.id)
	return ids


func test_ac69_without_armory_tricks_one_weapon_at_lv_1() -> void:
	await _quiet_run([])
	var banane: Player = first_player()
	assert_eq(banane.weapons().size(), 1)
	assert_eq(banane.weapons()[0].level, 1)


func test_ac69_head_start_starting_weapon_at_lv_2() -> void:
	await _quiet_run(["head_start"])
	var banane: Player = first_player()
	assert_eq(banane.weapons().size(), 1)
	assert_eq(banane.weapons()[0].level, int(HEAD_START.amount), "Lv 2 from data")
	var id: StringName = banane.weapons()[0].stats.id
	assert_eq(banane.upgrade_levels()[id], 2, "the cards offer Lv 3 next")
	assert_true(run.hud.trick_banner.visible, "the banner names it")
	assert_eq(run.hud.trick_banner.title.text, "Head Start!")


func test_ac69_show_and_tell_first_level_up_offers_only_new_weapons() -> void:
	await _quiet_run(["head_start", "show_and_tell"])
	var banane: Player = first_player()
	var owned: Array[StringName] = _owned_ids(banane)
	var screen: LevelUpScreen = await _open_level_up(banane)
	assert_eq(screen.offers.size(), 3)
	for offer: UpgradeOffer in screen.offers:
		assert_eq(offer.upgrade.kind, UpgradeDef.Kind.WEAPON, "%s is a weapon" % offer.upgrade.id)
		assert_false(owned.has(offer.upgrade.id), "%s is new" % offer.upgrade.id)
		assert_false(run.perks.locked_weapons.has(offer.upgrade.id), "and unlocked")
	assert_true(run.trick_fired(&"show_and_tell"), "noted for the banner and log")
	screen.picked.emit(screen.offers[0])
	await wait_physics_frames(2)
	assert_true(banane.first_level_up_done, "only the first level-up")
	assert_eq(run.new_weapons_only(banane), [] as Array[StringName], "later cards are normal")


func test_ac69_show_and_tell_falls_back_to_normal_cards_with_full_slots() -> void:
	await _quiet_run(["show_and_tell"])
	var banane: Player = first_player()
	for upgrade: UpgradeDef in run.upgrade_pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.WEAPON and banane.weapons().size() < run.upgrade_pool.max_weapons:
			run.dev_menu.give(upgrade.id, 1)
	var screen: LevelUpScreen = await _open_level_up(banane)
	assert_eq(screen.offers.size(), 3, "three normal cards")
	var owned: Array[StringName] = _owned_ids(banane)
	for offer: UpgradeOffer in screen.offers:
		var kind: UpgradeDef.Kind = offer.upgrade.kind
		var fine: bool = kind != UpgradeDef.Kind.WEAPON or owned.has(offer.upgrade.id)
		assert_true(fine, "%s: no new weapon fits" % offer.upgrade.id)
	assert_false(run.trick_fired(&"show_and_tell"), "the trick didn't fire")


func test_ac69_second_toy_starts_with_a_second_unlocked_weapon() -> void:
	await _quiet_run(["second_toy"])
	var banane: Player = first_player()
	var weapons: Array[Weapon] = banane.weapons()
	assert_eq(weapons.size(), 2, "two weapons from the start")
	if weapons.size() < 2:
		return
	assert_ne(weapons[1].stats.id, weapons[0].stats.id, "a different one")
	assert_false(run.perks.locked_weapons.has(weapons[1].stats.id), "an unlocked one")
	assert_eq(weapons[1].level, 1)
	assert_true(run.trick_fired(&"second_toy"))
