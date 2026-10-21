extends GutTest
## Spec 02 §4, AC-3 (unit): each item changes the numbers it says, and weapons use them.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")

var player: Player


func before_each() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child_autofree(player)


func _pick(id: StringName, times: int = 1) -> void:
	for i: int in times:
		var level: int = player.item_levels.get(id, 0) + 1
		player.apply_upgrade(UpgradeOffer.new(POOL.find(id), level))


func _boomerang() -> Weapon:
	return player.weapon(&"peel_boomerang")


func test_sharp_scissors_raise_weapon_damage() -> void:
	var base: float = _boomerang().current().damage
	_pick(&"sharp_scissors", 2)
	assert_almost_eq(_boomerang().current().damage, base * 1.2, 0.001)
	assert_eq(_boomerang().stats.at_level(1).damage, base, "the data stays as it is")


func test_long_thread_raises_reach_and_duration() -> void:
	var base: WeaponLevel = _boomerang().stats.at_level(1).duplicate()
	base.duration = 2.0
	_boomerang().stats = _boomerang().stats.duplicate()
	_boomerang().stats.levels = [base]
	_pick(&"long_thread")
	assert_almost_eq(_boomerang().current().reach, base.reach * 1.1, 0.001)
	assert_almost_eq(_boomerang().current().duration, 2.2, 0.001)


func test_big_spool_makes_areas_and_hits_bigger() -> void:
	var base: WeaponLevel = _boomerang().stats.at_level(1).duplicate()
	base.area = 50.0
	_boomerang().stats = _boomerang().stats.duplicate()
	_boomerang().stats.levels = [base]
	var radius: float = _boomerang().hit_radius()
	_pick(&"big_spool", 3)
	assert_almost_eq(_boomerang().current().area, 65.0, 0.001)
	assert_almost_eq(_boomerang().hit_radius(), radius * 1.3, 0.001)


func test_thick_felt_reduces_damage_taken() -> void:
	_pick(&"thick_felt", 2)
	player.take_hit(50.0, "Shambler")
	assert_almost_eq(player.health, player.max_health - 50.0 * 0.84, 0.001)


func test_thick_felt_never_blocks_everything() -> void:
	for i: int in 20:
		player.apply_upgrade(UpgradeOffer.new(POOL.find(&"thick_felt"), 1))
	assert_eq(player.damage_taken_multiplier, Player.MIN_DAMAGE_TAKEN)


func test_items_are_remembered_in_pick_order_with_levels() -> void:
	_pick(&"big_spool")
	_pick(&"quick_feet", 2)
	_pick(&"big_spool")
	assert_eq(player.items.size(), 2)
	assert_eq(player.items[0].id, &"big_spool")
	assert_eq(player.items[1].id, &"quick_feet")
	assert_eq(player.item_levels, {&"big_spool": 2, &"quick_feet": 2})
	assert_eq(player.upgrade_levels()[&"peel_boomerang"], 1)


func test_picking_anything_tells_the_hud() -> void:
	var changes: Array[int] = []
	player.loadout_changed.connect(func() -> void: changes.append(1))
	_pick(&"long_thread")
	player.apply_upgrade(UpgradeOffer.new(POOL.find(&"peel_boomerang"), 2))
	assert_eq(changes.size(), 2)
