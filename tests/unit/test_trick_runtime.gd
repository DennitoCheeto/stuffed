extends GutTest
## Trick runtime (spec 06 §4, §6, §7, AC-70, AC-73): TownPerks carries the bought tricks into the
## run, the run log writes them, and the trick banner never uses a danger colour.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")


func _town_with(ids: Array[String]) -> TownSave:
	var town: TownSave = TownSave.new()
	town.tricks = PackedStringArray(ids)
	return town


func test_ac70_perks_carry_the_bought_tricks_in_branch_order() -> void:
	var perks: TownPerks = TownPerks.from_save(_town_with(["spare_stuffing", "head_start"]), LAYOUT)
	assert_eq(perks.trick_ids(), PackedStringArray(["head_start", "spare_stuffing"]))
	assert_true(perks.has_trick(&"head_start"))
	assert_false(perks.has_trick(&"picnic"))
	assert_eq(perks.trick(&"spare_stuffing").display_name, "Spare Stuffing")


func test_ac70_unknown_ids_in_the_save_are_ignored() -> void:
	var perks: TownPerks = TownPerks.from_save(_town_with(["no_such_trick"]), LAYOUT)
	assert_eq(perks.tricks.size(), 0)


func test_ac70_a_run_without_a_town_has_no_tricks() -> void:
	assert_eq(TownPerks.new().trick_ids(), PackedStringArray())


func test_ac70_the_log_entry_has_tricks_and_rounded_first_fires() -> void:
	var result: RunResult = RunResult.new()
	result.tricks = PackedStringArray(["picnic"])
	result.trick_moments = [{"id": "picnic", "time": 61.27, "player": 1}]
	var entry: Dictionary = RunLog.to_entry(result)
	assert_eq(entry["tricks"], ["picnic"])
	assert_eq(entry["trick_moments"][0]["id"], "picnic")
	assert_almost_eq(float(entry["trick_moments"][0]["time"]), 61.3, 0.001)
	assert_eq(int(entry["trick_moments"][0]["player"]), 1)


func test_ac73_trick_banner_colours_are_never_danger() -> void:
	for index: int in UiColors.PLAYER_MARKERS.size():
		var color: Color = TrickBanner.color_for(index)
		assert_false(UiColors.is_danger(color), "player %d: %s" % [index + 1, color.to_html()])


func test_dev_menu_text_lists_trick_names() -> void:
	var perks: TownPerks = TownPerks.from_save(_town_with(["picnic", "head_start"]), LAYOUT)
	assert_eq(DevMenu.tricks_text(perks), "Tricks on: Head Start, Picnic")
	assert_eq(DevMenu.tricks_text(TownPerks.new()), "Tricks on: none")
