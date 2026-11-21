extends GutTest
## The low-health warning's rules (spec 10 §7, AC-115): below 25% the heart beats and pulses, it
## stops when healed or fallen, and the heart never turns danger red.

const RULES: LowHealthRules = preload("res://data/ui/low_health.tres")
const MAX: float = 100.0


func test_ac115_the_line_is_a_quarter_of_max_health_in_data() -> void:
	assert_almost_eq(RULES.threshold, 0.25, 0.001, "spec: below 25%")
	assert_true(LowHealthWarning.is_low(24.0, MAX))
	assert_false(LowHealthWarning.is_low(25.0, MAX), "exactly 25% is not below")
	assert_false(LowHealthWarning.is_low(80.0, MAX))
	assert_false(LowHealthWarning.is_low(0.0, MAX), "a fallen hero gets no heartbeat")
	assert_false(LowHealthWarning.is_low(10.0, 0.0))


func test_ac115_it_beats_at_once_then_on_every_beat() -> void:
	var warning: LowHealthWarning = autofree(LowHealthWarning.new())
	warning.tick(MAX, MAX, 0.1)
	assert_false(warning.active)
	assert_eq(warning.beats, 0)
	assert_eq(warning.pulse(), 0.0, "no pulse at full health")
	warning.tick(20.0, MAX, 0.0)
	assert_true(warning.active)
	assert_eq(warning.beats, 1, "the first beat comes at once")
	assert_almost_eq(warning.pulse(), 1.0, 0.001, "the heart is big right on the beat")
	assert_gt(warning.heart_scale(), 1.0)
	_run(warning, 20.0, RULES.pulse_seconds + 0.05)
	assert_eq(warning.pulse(), 0.0, "the pulse fades between beats")
	assert_eq(warning.heart_scale(), 1.0)
	_run(warning, 20.0, RULES.beat_seconds * 3.0)
	assert_between(warning.beats, 4, 5, "about one beat per beat_seconds")


func test_ac115_it_stops_when_healed_or_fallen() -> void:
	var warning: LowHealthWarning = autofree(LowHealthWarning.new())
	_run(warning, 20.0, 1.0)
	var beats: int = warning.beats
	_run(warning, 60.0, RULES.beat_seconds * 3.0)
	assert_false(warning.active, "healed above the line")
	assert_eq(warning.beats, beats, "no more heartbeats")
	assert_eq(warning.pulse(), 0.0)
	_run(warning, 20.0, 0.05)
	assert_true(warning.active, "low again")
	_run(warning, 0.0, RULES.beat_seconds * 2.0)
	assert_false(warning.active, "a fallen hero's heart stops beating")


func test_ac115_the_heart_stays_rose_never_danger_red() -> void:
	var warning: LowHealthWarning = autofree(LowHealthWarning.new())
	warning.tick(10.0, MAX, 0.0)
	var peak: Color = warning.heart_color(SpareHeartPatch.FILL)
	assert_ne(peak, SpareHeartPatch.FILL, "lighter on the beat")
	assert_false(UiColors.is_danger(peak), "the beat colour is no danger colour")
	assert_false(UiColors.is_danger(SpareHeartPatch.FILL))


func _run(warning: LowHealthWarning, health: float, seconds: float) -> void:
	var step: float = 1.0 / 60.0
	var left: float = seconds
	while left > 0.0:
		warning.tick(health, MAX, step)
		left -= step
