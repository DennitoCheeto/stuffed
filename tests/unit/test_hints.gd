extends GutTest
## M6-10 (spec 10 §6, §9): first-time hint rules, the note's words and keys, and the save.

const RULES: HintRules = preload("res://data/ui/hints.tres")
const SAVE: String = "user://test_hints_save.json"
const RUN_HINTS: PackedStringArray = [
	"move", "xp", "level_up", "gift_box", "floor_pickup", "evolution_ready", "boss", "way_home"
]

var _hints_were_on: bool = true


func before_each() -> void:
	_hints_were_on = GameSettings.hints
	GameSettings.hints = true
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_each() -> void:
	GameSettings.hints = _hints_were_on
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


func test_every_run_hint_has_a_text_and_no_written_out_key() -> void:
	for id: String in RUN_HINTS:
		var hint: HintDef = RULES.find(id)
		assert_not_null(hint, id)
		if hint == null:
			continue
		assert_ne(hint.text, "", id)
		for word: String in ["WASD", "Space", " R ", " S ", " B ", " E "]:
			assert_false(
				(" %s " % hint.text).contains(word), "%s spells out a key: %s" % [id, word]
			)
	assert_eq(RULES.basics.slice(0, RUN_HINTS.size()), RUN_HINTS, "the basics are move … can_build")
	assert_true(RULES.basics.has("town") and RULES.basics.has("can_build"))


func test_keys_next_to_each_other_share_one_tag() -> void:
	var parts: Array[Dictionary] = HintNote.parts("{move_up}{move_left} to walk · {dash} to dash")
	assert_eq(parts.size(), 4)
	assert_true(parts[0]["key"])
	assert_eq(parts[0]["text"], KeyBindings.key_text("move_up") + KeyBindings.key_text("move_left"))
	assert_eq(parts[1], {"text": " to walk · ", "key": false})
	assert_eq(parts[2], {"text": KeyBindings.key_text("dash"), "key": true})
	assert_eq(parts[3], {"text": " to dash", "key": false})


func test_a_rebound_key_shows_in_the_note() -> void:
	var before: Key = KeyBindings.key_of("dash")
	KeyBindings.bind("dash", KEY_K)
	var note: HintNote = autofree(HintNote.new(RULES.find("move")))
	assert_true(note.shown_text().contains("K"), note.shown_text())
	KeyBindings.bind("dash", before)


func test_done_hints_are_never_due_and_timed_out_ones_get_one_more_go() -> void:
	var save: TownSave = TownSave.new()
	assert_true(HintBook.is_due(save, "xp"))
	HintBook.timed_out(save, "xp")
	assert_true(HintBook.is_due(save, "xp"), "once more")
	HintBook.timed_out(save, "xp")
	assert_false(HintBook.is_due(save, "xp"), "the second time it's seen")
	assert_true(save.hints_once.is_empty())
	HintBook.mark_done(save, "boss")
	assert_false(HintBook.is_due(save, "boss"))
	GameSettings.hints = false
	assert_false(HintBook.is_due(save, "move"), "Hints off: nothing is due")
	GameSettings.hints = true
	HintBook.forget(save)
	assert_true(HintBook.is_due(save, "xp") and HintBook.is_due(save, "boss"), "Show hints again")


func test_seen_hints_survive_save_and_reload() -> void:
	var save: TownSave = TownSave.new()
	HintBook.mark_done(save, "move")
	HintBook.mark_done(save, "boss")
	HintBook.timed_out(save, "xp")
	assert_true(SaveStore.write(save))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.hints_seen, PackedStringArray(["move", "boss"]))
	assert_eq(loaded.hints_once, PackedStringArray(["xp"]))
	assert_eq(loaded.to_dict(), save.to_dict())


func test_an_older_save_with_a_town_knows_the_basics() -> void:
	var data: Dictionary = TownSave.new().to_dict()
	data["version"] = 7
	data.erase("hints_seen")
	data.erase("hints_once")
	data["runs_started"] = 3
	var returning: TownSave = TownSave.from_dict(data)
	for id: String in RULES.basics:
		assert_false(HintBook.is_due(returning, id), "%s is known" % id)
	assert_true(HintBook.is_due(returning, "siege"), "newer hints still show")
	data["runs_started"] = 0
	var fresh: TownSave = TownSave.from_dict(data)
	assert_true(fresh.hints_seen.is_empty(), "an older save with no town yet sees every hint")
	data["version"] = TownSave.VERSION
	data["runs_started"] = 3
	assert_true(TownSave.from_dict(data).hints_seen.is_empty(), "today's saves keep their list")
