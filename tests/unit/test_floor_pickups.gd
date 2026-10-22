extends GutTest
## Spec 02b §4, AC-31: the floor pickup drop rules (first drop time, minimum gap, at most 2 on
## the floor, odds per kind) and their data.

const RULES: FloorPickupRules = preload("res://data/floor_pickup_rules.tres")


## The data rules, but every kill drops once a drop is due (so the timing is easy to test).
func _sure_rules() -> FloorPickupRules:
	var rules: FloorPickupRules = RULES.duplicate()
	rules.drop_chance = 1.0
	return rules


func _drops(rules: FloorPickupRules, seed_value: int = 1) -> FloorPickupDrops:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorPickupDrops.new(rules, rng)


func _kind(id: StringName, weight: float) -> FloorPickupDef:
	var kind: FloorPickupDef = FloorPickupDef.new()
	kind.id = id
	kind.weight = weight
	return kind


func test_ac31_nothing_drops_in_the_first_seconds() -> void:
	for seed_value: int in range(1, 30):
		var drops: FloorPickupDrops = _drops(_sure_rules(), seed_value)
		var t: float = 0.0
		while t < RULES.first_drop_after:
			assert_null(drops.roll(t, 0), "nothing at %.1f s (seed %d)" % [t, seed_value])
			t += 0.5
		var latest: float = RULES.first_drop_after + RULES.gap_spread
		assert_not_null(drops.roll(latest, 0), "but it comes by %.0f s" % latest)


func test_ac31_drops_are_never_closer_than_the_minimum_gap() -> void:
	var drops: FloorPickupDrops = _drops(_sure_rules())
	var last: float = -INF
	var count: int = 0
	var t: float = 0.0
	while t < 900.0:
		if drops.roll(t, 0) != null:
			assert_gte(t - last, RULES.min_gap, "gap before the drop at %.1f s" % t)
			last = t
			count += 1
		t += 0.25
	assert_gt(count, 8, "drops keep coming")


func test_ac31_never_more_than_two_on_the_floor() -> void:
	assert_eq(RULES.max_on_floor, 2, "spec: at most 2")
	var drops: FloorPickupDrops = _drops(_sure_rules())
	assert_null(drops.roll(500.0, 2), "two lie around: nothing new")
	assert_null(drops.roll(500.0, 3))
	assert_not_null(drops.roll(500.0, 1), "one grabbed: the next can drop")


func test_ac31_about_one_per_minute_with_normal_kills() -> void:
	var drops: FloorPickupDrops = _drops(RULES, 7)
	var times: Array[float] = []
	var t: float = 0.0
	while t < 3600.0:
		if drops.roll(t, 0) != null:
			times.append(t)
		t += 0.5
	var average: float = (times[-1] - times[0]) / (times.size() - 1)
	assert_between(average, 50.0, 75.0, "about one a minute (two kills a second)")


func test_ac31_kinds_follow_their_weights() -> void:
	var rules: FloorPickupRules = FloorPickupRules.new()
	rules.kinds = [_kind(&"a", 40.0), _kind(&"b", 30.0), _kind(&"c", 30.0)]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var counts: Dictionary[StringName, int] = {&"a": 0, &"b": 0, &"c": 0}
	for i: int in 10000:
		counts[rules.pick(rng).id] += 1
	assert_almost_eq(counts[&"a"] / 10000.0, 0.4, 0.03)
	assert_almost_eq(counts[&"b"] / 10000.0, 0.3, 0.03)
	assert_almost_eq(counts[&"c"] / 10000.0, 0.3, 0.03)


func test_ac32_big_magnet_is_in_the_data_with_a_look_and_a_sound() -> void:
	var magnet: FloorPickupDef = RULES.find(&"magnet")
	assert_not_null(magnet, "the Big Magnet can drop")
	if magnet == null:
		return
	assert_eq(magnet.banner, "BIG MAGNET!")
	assert_eq(magnet.weight, 40.0, "spec odds: Magnet 40%")
	assert_true(SfxBank.LENGTHS.has(magnet.sound), "its own sound")
	var parts: Dictionary[StringName, FeltPiece] = FloorPickupLook.make_parts()
	assert_true(parts.has(FloorPickupLook.key(magnet.id)), "its own felt look")
	for part: FeltPiece in parts.values():
		part.free()


func test_ac34_snow_globe_is_in_the_data_with_a_look_and_a_sound() -> void:
	var globe: FloorPickupDef = RULES.find(&"snow_globe")
	assert_not_null(globe, "the Snow Globe can drop")
	if globe == null:
		return
	assert_eq(globe.banner, "SNOW GLOBE!")
	assert_eq(globe.weight, 30.0, "spec odds: Snow Globe 30%")
	assert_true(SfxBank.LENGTHS.has(globe.sound), "its own sound")
	assert_true(SfxBank.LENGTHS.has(&"ice_crack"), "and a crack when the ice breaks")
	var parts: Dictionary[StringName, FeltPiece] = FloorPickupLook.make_parts()
	assert_true(parts.has(FloorPickupLook.key(globe.id)), "its own felt look")
	for part: FeltPiece in parts.values():
		part.free()


func test_ac34_freeze_numbers_live_in_the_data() -> void:
	assert_eq(RULES.freeze_seconds, 5.0, "spec: frozen for 5 s")
	assert_eq(RULES.freeze_boss_speed, 0.5, "spec: bosses at half speed")
	assert_eq(RULES.freeze_crack_seconds, 1.0, "spec: the ice cracks in the last second")


func test_ac35_party_popper_is_in_the_data_with_a_look_and_a_sound() -> void:
	var popper: FloorPickupDef = RULES.find(&"party_popper")
	assert_not_null(popper, "the Party Popper can drop")
	if popper == null:
		return
	assert_eq(popper.banner, "PARTY POPPER!")
	assert_eq(popper.weight, 30.0, "spec odds: Party Popper 30%")
	assert_true(SfxBank.LENGTHS.has(popper.sound), "its own sound")
	var parts: Dictionary[StringName, FeltPiece] = FloorPickupLook.make_parts()
	assert_true(parts.has(FloorPickupLook.key(popper.id)), "its own felt look")
	for part: FeltPiece in parts.values():
		part.free()


func test_ac35_popper_numbers_live_in_the_data() -> void:
	assert_between(RULES.popper_elite_share, 0.2, 0.6, "elites lose a big chunk")
	assert_between(RULES.popper_boss_share, 0.01, 0.1, "bosses take a small hit")
	assert_gt(RULES.popper_seconds, 0.5, "the confetti stays long enough to see")
