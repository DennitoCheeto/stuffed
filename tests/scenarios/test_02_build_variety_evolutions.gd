extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §5, AC-7, AC-9): a level-5 weapon plus its partner item evolves at the next
## gift box, and each evolved weapon does what §5 says. Weapon cards show the partner, and the
## pause menu's Recipes page lists the pairs (unseen evolutions as "?").

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Health that no hit in these scenarios can take away.
const TOUGH: float = 100000.0

var run: Run


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	first_player().invincible = true
	return run


## Gives player 1 the weapon of `evolved_id`'s recipe at its top level plus the partner item.
func _ready_to_evolve(evolved_id: StringName) -> EvolutionDef:
	var pool: UpgradePool = run.upgrade_pool
	var evolution: EvolutionDef = pool.evolution_into(evolved_id)
	var banane: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	banane.add_weapon(base.weapon).level = base.top_level()
	banane.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	return evolution


## Drops a gift box on player 1 and waits for its moment to end. Returns the new weapon.
func _evolve_with_a_gift_box(evolution: EvolutionDef) -> Weapon:
	var banane: Player = first_player()
	run.drop_gift_box(banane.global_position)
	await _wait_until(run.gift_screen.is_open, 1.0)
	run.gift_screen.close()
	await wait_physics_frames(1)
	return banane.weapon(evolution.evolved.id)


func _tough_zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = TOUGH
	zombie.move_speed = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _shots(weapon: Weapon, kind: GDScript) -> Array[Projectile]:
	var result: Array[Projectile] = []
	for shot: Projectile in run.projectiles.fired_by(weapon):
		if shot.get_script() == kind:
			result.append(shot)
	return result


func test_ac7_a_ready_weapon_evolves_at_the_next_gift_box() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var evolution: EvolutionDef = _ready_to_evolve(&"banana_split")
	var slot: int = banane.weapons().find(banane.weapon(&"peel_boomerang"))
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0), "the box opens")
	assert_eq(run.gift_screen.title_label.text, "Evolution!", "a bigger moment")
	assert_string_contains(run.gift_screen.contents_label.text, "Peel Boomerang → Banana Split")
	await wait_physics_frames(1)
	assert_null(banane.weapon(&"peel_boomerang"), "the boomerang is gone")
	var split: Weapon = banane.weapon(&"banana_split")
	assert_not_null(split, "Banana Split took its place")
	assert_eq(banane.weapons().find(split), slot, "in the same slot")
	assert_eq(run.hud.weapon_slots[slot].icon_name, evolution.icon, "the HUD shows it")
	assert_eq(banane.item_levels[&"quick_feet"], 1, "the item stays")
	assert_true(RecipeBook.is_seen(&"banana_split"), "now seen on the Recipes page")


func test_ac7_without_the_partner_the_box_gives_level_ups() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_weapon(banane.stats.starting_weapon).level = 5
	banane.apply_upgrade(UpgradeOffer.new(run.upgrade_pool.find(&"long_thread"), 1))
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0))
	assert_eq(run.gift_screen.title_label.text, "Gift box!")
	assert_not_null(banane.weapon(&"peel_boomerang"), "no evolution")
	assert_null(banane.weapon(&"banana_split"))


func test_ac7_banana_split_peels_split_into_three_on_the_way_back() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var split: Weapon = await _evolve_with_a_gift_box(_ready_to_evolve(&"banana_split"))
	_tough_zombie(banane.global_position + Vector2(200, 0))
	var thrown: bool = await _wait_until(
		func() -> bool: return not run.projectiles.fired_by(split).is_empty(), 2.0
	)
	assert_true(thrown)
	var count: int = split.current().count
	assert_eq(run.projectiles.fired_by(split).size(), count, "thrown like a boomerang")
	var split_up: bool = await _wait_until(
		func() -> bool: return run.projectiles.fired_by(split).size() == count * 3, 2.0
	)
	assert_true(split_up, "each peel became three")
	var returning: int = 0
	for peel: Projectile in run.projectiles.fired_by(split):
		if (peel as SplitPeelProjectile).returning:
			returning += 1
	assert_eq(returning, count * 3, "all of them fly back")


func test_ac7_sewing_storm_never_stops_and_flings_outward() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var storm: Weapon = await _evolve_with_a_gift_box(_ready_to_evolve(&"sewing_storm"))
	var numbers: WeaponLevel = storm.current()
	await _wait_until(func() -> bool: return not run.projectiles.fired_by(storm).is_empty(), 1.0)
	assert_eq(run.projectiles.fired_by(storm).size(), numbers.count, "a storm of needles")
	var farthest: float = 0.0
	var seconds: float = 6.0
	for i: int in roundi(seconds * FPS):
		for needle: Projectile in run.projectiles.fired_by(storm):
			farthest = maxf(farthest, needle.global_position.distance_to(banane.global_position))
		await wait_physics_frames(1)
	var needles: WeaponStats = run.upgrade_pool.find(&"orbiting_needles").weapon
	var base_duration: float = needles.at_level(needles.max_level()).duration
	assert_gt(seconds, base_duration, "longer than Orbiting Needles last")
	assert_eq(run.projectiles.fired_by(storm).size(), numbers.count, "still all there: permanent")
	assert_gt(farthest, numbers.reach * 2.0, "flung far outward")


