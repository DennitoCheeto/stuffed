extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#339, PO option A): the small, forgiving hit area stays as it is, but every hero
## shows it clearly: a ringed spot drawn at exactly the hit radius. A zombie touching the ring
## hurts, a zombie just outside it doesn't (Banane's tall head is safe, and now you can see why).
## Calm colours, never danger; the dash ring sits just outside the spot.

const OVERLAY: GDScript = preload("res://src/player/player_overlay.gd")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")

var run: Run


## A quiet run as hero `id` (unlocked first), unarmed, nothing spawning.
func _quiet_run_as(id: String) -> Player:
	if id != "banane":
		main.town.plushies[id] = "in_town"
		main.town.set_hero(0, id)
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	var hero: Player = first_player()
	disarm(hero)
	await wait_physics_frames(2)
	return hero


func _ring_radius(hero: Player) -> float:
	return float(hero.get_node("Overlay").call(&"hit_ring_radius"))


## A zombie that stands still, `gap` px beyond touching the drawn ring (negative = overlapping).
func _zombie_near_ring(hero: Player, gap: float) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, hero.global_position)
	zombie.move_speed = 0.0
	var reach: float = zombie.radius() + _ring_radius(hero) + gap
	zombie.position = hero.global_position + Vector2(reach, 0.0)
	return zombie


func _check_ring_is_the_hit_area(id: String) -> void:
	var hero: Player = await _quiet_run_as(id)
	assert_eq(String(hero.stats.id), id, "playing %s" % id)
	assert_eq(_ring_radius(hero), hero.stats.hitbox_radius, "%s: the ring is the hit radius" % id)
	var outside: Zombie = _zombie_near_ring(hero, 2.0)
	await wait_physics_frames(10)
	assert_eq(hero.health, hero.max_health, "%s: just outside the ring doesn't hurt" % id)
	outside.position += Vector2(-3.0, 0.0)
	await wait_physics_frames(3)
	assert_lt(hero.health, hero.max_health, "%s: touching the ring hurts" % id)


func test_339_banane_ring_is_his_hit_area() -> void:
	await _check_ring_is_the_hit_area("banane")


func test_339_robbar_ring_is_his_tiny_hit_area() -> void:
	await _check_ring_is_the_hit_area("robbar")


func test_339_every_hero_shows_a_ring_of_their_own_size() -> void:
	for hero: HeroStats in HEROES.heroes:
		var note: String = "%s: a ring, not a dot" % hero.id
		assert_gt(hero.hitbox_radius, OVERLAY.HIT_DOT_RADIUS * 2.0, note)
	var banane: Player = await _quiet_run_as("banane")
	assert_gt(OVERLAY.DASH_RING_GAP, OVERLAY.HIT_RING_WIDTH, "the dash ring sits outside the spot")
	assert_true(banane.get_node("Overlay").visible, "drawn over the hero")


func test_339_hit_spot_colours_are_calm() -> void:
	for color: Color in [OVERLAY.HIT_FILL, OVERLAY.HIT_RING, OVERLAY.HIT_EDGE]:
		assert_false(UiColors.is_danger(color), "%s is not a danger colour" % color)
