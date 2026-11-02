extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §7, AC-73): with every trick bought, a run shows all trick visuals at once
## (banner, shield outline, shockwave, heart patch, pocket, buddy, shiny card, Spyglass and
## treasure arrows, a double floor pickup), and the town shows the Tricks panel. None of them
## uses a danger colour (UiColors.is_danger): red/orange belongs to the enemies (hard rule 9).
## The sweep reads every colour the nodes carry, so a new trick look is checked too once its
## node is added to the list.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SHINY_CARD: TrickDef = preload("res://data/town/tricks/shiny_card.tres")
const PICKUP_RULES: FloorPickupRules = preload("res://data/floor_pickup_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const DEADLY: float = 99999.0
const OFF_SCREEN: Vector2 = Vector2(1600.0, 0.0)

var run: Run


func _all_trick_ids() -> Array[String]:
	var ids: Array[String] = []
	for trick: TrickDef in TrickBook.all_tricks(LAYOUT):
		ids.append(String(trick.id))
	return ids


## A seed whose first roll lands under `chance` (a lucky level-up for Shiny Card).
func _lucky_seed(chance: float) -> int:
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	for seed_value: int in range(1, 10000):
		probe.seed = seed_value
		if probe.randf() < chance:
			return seed_value
	return 0


func _shockwaves() -> Array[Node]:
	var waves: Array[Node] = []
	for child: Node in run.effects.get_children():
		if child is SpareShockwave:
			waves.append(child)
	return waves


## Every colour `root` and its children carry: tints, Color variables, theme colour overrides,
## their style boxes and plushie looks, and the Color constants of their scripts.
func _colors_of(root: Object) -> Array[Color]:
	var found: Array[Color] = []
	var objects: Array[Object] = [root]
	if root is Node:
		objects.append_array((root as Node).find_children("*", "", true, false))
	for object: Object in objects:
		_add_properties(object, found)
		var script: Script = object.get_script() as Script
		if script != null:
			for value: Variant in script.get_script_constant_map().values():
				_add_value(value, found)
	return found


func _add_properties(object: Object, found: Array[Color]) -> void:
	for property: Dictionary in object.get_property_list():
		var value: Variant = object.get(String(property["name"]))
		if value is StyleBox or value is PlushieDef:
			_add_properties(value as Object, found)
		else:
			_add_value(value, found)


func _add_value(value: Variant, found: Array[Color]) -> void:
	if value is Color:
		found.append(value as Color)
	elif value is PackedColorArray:
		for color: Color in value as PackedColorArray:
			found.append(color)
	elif value is Array:
		for item: Variant in value as Array:
			if item is Color:
				found.append(item as Color)


func _assert_calm(what: String, root: Object) -> void:
	var colors: Array[Color] = _colors_of(root)
	assert_gt(colors.size(), 0, "%s carries colours" % what)
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), "%s uses danger %s" % [what, color.to_html()])


func test_ac73_no_trick_visual_in_a_run_uses_a_danger_colour() -> void:
	add_controls(1)
	for id: String in _all_trick_ids():
		main.town.tricks.append(id)
	main.town.last_rescued = "bobo"  # the brown bear: his felt alone would count as danger
	main.player_count = 2
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.enemies.calm = true
	var heroes: Array[Player] = Players.all(get_tree())
	var banane: Player = heroes[0]
	disarm(banane)
	disarm(heroes[1])
	# Shield (Second Helping) and the banner in player 1's colour.
	banane.take_hit(10.0, "test")
	banane.heal(30.0)
	assert_gt(banane.shield, 0.0)
	# Player 2 pops back up (Spare Stuffing): shockwave in their colour.
	heroes[1].take_hit(DEADLY, "test")
	assert_false(heroes[1].is_dead())
	# A double pickup in the pocket and one on the floor (Pocket Pickup, Double Fun).
	var kind: FloorPickupDef = PICKUP_RULES.kinds[0]
	assert_true(banane.put_in_pocket(kind, true))
	var double: FloorPickup = run.drop_floor_pickup(
		kind.id, banane.global_position + Vector2(0.0, 400.0), true
	)
	# Spyglass: an elite and a boss off screen.
	var at: Vector2 = banane.global_position + OFF_SCREEN
	run.enemies.spawn(SHAMBLER, at, run.spawner.schedule.elite_rules)
	run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	await wait_process_frames(3)
	assert_true(run.hud.shield_outline.visible, "shield outline")
	assert_true(run.hud.spare_heart.visible, "player 1's heart patch")
	assert_true(run.hud.pocket.is_full(), "pocket")
	assert_true(run.hud.trick_banner.visible, "a trick banner")
	assert_not_null(run.tricks.buddy, "Böbö came along")
	assert_not_null(run.tricks.treasure, "the treasure box")
	assert_has(run.pickup_arrows.colors, PickupArrows.THREAT_COLOR, "a Spyglass arrow")
	assert_eq(_shockwaves().size(), 1, "the shockwave")
	_assert_calm("trick banner", run.hud.trick_banner)
	for index: int in UiColors.PLAYER_MARKERS.size():
		var name_color: Color = TrickBanner.color_for(index)
		assert_false(UiColors.is_danger(name_color), "banner of player %d" % (index + 1))
	_assert_calm("shield outline", run.hud.shield_outline)
	_assert_calm("heart patch", run.hud.spare_heart)
	_assert_calm("pocket", run.hud.pocket)
	_assert_calm("shockwave", _shockwaves()[0])
	_assert_calm("plushie buddy", run.tricks.buddy)
	assert_false(UiColors.is_danger(run.rescue_rules.buddy_halo), "buddy halo")
	_assert_calm("edge arrows", run.pickup_arrows)
	_assert_calm("double floor pickup", double)
	# Shiny Card on a lucky level-up (4 cards with Four of a Kind).
	run.tricks.rng.seed = _lucky_seed(SHINY_CARD.amount)
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	var screen: LevelUpScreen = run.level_up_screen
	assert_eq(screen.cards.size(), 4, "Four of a Kind")
	var shiny: UpgradeCard = null
	for i: int in screen.offers.size():
		if screen.offers[i].shiny:
			shiny = screen.cards[i]
	assert_not_null(shiny, "a shiny card")
	if shiny != null:
		_assert_calm("shiny tag", shiny.shiny_tag)
		_assert_calm("shiny sparkle", shiny.sparkle)


func test_ac73_tricks_panel_has_no_danger_colour() -> void:
	main.town.building_levels["snack_bar"] = 2
	main.town.revealed.append("snack_bar")
	main.town.tricks.append("picnic")
	main.town.materials = {"coins": 0, "stuffing": 0, "thread": 0}
	var town: Town = await go_to_town()
	var bar: TownBuilding = town.buildings[&"snack_bar"]
	assert_true(town.tricks.open(bar))
	await wait_seconds(UiFeel.STYLE.open_seconds + 0.1)
	var states: Array[TrickBook.State] = []
	for patch: TrickPatch in town.tricks.panel.patches:
		states.append(patch.state)
	assert_eq(states.size(), 3, "bought, missing materials, needs level")
	assert_false(states.has(TrickBook.State.CAN_BUY), "no patch can be bought")
	_assert_calm("tricks panel", town.tricks.panel)
	_assert_calm("tricks toast", town.tricks.toast)
	town.tricks.panel.close()
