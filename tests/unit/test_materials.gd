extends GutTest
## Unit tests for the run's materials (spec 03 §3, §10, AC-39, AC-40): which kills, boxes and
## wins give coins, stuffing and thread, the keep share, and the run log fields.

const RULES: MaterialRules = preload("res://data/town/material_rules.tres")
const ENEMY_FILES: Array[String] = [
	"res://data/enemies/shambler.tres",
	"res://data/enemies/runner.tres",
	"res://data/enemies/spitter.tres",
	"res://data/enemies/tank.tres",
	"res://data/enemies/bloater.tres",
]
const BOSS_FILES: Array[String] = [
	"res://data/bosses/big_ted.tres",
	"res://data/bosses/sock_puppet_king.tres",
]


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _result(won: bool, ending: String) -> RunResult:
	var result: RunResult = RunResult.new()
	result.won = won
	result.ending = ending
	return result


func test_ac39_every_zombie_type_and_boss_has_its_own_coins() -> void:
	for file: String in ENEMY_FILES:
		var stats: EnemyStats = load(file)
		var reward: MaterialReward = RULES.kill_reward(stats.display_name)
		assert_eq(reward.source, stats.display_name, "%s has an entry" % file)
		assert_gt(reward.coins, 0, "%s gives coins" % file)
	for file: String in BOSS_FILES:
		var boss: BossDef = load(file)
		var reward: MaterialReward = RULES.kill_reward(boss.enemy.display_name)
		assert_eq(reward.source, boss.enemy.display_name, "%s has an entry" % file)


func test_ac39_bigger_zombies_and_bosses_give_more() -> void:
	var shambler: int = RULES.kill_reward("Shambler").coins
	assert_gt(RULES.kill_reward("Tank").coins, shambler)
	assert_gt(RULES.kill_reward("Bloater").coins, shambler)
	assert_gt(RULES.kill_reward("Big Ted").coins, RULES.kill_reward("Tank").coins)
	assert_gt(RULES.kill_reward("Sock Puppet King").coins, RULES.kill_reward("Big Ted").coins)


func test_ac39_stuffing_and_thread_come_from_the_spec_sources() -> void:
	assert_eq(RULES.kill_reward("Shambler").stuffing, 0, "normal zombies: coins only")
	assert_eq(RULES.kill_reward("Shambler").thread, 0)
	for big: String in ["Tank", "Bloater"]:
		var reward: MaterialReward = RULES.kill_reward(big)
		assert_gt(reward.stuffing, 0, big)
		assert_lt(reward.stuffing_chance, 1.0, "%s: only now and then" % big)
		assert_eq(reward.thread, 0, big)
	assert_gt(RULES.elite_extra.stuffing, 0, "every elite gives stuffing")
	assert_eq(RULES.elite_extra.stuffing_chance, 1.0)
	for boss: String in ["Big Ted", "Sock Puppet King"]:
		assert_gt(RULES.kill_reward(boss).stuffing, 0, boss)
		assert_gt(RULES.kill_reward(boss).thread, 0, boss)
	assert_gt(RULES.gift_box.thread, 0, "gift boxes give thread")
	assert_gt(RULES.big_gift_box.thread, 0)


func test_ac39_a_kill_gives_the_data_amounts() -> void:
	var amounts: Dictionary[String, int] = RULES.for_kill("Shambler", false, _rng())
	assert_eq(amounts, {"coins": RULES.kill_reward("Shambler").coins})
	var king: Dictionary[String, int] = RULES.for_kill("Sock Puppet King", false, _rng())
	var reward: MaterialReward = RULES.kill_reward("Sock Puppet King")
	assert_eq(king.get("coins", 0), reward.coins)
	assert_eq(king.get("stuffing", 0), reward.stuffing)
	assert_eq(king.get("thread", 0), reward.thread)


func test_ac39_an_elite_adds_its_extra_on_top() -> void:
	var amounts: Dictionary[String, int] = RULES.for_kill("Shambler", true, _rng())
	var coins: int = RULES.kill_reward("Shambler").coins + RULES.elite_extra.coins
	assert_eq(amounts.get("coins", 0), coins)
	assert_eq(amounts.get("stuffing", 0), RULES.elite_extra.stuffing)


func test_ac39_an_unknown_type_falls_back_to_the_other_kill() -> void:
	assert_eq(RULES.kill_reward("Something new"), RULES.other_kill)
	assert_gt(RULES.other_kill.coins, 0)


