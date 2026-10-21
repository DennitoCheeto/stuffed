extends GutTest


func test_clock_pads_seconds() -> void:
	assert_eq(TimeFormat.clock(0.0), "0:00")
	assert_eq(TimeFormat.clock(9.9), "0:09")
	assert_eq(TimeFormat.clock(192.7), "3:12")


func test_clock_keeps_counting_minutes_past_an_hour() -> void:
	assert_eq(TimeFormat.clock(3725.0), "62:05")


func test_clock_never_negative() -> void:
	assert_eq(TimeFormat.clock(-3.0), "0:00")


func test_run_timer_shows_goal() -> void:
	assert_eq(TimeFormat.run_timer(192.0, 300.0), "3:12 / 5:00")
