extends GutTest
## Rescue rules (spec 03 §7, AC-44): which runs have a rescue, who and when.

const RULES: RescueRules = preload("res://data/town/rescue_rules.tres")
const SEEDS: int = 400


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_data_matches_the_spec() -> void:
	assert_eq(RULES.plushies.size(), 4, "room for 4 plushies in M3")
	assert_eq(RULES.first_run, 2, "from the second run on")
	assert_almost_eq(RULES.chance, 0.5, 0.001, "about one run in two")
	assert_eq(RULES.earliest_seconds, 120.0, "from 2:00")
	assert_eq(RULES.latest_seconds, 360.0, "until 6:00")
	assert_eq(RULES.fill_seconds, 3.0, "3 s to free it")
	var ids: PackedStringArray = []
	for plushie: PlushieDef in RULES.plushies:
		assert_false(plushie.id.is_empty(), "every plushie has an id")
		assert_false(plushie.display_name.is_empty(), "and a name tag")
		assert_false(ids.has(plushie.id), "%s is unique" % plushie.id)
		ids.append(plushie.id)
	assert_true(SfxBank.LENGTHS.has(RULES.help_sound), "the help squeak exists")
	assert_true(SfxBank.LENGTHS.has(RULES.freed_sound), "the freed sound exists")


func test_the_first_run_never_has_a_rescue() -> void:
	for seed_value: int in SEEDS:
		assert_null(RULES.plan(1, [], _rng(seed_value)), "run 1, seed %d" % seed_value)
		assert_null(RULES.plan(0, [], _rng(seed_value)), "no town")


func test_about_every_second_run_has_one_between_2_and_6_minutes() -> void:
	var with_rescue: int = 0
	for seed_value: int in SEEDS:
		var plan: RescuePlan = RULES.plan(2 + seed_value % 5, [], _rng(seed_value))
		if plan == null:
			continue
		with_rescue += 1
		assert_between(plan.at_seconds, 120.0, 360.0, "seed %d" % seed_value)
	assert_between(with_rescue / float(SEEDS), 0.4, 0.6, "about half the runs")


func test_a_plushie_already_home_never_comes_again() -> void:
	var home: PackedStringArray = ["bambam", "bobo", "pip"]
	for seed_value: int in SEEDS:
		var plan: RescuePlan = RULES.plan(3, home, _rng(seed_value))
		if plan != null:
			assert_eq(plan.plushie.id, "robbar", "only the one still out there")


func test_no_more_rescues_once_all_are_home() -> void:
	var home: PackedStringArray = []
	for plushie: PlushieDef in RULES.plushies:
		home.append(plushie.id)
	for seed_value: int in SEEDS:
		assert_null(RULES.plan(5, home, _rng(seed_value)))
	assert_null(RULES.pick_plushie(home, _rng(1)))


func test_find_by_id() -> void:
	assert_eq(RULES.find("bambam").display_name, "BamBam")
	assert_null(RULES.find("nobody"))


func test_run_log_writes_the_rescue() -> void:
	var result: RunResult = RunResult.new()
	assert_null(RunLog.to_entry(result)["rescue"], "null when no rescue appeared")
	assert_eq(result.rescued_plushie(), "")
	result.rescue = {"plushie": "bambam", "time": 150.04, "freed": true, "freed_at": 158.06}
	var entry: Dictionary = RunLog.to_entry(result)["rescue"]
	assert_eq(entry["plushie"], "bambam")
	assert_almost_eq(float(entry["time"]), 150.0, 0.001)
	assert_true(entry["freed"])
	assert_almost_eq(float(entry["freed_at"]), 158.1, 0.001)
	assert_eq(result.rescued_plushie(), "bambam")
	result.rescue = {"plushie": "bambam", "time": 150.0, "freed": false, "freed_at": -1.0}
	assert_null(RunLog.to_entry(result)["rescue"]["freed_at"], "never freed")
	assert_eq(result.rescued_plushie(), "", "not freed = not brought home")


func test_a_freed_plushie_is_banked_whatever_share_is_kept() -> void:
	var haul: RunHaul = RunHaul.new()
	haul.rescued = "pip"
	var town: TownSave = TownSave.new()
	town.bank(haul, 0.5)
	assert_eq(town.plushies["pip"], "waiting", "waits in the tent for a Hospital bed")
