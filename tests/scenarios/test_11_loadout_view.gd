extends "res://tests/scenarios/run_scenario.gd"
## Spec 04b §2 (AC-117): Esc → Loadout shows every hero's weapons and items with their levels,
## evolved weapons, the evolution hint per weapon ("Ready!" once maxed with the partner owned),
## worn gear and the free slots. Back / Esc returns to the pause menu; the run stays frozen.

const TEXTS: LoadoutTexts = preload("res://data/ui/loadout_view.tres")

var run: Run


func before_each() -> void:
	super()
	RecipeBook.seen.clear()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.rescue_plan = null
	run.spawner.active = false
	for player: Player in Players.all(run.get_tree()):
		disarm(player)
		player.invincible = true
	return run


## Gives `player` weapon `id` at `level` (top level when 0).
func _weapon(player: Player, id: StringName, level: int = 0) -> Weapon:
	var upgrade: UpgradeDef = run.upgrade_pool.find(id)
	var weapon: Weapon = player.add_weapon(upgrade.weapon)
	weapon.level = level if level > 0 else upgrade.top_level()
	return weapon


func _item(player: Player, id: StringName, level: int) -> void:
	for step: int in level:
		player.apply_upgrade(UpgradeOffer.new(run.upgrade_pool.find(id), step + 1))


func _open_loadout(by_key: bool = false) -> LoadoutPage:
	if by_key:
		await tap_action("pause")
	else:
		run.pause()
	assert_true(run.pause_menu.is_open(), "the pause menu is open")
	run.pause_menu.loadout_button.pressed.emit()
	await wait_process_frames(2)
	return run.pause_menu.loadout_page


func _row(column: LoadoutColumn, id: StringName) -> Dictionary:
	for entry: Dictionary in column.weapon_rows:
		if entry["id"] == id:
			return entry
	return {}


func test_ac117_the_loadout_page_lists_weapons_items_and_evolution_hints() -> void:
	await _quiet_run()
	var hero: Player = first_player()
	var pool: UpgradePool = run.upgrade_pool
	_weapon(hero, &"peel_boomerang", 3)
	_weapon(hero, &"orbiting_needles")
	_weapon(hero, &"sewing_pin_sniper")
	_weapon(hero, &"yarn_cannon")
	_item(hero, &"quick_feet", 2)
	_item(hero, &"sharp_scissors", 1)
	_item(hero, &"big_spool", 1)
	var yarn: EvolutionDef = null
	for evolution: EvolutionDef in pool.evolutions:
		if evolution.weapon == &"yarn_cannon":
			yarn = evolution
	hero.evolve(yarn)
	await wait_physics_frames(10)
	var page: LoadoutPage = await _open_loadout(true)
	assert_true(page.is_visible_in_tree(), "the Loadout page opens")
	assert_false(run.pause_menu.panel.visible, "instead of the menu")
	assert_true(run.is_frozen(), "the run stays frozen")
	assert_eq(page.columns.size(), 1, "one column for one hero")
	var column: LoadoutColumn = page.columns[0]
	assert_eq(column.heading.label.text, TEXTS.heading % [1, hero.stats.display_name])
	assert_eq(column.weapon_rows.size(), 4)
	var boomerang: Dictionary = _row(column, &"peel_boomerang")
	assert_eq(boomerang["level"], 3)
	assert_eq(boomerang["top"], pool.find(&"peel_boomerang").top_level())
	assert_eq(
		boomerang["hint"], TEXTS.evolve_hint % [TEXTS.unseen, "Quick Feet"], "unseen name, partner"
	)
	var needles: Dictionary = _row(column, &"orbiting_needles")
	assert_string_contains(needles["hint"], pool.find(&"long_thread").display_name)
	assert_eq(_row(column, &"sewing_pin_sniper")["hint"], TEXTS.ready, "maxed + partner owned")
	var evolved: Dictionary = _row(column, yarn.evolved.id)
	assert_true(evolved["evolved"], "the evolved weapon is marked")
	assert_eq(evolved["hint"], "", "an evolved weapon has no hint")
	assert_eq(column.item_rows.size(), 3)
	assert_eq(column.item_rows[0]["id"], &"quick_feet")
	assert_eq(column.item_rows[0]["level"], 2)
	var free: int = pool.max_weapons - 4 + pool.max_items - 3
	assert_eq(column.empty_slots, free, "free slots show as faint empty slots")
	await tap_action("pause")
	assert_false(page.visible, "Esc goes back")
	assert_true(run.pause_menu.panel.visible)
	assert_true(run.pause_menu.loadout_button.has_focus(), "back on Loadout")
	assert_true(run.pause_menu.is_open(), "still paused")


