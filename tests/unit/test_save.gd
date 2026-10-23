extends GutTest
## The town save (spec 03 §9, AC-47): save → reload → compare (hard rule 10), the backup for a
## damaged save, "Start over", and how a run's haul is banked.

const SAVE: String = "user://test_unit_save.json"
const RULES: MaterialRules = preload("res://data/town/material_rules.tres")


func before_each() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


## A town with something in every field.
func _full_town() -> TownSave:
	var town: TownSave = TownSave.new()
	town.materials = {"coins": 1234, "stuffing": 56, "thread": 7}
	town.building_levels = {"armory": 2, "lucky_jar": 1, "watchtower": 0}
	town.plushies = {"bambam": "in_town", "frog": "waiting"}
	town.mark_seen("weapons", "peel_boomerang")
	town.mark_seen("weapons", "banana_split")
	town.mark_seen("enemies", "runner")
	town.runs_started = 9
	town.start_weapon = "yarn_cannon"
	town.revealed = PackedStringArray(["watchtower", "snack_bar"])
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 40)
	haul.rescued = "piglet"
	town.unfinished_run = haul.to_dict()
	return town


func _write_text(file_path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_ac47_save_reload_gives_the_same_town() -> void:
	var town: TownSave = _full_town()
	assert_true(SaveStore.write(town))
	var loaded: TownSave = SaveStore.read()
	assert_eq(SaveStore.last_source, SaveStore.Source.MAIN)
	assert_eq(loaded.to_dict(), town.to_dict())
	assert_eq(loaded.material("coins"), 1234)
	assert_eq(loaded.building_level("armory"), 2)
	assert_eq(loaded.building_level("party_shop"), 0, "never built = ruin")
	assert_eq(loaded.plushies["frog"], "waiting")
	assert_true(loaded.has_seen("weapons", "banana_split"))
	assert_false(loaded.has_seen("weapons", "zipper_ray"))
	assert_eq(loaded.runs_started, 9)
	assert_eq(loaded.start_weapon, "yarn_cannon")
	assert_eq(loaded.revealed, PackedStringArray(["watchtower", "snack_bar"]))
	assert_eq(RunHaul.from_dict(loaded.unfinished_run).amount("coins"), 40)


func test_ac47_no_save_means_a_new_town() -> void:
	assert_false(SaveStore.exists())
	var town: TownSave = SaveStore.read()
	assert_eq(SaveStore.last_source, SaveStore.Source.NEW)
	assert_eq(town.to_dict(), TownSave.new().to_dict())


func test_ac47_a_damaged_save_falls_back_to_the_backup() -> void:
	var first: TownSave = _full_town()
	SaveStore.write(first)
	var second: TownSave = _full_town()
	second.materials["coins"] = 9999
	SaveStore.write(second)
	_write_text(SaveStore.path, '{"version": 1, "materials": {"coi')
	var loaded: TownSave = SaveStore.read()
	assert_eq(SaveStore.last_source, SaveStore.Source.BACKUP)
	assert_eq(loaded.material("coins"), 1234, "the backup is the save before the last write")


func test_ac47_a_save_without_its_version_is_not_trusted() -> void:
	SaveStore.write(_full_town())
	SaveStore.write(_full_town())
	_write_text(SaveStore.path, '{"materials": {"coins": 5}}')
	assert_eq(SaveStore.read().material("coins"), 1234)


func test_ac47_older_saves_with_missing_fields_still_load() -> void:
	_write_text(SaveStore.path, '{"version": 1, "materials": {"coins": 12}}')
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.material("coins"), 12)
	assert_eq(loaded.runs_started, 0)
	assert_true(loaded.unfinished_run.is_empty())


func test_ac47_start_over_removes_save_and_backup() -> void:
	SaveStore.write(_full_town())
	SaveStore.write(_full_town())
	assert_true(FileAccess.file_exists(SaveStore.backup_path()))
	SaveStore.delete_all()
	assert_false(SaveStore.exists())
	assert_eq(SaveStore.read().material("coins"), 0)


func test_banking_keeps_the_share_rounded_up_and_takes_the_plushie_in() -> void:
	var town: TownSave = TownSave.new()
	town.materials["coins"] = 100
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 31)
	haul.add("stuffing", 3)
	haul.rescued = "bambam"
	town.bank(haul, RULES.keep_share_lost)
	assert_eq(town.material("coins"), 116, "half of 31 rounded up = 16")
	assert_eq(town.material("stuffing"), 2)
	assert_eq(town.plushies["bambam"], "waiting")
	town.bank(haul, RULES.keep_share_won)
	assert_eq(town.material("coins"), 147)


func test_keep_share_follows_the_result() -> void:
	var result: RunResult = RunResult.new()
	assert_eq(RULES.keep_share(result), 0.5)
	result.won = true
	assert_eq(RULES.keep_share(result), 1.0)


func test_ac47_an_unfinished_run_counts_as_given_up() -> void:
	var town: TownSave = TownSave.new()
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 9)
	haul.rescued = "frog"
	town.unfinished_run = haul.to_dict()
	assert_true(town.settle_unfinished_run(RULES.keep_share_lost))
	assert_eq(town.material("coins"), 5)
	assert_eq(town.plushies["frog"], "waiting", "a freed plushie is always kept")
	assert_true(town.unfinished_run.is_empty())
	assert_false(town.settle_unfinished_run(RULES.keep_share_lost), "only once")