func test_stuffing_chance_is_rolled() -> void:
	var reward: MaterialReward = MaterialReward.new()
	reward.coins = 1
	reward.stuffing = 2
	reward.stuffing_chance = 0.0
	assert_false(reward.roll(_rng()).has("stuffing"), "chance 0: never")
	reward.stuffing_chance = 1.0
	assert_eq(reward.roll(_rng()).get("stuffing", 0), 2, "chance 1: always")
	reward.stuffing_chance = 0.5
	var rng: RandomNumberGenerator = _rng(7)
	var got: int = 0
	for i: int in 1000:
		if reward.roll(rng).has("stuffing"):
			got += 1
	assert_between(got, 400, 600, "about half")


func test_stuffing_from_tanks_follows_the_chance() -> void:
	var rng: RandomNumberGenerator = _rng(3)
	var reward: MaterialReward = RULES.kill_reward("Tank")
	var got: int = 0
	var kills: int = 2000
	for i: int in kills:
		got += RULES.for_kill("Tank", false, rng).get("stuffing", 0)
	var expected: float = kills * reward.stuffing_chance * reward.stuffing
	assert_almost_eq(float(got), expected, expected * 0.25)


func test_gift_boxes_give_thread() -> void:
	assert_eq(RULES.for_gift_box(false, _rng()).get("thread", 0), RULES.gift_box.thread)
	assert_eq(RULES.for_gift_box(true, _rng()).get("thread", 0), RULES.big_gift_box.thread)


func test_ac40_keep_share_per_ending() -> void:
	assert_eq(RULES.keep_share(_result(true, "ended")), 1.0, "beat the King")
	assert_eq(RULES.keep_share(_result(true, "died")), 1.0, "died in endless after the King")
	assert_eq(RULES.keep_share(_result(true, "quit")), 1.0, "gave up in endless")
	assert_eq(RULES.keep_share(_result(false, "way_home")), 1.0, "Way Home portal")
	assert_eq(RULES.keep_share(_result(false, "died")), 0.5, "stuffed")
	assert_eq(RULES.keep_share(_result(false, "quit")), 0.5, "gave up")


func test_ac40_half_is_rounded_up_per_material() -> void:
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 31)
	haul.add("stuffing", 1)
	haul.add("thread", 4)
	var kept: Dictionary[String, int] = haul.kept(RULES.keep_share(_result(false, "died")))
	assert_eq(kept, {"coins": 16, "stuffing": 1, "thread": 2})
	assert_eq(haul.kept(RULES.keep_share(_result(true, "ended"))), haul.materials)


func test_ac40_the_victory_bonus_gives_coins_and_thread() -> void:
	var bonus: Dictionary[String, int] = RULES.victory_bonus.roll(_rng())
	assert_gt(bonus.get("coins", 0), 0)
	assert_gt(bonus.get("thread", 0), 0)


func test_run_end_names_how_the_run_ended() -> void:
	assert_eq(_result(true, "ended").run_end(), "king")
	assert_eq(_result(true, "died").run_end(), "king", "endless after the King")
	assert_eq(_result(false, "way_home").run_end(), "way_home")
	assert_eq(_result(false, "died").run_end(), "died")
	assert_eq(_result(false, "quit").run_end(), "gave_up")


func test_run_log_has_the_material_fields() -> void:
	var result: RunResult = _result(false, "quit")
	result.materials_collected = {"coins": 31, "thread": 1}
	result.materials_kept = {"coins": 16, "thread": 1}
	var entry: Dictionary = RunLog.to_entry(result)
	assert_eq(entry["materials_collected"], {"coins": 31, "thread": 1})
	assert_eq(entry["materials_kept"], {"coins": 16, "thread": 1})
	assert_eq(entry["run_end"], "gave_up")


func test_burst_piece_counts_stay_small() -> void:
	assert_eq(MaterialBurst.piece_count("coins", 0), 0)
	assert_eq(MaterialBurst.piece_count("coins", 3), 1)
	assert_eq(MaterialBurst.piece_count("coins", 25), 3)
	assert_eq(MaterialBurst.piece_count("coins", 5000), MaterialBurst.MAX_PIECES)
	assert_eq(MaterialBurst.piece_count("thread", 3), 3)
