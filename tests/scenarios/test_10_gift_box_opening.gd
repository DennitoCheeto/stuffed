extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#342, playtest 2026-11-21: "a bit stale"): the gift box opening flows. The box rocks
## gently then harder and squashes down, the lid eases off with a small overshoot while the box
## stretches up and springs back, the box shrinks away and the cards fly out of it to their
## places. The time until the cards show does not grow. Reduced motion keeps it plain.

const RULES: GiftBoxRules = preload("res://data/gift_box_rules.tres")

var run: Run


func before_each() -> void:
	super()
	GameSettings.reduced_motion = false


func after_each() -> void:
	GameSettings.reduced_motion = false
	super()


func _open_box(reduced: bool = false) -> GiftBoxScreen:
	run = await start_run()
	GameSettings.reduced_motion = reduced
	run.spawner.active = false
	run.rescue_plan = null
	var hero: Player = first_player()
	disarm(hero)
	var weapon: Weapon = hero.add_weapon(hero.stats.starting_weapon)
	weapon.level = 1
	run.pickups.buttons.clear()
	run.drop_gift_box(hero.global_position)
	var screen: GiftBoxScreen = run.gift_screen
	for frame: int in 60:
		if screen.is_open():
			break
		await wait_process_frames(1)
	assert_true(screen.is_open(), "the box opens")
	return screen


func test_the_opening_squashes_pops_with_overshoot_and_shrinks_away() -> void:
	var screen: GiftBoxScreen = await _open_box()
	var most_squash: float = 0.0
	var most_stretch: float = 0.0
	var early_rock: float = 0.0
	var late_rock: float = 0.0
	var most_lid: float = 0.0
	var smallest: float = 1.0
	var faintest: float = 1.0
	while not screen.showing_contents:
		var share: float = screen.time / screen.opening_seconds
		var rock: float = absf(screen.art.wobble)
		if share < GiftBoxScreen.LID_POP_AT * 0.4:
			early_rock = maxf(early_rock, rock)
		elif share < GiftBoxScreen.LID_POP_AT:
			late_rock = maxf(late_rock, rock)
		most_squash = maxf(most_squash, screen.art.squash)
		most_stretch = minf(most_stretch, screen.art.squash)
		most_lid = maxf(most_lid, screen.art.lid_open)
		smallest = minf(smallest, screen.art.scale.x)
		faintest = minf(faintest, screen.art.modulate.a)
		await wait_process_frames(1)
	assert_lte(screen.time, RULES.opening_seconds + 0.1, "the cards come no later than before")
	assert_gt(late_rock, early_rock, "it rocks gently first, then harder")
	assert_gt(most_squash, RULES.wind_up_squash * 0.5, "it squashes down before the pop")
	assert_lt(most_stretch, -RULES.pop_stretch * 0.5, "and stretches up when the lid pops")
	assert_gt(most_lid, 1.02, "the lid flies a little too far and settles")
	assert_lt(smallest, 0.8, "the box shrinks away at the end")
	assert_lt(faintest, 0.5, "and fades")


func test_the_cards_fly_out_of_the_box_to_their_places() -> void:
	var screen: GiftBoxScreen = await _open_box()
	while not screen.showing_contents:
		await wait_process_frames(1)
	var first: GiftCardView = screen.cards[0]
	assert_gt(first.drift.length(), 100.0, "the card starts far from its place")
	assert_gt(first.drift.x, 0.0, "over at the box (right of the middle)")
	assert_lt(first.grow, 0.8, "and small")
	var wait: float = RULES.card_flow_seconds + RULES.card_flow_stagger * screen.cards.size()
	await wait_seconds(wait + 0.2)
	for card: GiftCardView in screen.cards:
		assert_almost_eq(card.drift.length(), 0.0, 0.5, "it landed in its place")
		assert_almost_eq(card.grow, 1.0, 0.01, "full size")
		assert_almost_eq(card.fade, 1.0, 0.01, "fully visible")


func test_the_start_offsets_point_every_card_at_the_box() -> void:
	var width: float = GiftCardView.CARD_SIZE.x
	var from: Vector2 = GiftBoxScreen.box_middle()
	var offsets: Array[Vector2] = GiftBoxScreen.card_start_offsets(3, width, from)
	assert_eq(offsets.size(), 3)
	var step: float = width + GiftBoxScreen.CARD_GAP
	assert_almost_eq(offsets[1].x, from.x, 0.01, "the middle card sits under the screen middle")
	assert_almost_eq(offsets[0].x - offsets[1].x, step, 0.01, "the left card flies further")
	assert_almost_eq(offsets[2].x - offsets[1].x, -step, 0.01)


func test_reduced_motion_keeps_the_opening_plain() -> void:
	var screen: GiftBoxScreen = await _open_box(true)
	var most_squash: float = 0.0
	while not screen.showing_contents:
		most_squash = maxf(most_squash, absf(screen.art.squash))
		await wait_process_frames(1)
	assert_eq(most_squash, 0.0, "no squash and stretch")
	await wait_process_frames(1)
	for card: GiftCardView in screen.cards:
		assert_eq(card.drift, Vector2.ZERO, "the cards are at their places at once")
		assert_eq(card.grow, 1.0)