func test_ac7_pincushion_volley_is_a_fan_that_pierces_everything() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var volley: Weapon = await _evolve_with_a_gift_box(_ready_to_evolve(&"pincushion_volley"))
	var line: Array[Zombie] = []
	for i: int in 12:
		line.append(_tough_zombie(banane.global_position + Vector2(120 + i * 30, 0)))
	var fired: Array[int] = []
	volley.fired.connect(func() -> void: fired.append(run.projectiles.fired_by(volley).size()))
	await _wait_until(func() -> bool: return not fired.is_empty(), 2.0)
	assert_eq(fired[0], volley.current().count, "a fan of pins in one volley")
	await wait_physics_frames(roundi(0.6 * FPS))
	for zombie: Zombie in line:
		assert_lt(zombie.health, TOUGH, "a pin went through all 12 zombies")


func test_ac7_yarn_bomb_leaves_sticky_yarn_that_slows_and_hurts() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var bomb: Weapon = await _evolve_with_a_gift_box(_ready_to_evolve(&"yarn_bomb"))
	var target: Zombie = _tough_zombie(banane.global_position + Vector2(220, 0))
	target.move_speed = SHAMBLER.move_speed
	var stuck: bool = await _wait_until(
		func() -> bool: return not _shots(bomb, StickyYarnProjectile).is_empty(), 3.0
	)
	assert_true(stuck, "the burst left sticky yarn")
	var yarn: StickyYarnProjectile = _shots(bomb, StickyYarnProjectile)[0] as StickyYarnProjectile
	var inside: Zombie = _tough_zombie(yarn.global_position)
	inside.move_speed = SHAMBLER.move_speed
	await wait_physics_frames(2)
	assert_lt(inside.current_speed(), SHAMBLER.move_speed, "slowed")
	var health: float = inside.health
	await wait_physics_frames(roundi(1.2 * FPS))
	assert_lt(inside.health, health, "and hurt while it stays inside")
	assert_gt(yarn.time_left(), 0.0, "for a while")


func test_ac9_weapon_cards_show_the_partner_icon() -> void:
	await _quiet_run()
	var pool: UpgradePool = run.upgrade_pool
	var card: UpgradeCard = UpgradeCard.new()
	add_child_autofree(card)
	var weapon_offer: UpgradeOffer = UpgradeOffer.new(pool.find(&"yarn_cannon"), 1)
	weapon_offer.partner = pool.partner_of(weapon_offer.upgrade)
	card.show_offer(weapon_offer, 1)
	assert_true(card.partner_row.visible)
	assert_eq(card.partner_icon.icon, &"spool", "Big Spool's icon")
	assert_string_contains(card.partner_label.text, "Big Spool")
	card.show_offer(UpgradeOffer.new(pool.find(&"big_spool"), 1), 2)
	assert_false(card.partner_row.visible, "items show no partner")


func test_ac9_level_up_cards_of_weapons_show_their_partner() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_weapon(banane.stats.starting_weapon)
	var seen_partner: bool = false
	for attempt: int in 8:
		banane.progress.level_up_now()
		await _wait_until(run.level_up_screen.is_open, 2.0)
		await wait_for_signal(run.level_up_screen.cards_shown, 2.0)
		for card: UpgradeCard in run.level_up_screen.cards:
			var partner: UpgradeDef = run.upgrade_pool.partner_of(card.offer.upgrade)
			assert_eq(card.partner_row.visible, partner != null, card.offer.upgrade.display_name)
			seen_partner = seen_partner or partner != null
		await wait_physics_frames(roundi(0.3 * FPS))
		run.level_up_screen.choose(0)
		await wait_physics_frames(2)
	assert_true(seen_partner, "some weapon card showed its partner")


func test_ac9_recipes_page_lists_all_pairs_unseen_as_question_marks() -> void:
	await _quiet_run()
	_ready_to_evolve(&"pincushion_volley")
	await _evolve_with_a_gift_box(run.upgrade_pool.evolution_into(&"pincushion_volley"))
	await tap_action("pause")
	assert_true(run.pause_menu.is_open())
	run.pause_menu.recipes_button.pressed.emit()
	await wait_physics_frames(1)
	var page: RecipesPage = run.pause_menu.recipes_page
	assert_true(page.is_visible_in_tree(), "the Recipes page opens")
	assert_false(run.pause_menu.panel.visible)
	assert_eq(page.rows.size(), 4, "all four pairs")
	var shown: Array[String] = []
	for row: RecipeRow in page.rows:
		shown.append(row.result_label.text)
	assert_eq(shown, ["?", "?", "Pincushion Volley", "?"], "only the seen one has a name")
	assert_eq(page.rows[2].result_icon.icon, &"volley")
	assert_eq(page.rows[0].result_icon.icon, &"", "no icon for an unseen one")
	await tap_action("pause")
	assert_false(page.visible, "Esc goes back")
	assert_true(run.pause_menu.panel.visible)
	assert_true(run.pause_menu.is_open(), "still paused")
	await tap_action("pause")
	assert_false(run.pause_menu.is_open())
