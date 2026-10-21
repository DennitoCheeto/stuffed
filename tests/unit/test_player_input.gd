extends GutTest


func test_player_one_uses_p1_actions() -> void:
	var input: PlayerInput = PlayerInput.new(0)
	assert_eq(input.action("dash"), &"p1_dash")
	assert_true(input.has_controls())


func test_player_two_uses_p2_actions() -> void:
	assert_eq(PlayerInput.new(1).action("move_left"), &"p2_move_left")


func test_player_without_controls_stands_still() -> void:
	var input: PlayerInput = PlayerInput.new(7)
	assert_false(input.has_controls())
	assert_eq(input.move_vector(), Vector2.ZERO)
	assert_false(input.is_just_pressed("dash"))


func test_banane_stats_come_from_data_file() -> void:
	var stats: HeroStats = load("res://data/heroes/banane.tres")
	assert_eq(stats.display_name, "Banane")
	assert_eq(stats.move_speed, 150.0)
	assert_eq(stats.dash_distance, 120.0)
	assert_eq(stats.dash_cooldown, 1.5)
