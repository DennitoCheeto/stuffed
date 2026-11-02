extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §3, §3.1, AC-69, AC-73): the Plush Hospital's tricks work in a run. Quick
## Untangle: freeing a tangled plushie takes half the time. Thank-you Gift: freeing a plushie
## drops a gift box. Plushie Buddy: the plushie rescued last comes along, follows the hero and
## sends the XP buttons near it to the hero; it's drawn small on a soft halo, can't be hurt and
## doesn't attack.

const RULES: RescueRules = preload("res://data/town/rescue_rules.tres")
const BAMBAM: PlushieDef = preload("res://data/town/plushies/bambam.tres")
const QUICK_UNTANGLE: TrickDef = preload("res://data/town/tricks/quick_untangle.tres")
const PLUSHIE_BUDDY: TrickDef = preload("res://data/town/tricks/plushie_buddy.tres")

var run: Run
## Where gift boxes lay right when the plushie was freed, and XP that reached a hero.
var boxes_at_free: Array[Vector2] = []
var collected_xp: int = 0


func _quiet_run(tricks: Array[String]) -> Run:
	for id: String in tricks:
		main.town.tricks.append(id)
	run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	run.rescue_plan = null
	disarm(first_player())
	first_player().invincible = true
	return run


## A town that rescued Pip last (Plushie Buddy brings Pip).
func _rescued_pip() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.last_rescued = "pip"


func _step_to(player: Player, at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO


## Run seconds from standing next to a new tangled plushie until it is free.
func _time_to_free() -> float:
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(first_player(), plushie.middle())
	var started: float = run.elapsed
	while run.haul.rescued.is_empty() and run.elapsed - started < RULES.fill_seconds + 2.0:
		await wait_physics_frames(1)
	return run.elapsed - started


func _gift_boxes_on_floor() -> int:
	var count: int = 0
	for child: Node in run.floor_items.get_children():
		if child is GiftBox and not child.is_queued_for_deletion():
			count += 1
	return count


## An XP button `away` pixels to the left of the hero.
func _button_left_of_hero(away: float) -> XpButton:
	var at: Vector2 = first_player().global_position + Vector2(-away, 0.0)
	return run.pickups.drop(EnemyStats.XpSize.SMALL, at)


func test_ac69_without_quick_untangle_freeing_takes_the_normal_time() -> void:
	await _quiet_run([])
	var seconds: float = await _time_to_free()
	assert_almost_eq(seconds, RULES.fill_seconds, 0.1)
	assert_false(run.tricks.fired(&"quick_untangle"))


func test_ac69_quick_untangle_frees_a_plushie_in_half_the_time() -> void:
	await _quiet_run(["quick_untangle"])
	assert_eq(QUICK_UNTANGLE.amount, 0.5, "half the time, in data")
	var seconds: float = await _time_to_free()
	assert_almost_eq(seconds, RULES.fill_seconds * QUICK_UNTANGLE.amount, 0.1)
	assert_eq(run.haul.rescued, "bambam", "it still comes home")
	assert_true(run.tricks.fired(&"quick_untangle"))
	assert_eq(run.hud.trick_banner.title.text, "Quick Untangle!")


func test_ac69_without_thank_you_gift_freeing_drops_nothing() -> void:
	await _quiet_run([])
	await _time_to_free()
	assert_eq(_gift_boxes_on_floor(), 0)
	assert_eq(run.gift_boxes_opened, 0)
	assert_false(run.tricks.fired(&"thank_you_gift"))


func test_ac69_thank_you_gift_drops_a_gift_box_where_the_plushie_was() -> void:
	await _quiet_run(["thank_you_gift"])
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	var spot: Vector2 = plushie.position
	plushie.freed.connect(_on_freed)
	_step_to(first_player(), plushie.middle())
	await wait_seconds(RULES.fill_seconds + 0.2)
	assert_eq(boxes_at_free.size(), 1, "a gift box drops when it's freed")
	assert_eq(run.gift_boxes_opened + _gift_boxes_on_floor(), 1, "there to take")
	if boxes_at_free.size() == 1:
		assert_almost_eq(boxes_at_free[0].distance_to(spot), 0.0, 1.0, "where it stood")
	assert_true(run.tricks.fired(&"thank_you_gift"))


func _on_freed(_player: Player) -> void:
	for child: Node in run.floor_items.get_children():
		if child is GiftBox:
			boxes_at_free.append((child as GiftBox).position)


func _on_collected(_player: Player, value: int, _chain: int) -> void:
	collected_xp += value


func test_ac69_without_plushie_buddy_no_buddy_comes_along() -> void:
	_rescued_pip()
	await _quiet_run([])
	assert_null(run.tricks.buddy)
	var far: float = first_player().pickup_range + 120.0
	var button: XpButton = _button_left_of_hero(far)
	await wait_seconds(0.5)
	assert_true(run.pickups.buttons.has(button), "out of reach, it stays on the floor")


func test_ac69_plushie_buddy_needs_a_rescued_plushie() -> void:
	await _quiet_run(["plushie_buddy"])
	assert_null(run.tricks.buddy, "nobody rescued yet, nobody comes along")


func test_ac69_plushie_buddy_follows_the_hero_and_fetches_buttons() -> void:
	_rescued_pip()
	await _quiet_run(["plushie_buddy"])
	var buddy: PlushieBuddy = run.tricks.buddy
	assert_not_null(buddy, "the buddy came along")
	assert_eq(buddy.plushie.id, "pip", "the plushie rescued last")
	var hero: Player = first_player()
	var close: float = RULES.buddy_follow_distance + 5.0
	assert_lt(buddy.global_position.distance_to(hero.global_position), close, "next to Banane")
	assert_false(run.tricks.fired(&"plushie_buddy"))
	# A button out of Banane's reach but near the buddy (it waits on Banane's left).
	var away: float = hero.pickup_range + PLUSHIE_BUDDY.amount * 0.5
	assert_lt(away - RULES.buddy_follow_distance, PLUSHIE_BUDDY.amount, "the buddy reaches it")
	run.pickups.collected.connect(_on_collected)
	_button_left_of_hero(away)
	await wait_seconds(1.0)
	assert_eq(run.pickups.buttons.size(), 0, "the buddy sent it to Banane")
	assert_gt(collected_xp, 0, "Banane got the XP")
	assert_true(run.tricks.fired(&"plushie_buddy"))
	assert_eq(run.hud.trick_banner.title.text, "Plushie Buddy!")
	# It trots after Banane when he walks off.
	_step_to(hero, hero.global_position + Vector2(500.0, 0.0))
	await wait_seconds(0.3)
	assert_true(buddy.walking, "it hops after him")
	await wait_seconds(2.0)
	var gap: float = buddy.global_position.distance_to(hero.global_position)
	assert_lt(gap, close, "it caught up")


func test_ac69_ac73_the_buddy_is_harmless_and_never_looks_like_danger() -> void:
	_rescued_pip()
	await _quiet_run(["plushie_buddy"])
	var buddy: PlushieBuddy = run.tricks.buddy
	assert_false(buddy.is_class("CollisionObject2D"), "no body: zombies can't hurt it")
	assert_eq(buddy.get_child_count(), 0, "no weapons, no hitbox")
	assert_lt(RULES.buddy_size, TangledPlushie.SIZE, "drawn small")
	assert_false(UiColors.is_danger(RULES.buddy_halo), "a soft halo, never danger red")
	assert_gt(RULES.buddy_halo.v, 0.85, "a light halo")
