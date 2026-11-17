extends GutTest
## Night siege targets (spec 07 §4, §5, AC-77): built buildings get health from data (more per
## level, the Lucky Jar extra sturdy), and zombies on their way to the fort turn to a hero or a
## building close by; the Lucky Jar pulls them from further away, even past a hero.

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
## The armory's spot is Rect2(560, 670, 260, 180), the jar's Rect2(1680, 670, 260, 180), the
## fort's Rect2(1050, 600, 400, 300).
const ARMORY: StringName = &"toy_box_armory"
const JAR: StringName = &"lucky_jar"


func _spot(id: StringName) -> TownSpot:
	for spot: TownSpot in LAYOUT.spots:
		if spot.id == id:
			return spot
	return null


func _targets(levels: Dictionary[StringName, int]) -> SiegeTargets:
	var fort: SiegeFort = SiegeFort.new(LAYOUT.fort_rect, 500.0, RULES.hero_reach, 0.5)
	var targets: SiegeTargets = SiegeTargets.new(fort)
	for id: StringName in levels:
		targets.buildings.append(SiegeBuilding.new(_spot(id), levels[id], RULES))
	return targets


func _zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = Zombie.new()
	zombie.position = at
	zombie.setup(SHAMBLER, 1.0, 1.0, 0.0, null, null)
	autofree(zombie)
	return zombie


func _hero(at: Vector2) -> Player:
	var hero: Player = autofree(PLAYER_SCENE.instantiate())
	hero.global_position = at
	return hero


func test_buildings_get_more_health_per_level_from_data() -> void:
	for spot: TownSpot in LAYOUT.spots:
		var last: float = 0.0
		for level: int in range(1, spot.building.max_level() + 1):
			var health: float = SiegeBuilding.new(spot, level, RULES).max_health
			assert_gt(health, last, "%s Lv %d is sturdier" % [spot.id, level])
			last = health


func test_the_lucky_jar_is_extra_sturdy_bait() -> void:
	for level: int in [1, 2, 3]:
		var jar: SiegeBuilding = SiegeBuilding.new(_spot(JAR), level, RULES)
		var armory: SiegeBuilding = SiegeBuilding.new(_spot(ARMORY), level, RULES)
		assert_gt(jar.max_health, armory.max_health, "extra sturdy at Lv %d" % level)
		assert_true(jar.bait)
		assert_false(armory.bait)
		assert_almost_eq(armory.pull, RULES.building_reach, 0.001)
	# Bait radius 250 / 350 / 450 px (spec 07 §4).
	for level: int in [1, 2, 3]:
		var pull: float = SiegeBuilding.new(_spot(JAR), level, RULES).pull
		assert_almost_eq(pull, 150.0 + 100.0 * level, 0.001)


func test_zombies_far_from_everything_walk_to_the_fort() -> void:
	var targets: SiegeTargets = _targets({ARMORY: 1, JAR: 1})
	var zombie: Zombie = _zombie(Vector2(1250, 150))
	assert_eq(targets.goal_for(zombie, null), targets.fort)


func test_a_building_close_by_draws_zombies_on_their_way() -> void:
	var targets: SiegeTargets = _targets({ARMORY: 1})
	var armory: SiegeBuilding = targets.building(ARMORY)
	var close: Zombie = _zombie(Vector2(500, 760))
	assert_eq(targets.goal_for(close, null), armory, "60 px from the armory")
	var far: Zombie = _zombie(Vector2(300, 760))
	assert_eq(targets.goal_for(far, null), targets.fort, "260 px away: on to the fort")
	assert_null(targets.goal_for(close, _hero(Vector2(450, 760))), "a hero close by wins")
	armory.hurt(armory.max_health)
	assert_eq(targets.goal_for(close, null), targets.fort, "a knocked-down building is ignored")


func test_the_lucky_jar_pulls_from_further_away_even_past_a_hero() -> void:
	var targets: SiegeTargets = _targets({ARMORY: 1, JAR: 1})
	var jar: SiegeBuilding = targets.building(JAR)
	# 200 px right of the jar: too far for a normal building, inside the jar's 250 px.
	var zombie: Zombie = _zombie(Vector2(2140, 760))
	assert_eq(targets.goal_for(zombie, null), jar)
	assert_eq(targets.goal_for(zombie, _hero(Vector2(2140, 860))), jar, "bait before the hero")
	var farther: Zombie = _zombie(Vector2(2240, 760))
	assert_eq(targets.goal_for(farther, null), targets.fort, "300 px: out of Lv 1's reach")
	var big: SiegeTargets = _targets({JAR: 3})
	assert_eq(big.goal_for(farther, null), big.building(JAR), "Lv 3 reaches 450 px")


func test_a_zombie_keeps_knocking_at_what_it_touches() -> void:
	var targets: SiegeTargets = _targets({ARMORY: 1})
	var fort_rect: Rect2 = LAYOUT.fort_rect
	var at_fort: Zombie = _zombie(Vector2(fort_rect.position.x - SHAMBLER.radius, 700))
	assert_eq(targets.goal_for(at_fort, null), targets.fort)
	targets.touch(at_fort, 1.0)
	assert_lt(targets.fort.health, targets.fort.max_health, "the fort takes its touch")
	assert_almost_eq(targets.building(ARMORY).health, targets.building(ARMORY).max_health, 0.01)


func test_buildings_take_touch_damage_and_fall_once() -> void:
	var targets: SiegeTargets = _targets({ARMORY: 1})
	var armory: SiegeBuilding = targets.building(ARMORY)
	var fell: Array[bool] = []
	armory.fell.connect(func() -> void: fell.append(true))
	var zombie: Zombie = _zombie(Vector2(560 - SHAMBLER.radius, 760))
	targets.touch(zombie, 1.0)
	var expected: float = armory.max_health - SHAMBLER.contact_damage * RULES.building_touch_rate
	assert_almost_eq(armory.health, expected, 0.001)
	assert_true(armory.is_hurt())
	armory.hurt(armory.max_health)
	assert_true(armory.is_fallen())
	assert_false(armory.is_hurt(), "down, not hurt: the bar hides")
	targets.touch(zombie, 1.0)
	assert_eq(fell.size(), 1, "falls once")
	assert_eq(targets.knocked_down().size(), 1)
	assert_has(targets.knocked_down(), ARMORY)