func test_ac117_partner_owned_colours_and_seen_names() -> void:
	await _quiet_run()
	var pool: UpgradePool = run.upgrade_pool
	var hidden: Array[StringName] = []
	var none: Dictionary[StringName, int] = {}
	var owned: Dictionary[StringName, int] = {&"quick_feet": 1}
	var missing: Dictionary = LoadoutColumn.evolution_hint(
		&"peel_boomerang", false, none, pool, hidden, TEXTS
	)
	assert_eq(missing["color"], LoadoutColumn.MISSING_COLOR, "partner not owned: grey")
	var has: Dictionary = LoadoutColumn.evolution_hint(
		&"peel_boomerang", false, owned, pool, hidden, TEXTS
	)
	assert_eq(has["color"], LoadoutColumn.OWNED_COLOR, "partner owned: green")
	var split: EvolutionDef = pool.evolutions[0]
	RecipeBook.mark_seen(split.evolved.id)
	var seen: Dictionary = LoadoutColumn.evolution_hint(
		&"peel_boomerang", false, owned, pool, hidden, TEXTS
	)
	assert_eq(seen["text"], TEXTS.evolve_hint % [split.display_name(), "Quick Feet"])
	var not_ready: Dictionary = LoadoutColumn.evolution_hint(
		&"peel_boomerang", true, none, pool, hidden, TEXTS
	)
	assert_ne(not_ready["text"], TEXTS.ready, "maxed without the partner isn't ready")
	hidden.append(&"peel_boomerang")
	var gone: Dictionary = LoadoutColumn.evolution_hint(
		&"peel_boomerang", true, owned, pool, hidden, TEXTS
	)
	assert_true(gone.is_empty(), "a hidden hero's recipe gives no hint")


func test_ac117_a_locked_heros_weapon_shows_no_recipe() -> void:
	await _quiet_run()
	_weapon(first_player(), &"snowball_toss")
	assert_true(run.perks.locked_hero_weapons.has(&"snowball_toss"), "Pip isn't unlocked")
	var page: LoadoutPage = await _open_loadout()
	assert_eq(_row(page.columns[0], &"snowball_toss")["hint"], "")


func test_ac117_co_op_shows_a_column_per_hero_with_their_gear() -> void:
	main.town.gear.add_pattern("lookout_cap")
	main.town.gear.stitches["lookout_cap"] = 2
	main.town.gear.put_on(0, "head", "lookout_cap")
	main.player_count = 2
	add_controls(1)
	await _quiet_run()
	var players: Array[Player] = Players.all(run.get_tree())
	assert_eq(players.size(), 2)
	for player: Player in players:
		_weapon(player, &"peel_boomerang", player.player_index + 1)
	var page: LoadoutPage = await _open_loadout()
	assert_eq(page.columns.size(), 2, "one column per hero")
	for index: int in 2:
		var column: LoadoutColumn = page.columns[index]
		assert_eq(column.player_index, index, "in player order")
		assert_eq(_row(column, &"peel_boomerang")["level"], index + 1, "each hero's own levels")
	assert_eq(page.columns[0].gear_lines, PackedStringArray([TEXTS.gear_line % ["Lookout Cap", 2]]))
	assert_eq(page.columns[1].gear_lines.size(), 0, "player 2 wears nothing")
