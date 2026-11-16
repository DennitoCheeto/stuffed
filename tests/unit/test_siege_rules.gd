extends GutTest
## Night siege rules (spec 07 §3, §6, §8, AC-74, AC-81): when the warning appears, how a night
## ticks the countdown, what a siege gives, what a repair costs, and that the siege fields
## survive saving (older saves get no warning).

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const SAVE: String = "user://test_unit_siege_save.json"


func before_each() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _town(built: int) -> TownSave:
	var town: TownSave = TownSave.new()
	var ids: PackedStringArray = ["toy_box_armory", "lucky_jar", "watchtower", "snack_bar"]
	for i: int in built:
		town.building_levels[ids[i]] = 1
	return town


## Coins, stuffing, thread of `haul`.
func _amounts(haul: Dictionary[String, int]) -> Array[int]:
	return [haul.get("coins", 0), haul.get("stuffing", 0), haul.get("thread", 0)]


func test_the_numbers_come_from_data() -> void:
	assert_eq(RULES.first_trigger_buildings, 2)
	assert_eq(RULES.first_nights, 2)
	assert_eq(RULES.nights_between, 3)
	assert_eq(RULES.wave_list.size(), 3)
	assert_eq(_amounts(RULES.reward), [400, 20, 4])
	assert_almost_eq(RULES.repair_share, 0.25, 0.001)


func test_ac74_no_warning_before_two_buildings() -> void:
	var town: TownSave = _town(1)
	assert_false(RULES.warn_if_ready(town))
	assert_eq(town.siege_nights, -1, "nothing to defend yet")
	RULES.night_passed(town)
	assert_eq(town.siege_nights, -1, "nights don't count before the warning")
	assert_false(RULES.is_warned(town))
	assert_false(RULES.is_due(town))


func test_ac74_the_warning_appears_at_two_buildings_with_two_nights() -> void:
	var town: TownSave = _town(2)
	assert_true(RULES.warn_if_ready(town))
	assert_eq(town.siege_nights, 2)
	assert_false(RULES.warn_if_ready(town), "only once")
	assert_eq(town.siege_nights, 2)


func test_ac74_every_night_ticks_down_by_one_until_due() -> void:
	var town: TownSave = _town(2)
	RULES.warn_if_ready(town)
	RULES.night_passed(town)
	assert_eq(town.siege_nights, 1)
	assert_false(RULES.is_due(town))
	RULES.night_passed(town)
	assert_eq(town.siege_nights, 0)
	assert_true(RULES.is_due(town))
	RULES.night_passed(town)
	assert_eq(town.siege_nights, 0, "never below 0: still due")


func test_ac74_a_night_with_two_buildings_and_no_warning_starts_the_countdown() -> void:
	var town: TownSave = _town(3)
	RULES.night_passed(town)
	assert_eq(town.siege_nights, 2, "the warning appears, the night doesn't tick it yet")


func test_ac74_after_a_siege_the_countdown_starts_again() -> void:
	var town: TownSave = _town(2)
	town.siege_nights = 0
	RULES.siege_ended(town, true)
	assert_eq(town.siege_nights, 3)
	assert_eq(town.sieges_played, 1)
	assert_eq(town.sieges_won, 1)
	town.siege_nights = 0
	RULES.siege_ended(town, false)
	assert_eq(town.siege_nights, 3, "won or lost")
	assert_eq(town.sieges_played, 2)
	assert_eq(town.sieges_won, 1)


func test_rewards_grow_with_every_siege() -> void:
	assert_eq(_amounts(RULES.reward_for(1)), [400, 20, 4])
	assert_eq(_amounts(RULES.reward_for(2)), [500, 25, 5], "+25%")
	var lost: Dictionary[String, int] = RULES.consolation_for(1)
	assert_eq(lost["coins"], 120, "30% of the reward")
	assert_eq(lost["stuffing"], 6)
	assert_gt(RULES.zombie_scale(3), RULES.zombie_scale(2))
	assert_almost_eq(RULES.zombie_scale(1), 1.0, 0.001)
	assert_almost_eq(RULES.health_scale(1), 1.0, 0.001)


func test_repair_costs_a_quarter_of_the_level_coins() -> void:
	var level: BuildingLevel = BuildingLevel.new()
	level.coins = 1500
	assert_eq(RULES.repair_cost(level)["coins"], 375)
	level.coins = 201
	assert_eq(RULES.repair_cost(level)["coins"], 51, "rounded up")


func test_calendar_and_end_screen_texts() -> void:
	assert_eq(RULES.calendar_line(2), "The horde arrives in 2 nights.")
	assert_eq(RULES.calendar_line(1), "The horde arrives in 1 night.")
	assert_eq(RULES.calendar_line(0), "The horde arrives tonight!")
	assert_eq(RULES.end_line(1), "1 night until the horde!")
	assert_eq(RULES.end_line(3), "3 nights until the horde!")
	assert_eq(RULES.end_line(-1), "", "no warning yet: no line")


func test_ac81_siege_fields_survive_save_and_reload() -> void:
	var town: TownSave = _town(2)
	town.siege_nights = 0
	town.sieges_played = 4
	town.sieges_won = 3
	town.damaged = PackedStringArray(["lucky_jar", "watchtower"])
	assert_true(SaveStore.write(town))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.to_dict(), town.to_dict())
	assert_true(RULES.is_due(loaded), "a due siege is still due after reopening the game")
	assert_true(loaded.is_damaged("watchtower"))


func test_ac81_an_older_save_has_no_warning_yet() -> void:
	var data: Dictionary = _town(3).to_dict()
	data["version"] = 4
	for key: String in ["siege_nights", "sieges_played", "sieges_won", "damaged"]:
		data.erase(key)
	var loaded: TownSave = TownSave.from_dict(data)
	assert_eq(loaded.siege_nights, -1)
	assert_eq(loaded.sieges_played, 0)
	assert_eq(loaded.damaged.size(), 0)
	assert_true(RULES.warn_if_ready(loaded), "the countdown appears as usual")
