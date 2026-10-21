extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §5.2, AC-8, AC-9): the Sewing-Pin Sniper fires on its own towards the cursor.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")

var run: Run


## A run where Banane has only the sniper.
func _sniper_run() -> SewingPinSniper:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	disarm(banane)
	var sniper: SewingPinSniper = banane.add_weapon(SNIPER) as SewingPinSniper
	await wait_physics_frames(5)
	return sniper


func _dummy(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.move_speed = 0.0
	zombie.max_health = 1000.0
	zombie.health = 1000.0
	return zombie


## Moves the mouse so the cursor is over world point `world`. Mouse events arrive in window
## coordinates, so the point goes world → game canvas → window.
func _point_mouse_at(world: Vector2) -> void:
	var viewport: Viewport = run.get_viewport()
	var canvas: Vector2 = viewport.get_canvas_transform() * world
	var window: Vector2 = viewport.get_screen_transform() * canvas
	sender.mouse_motion(window)
	await wait_process_frames(2)


func _pins(weapon: SewingPinSniper) -> Array[PinProjectile]:
	var result: Array[PinProjectile] = []
	for child: Node in weapon.get_children():
		if child is PinProjectile and not child.is_queued_for_deletion():
			result.append(child as PinProjectile)
	return result


func test_ac8_fires_on_its_own_towards_the_cursor() -> void:
	var sniper: SewingPinSniper = await _sniper_run()
	var banane: Player = first_player()
	await _point_mouse_at(banane.global_position + Vector2(-200, -200))
	await wait_for_signal(sniper.fired, 2.0)
	assert_false(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "no mouse button needed")
	await wait_physics_frames(3)
	var pin: PinProjectile = _pins(sniper)[0]
	var flight: Vector2 = pin.global_position - banane.global_position
	assert_lt(flight.x, 0.0, "towards the cursor: left")
	assert_lt(flight.y, 0.0, "towards the cursor: up")
	assert_almost_eq(flight.x, flight.y, 3.0, "diagonal, like the cursor")


func test_ac8_aims_where_the_cursor_is_not_at_zombies() -> void:
	var sniper: SewingPinSniper = await _sniper_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(0, 150))
	await _point_mouse_at(banane.global_position + Vector2(300, 0))
	await wait_for_signal(sniper.fired, 2.0)
	await wait_physics_frames(3)
	var pin: PinProjectile = _pins(sniper)[0]
	assert_gt(pin.global_position.x, banane.global_position.x, "right, where the cursor is")
	assert_almost_eq(pin.global_position.y, banane.global_position.y, 1.0)


func test_ac8_pierces_up_to_its_count_in_a_line() -> void:
	var sniper: SewingPinSniper = await _sniper_run()
	var banane: Player = first_player()
	var line: Array[Zombie] = []
	for i: int in 5:
		line.append(_dummy(banane.global_position + Vector2(120 + i * 60, 0)))
	await _point_mouse_at(banane.global_position + Vector2(500, 0))
	await wait_for_signal(sniper.fired, 2.0)
	await wait_physics_frames(40)
	var pierce: int = sniper.current().pierce
	var hit: int = 0
	for zombie: Zombie in line:
		if zombie.health < 1000.0:
			hit += 1
	assert_eq(hit, pierce + 1, "goes through %d zombies and stops in the next" % pierce)
	assert_lt(line[pierce].health, 1000.0, "the pin stops in zombie %d" % (pierce + 1))
	for behind: int in range(pierce + 1, line.size()):
		assert_eq(line[behind].health, 1000.0, "zombie %d behind it is safe" % (behind + 1))


func test_ac9_level_five_fires_two_pins() -> void:
	var sniper: SewingPinSniper = await _sniper_run()
	for i: int in 4:
		sniper.level_up()
	assert_eq(sniper.level, 5)
	await _point_mouse_at(first_player().global_position + Vector2(300, 0))
	await wait_for_signal(sniper.fired, 2.0)
	await wait_physics_frames(1)
	assert_eq(_pins(sniper).size(), 2)


func test_ac18_sniper_card_adds_the_weapon() -> void:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	var pool: UpgradePool = load("res://data/upgrade_pool.tres")
	var card: UpgradeDef = null
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.id == &"sewing_pin_sniper":
			card = upgrade
	assert_not_null(card, "the sniper is in the upgrade pool")
	var offer: UpgradeOffer = UpgradeOffer.new(card, 1)
	assert_eq(offer.level_text(), "New!")
	banane.apply_upgrade(offer)
	assert_not_null(banane.weapon(&"sewing_pin_sniper"))
	assert_not_null(banane.weapon(&"peel_boomerang"), "keeps the boomerang")
