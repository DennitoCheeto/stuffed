extends GutTest
## Spec 02 AC-24: every M2 number (weapons, items, evolutions, enemies, bosses, rerolls, schedule)
## lives in a .tres file under data/, so tuning never needs a code change (hard rule 8).

const RUN_SCENE: PackedScene = preload("res://src/run/run.tscn")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const RULES: RunRules = preload("res://data/run_rules.tres")
const WEAPONS_DIR: String = "res://data/weapons/"
const ENEMIES_DIR: String = "res://data/enemies/"
## Making one of these in code would put balance numbers in code.
const DATA_CLASSES: String = (
	"(EnemyStats|WeaponStats|WeaponLevel|UpgradeDef|EvolutionDef|UpgradePool|SpawnSchedule"
	+ "|SpawnEntry|EliteSpawn|EliteRules|BossDef|BigTedDef|SockKingDef|SpitAttack|DeathCloud"
	+ "|GiftBoxRules|RunRules|XpRules|HeroStats|FurnitureLayout|FurniturePiece)\\.new\\("
)


func _assert_from_data(resource: Resource, what: String) -> void:
	assert_not_null(resource, "%s is set" % what)
	if resource == null:
		return
	var path: String = resource.resource_path
	assert_true(path.begins_with("res://data/"), "%s comes from data/ (%s)" % [what, path])


func _files(dir: String) -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			paths.append(dir + file)
	return paths


func _scripts(dir: String) -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			paths.append(dir + file)
	for sub: String in DirAccess.get_directories_at(dir):
		paths.append_array(_scripts(dir + sub + "/"))
	return paths


## A property saved in the run scene for node `node_path` ("." is the run itself).
func _saved(node_path: String, property: String) -> Resource:
	var state: SceneState = RUN_SCENE.get_state()
	for node: int in state.get_node_count():
		if String(state.get_node_path(node)) != node_path:
			continue
		for index: int in state.get_node_property_count(node):
			if state.get_node_property_name(node, index) == property:
				return state.get_node_property_value(node, index) as Resource
	return null


func test_ac24_the_run_reads_its_rules_from_data() -> void:
	_assert_from_data(_saved(".", "rules"), "run rules")
	_assert_from_data(_saved(".", "upgrade_pool"), "upgrade pool")
	_assert_from_data(_saved(".", "gift_box_rules"), "gift box rules")
	_assert_from_data(_saved("./Spawner", "schedule"), "spawn schedule")


func test_ac24_weapons_items_and_evolutions_live_in_data() -> void:
	_assert_from_data(POOL.snack, "snack")
	var weapon_files: Array[String] = []
	for upgrade: UpgradeDef in POOL.upgrades:
		_assert_from_data(upgrade, String(upgrade.id))
		if upgrade.kind == UpgradeDef.Kind.WEAPON:
			_assert_from_data(upgrade.weapon, String(upgrade.id))
			weapon_files.append(upgrade.weapon.resource_path)
		else:
			assert_gt(upgrade.amount, 0.0, "%s does something" % upgrade.id)
			assert_gt(upgrade.max_level, 0, "%s has levels" % upgrade.id)
			assert_ne(upgrade.card_text, "", "%s has card text" % upgrade.id)
	for evolution: EvolutionDef in POOL.evolutions:
		_assert_from_data(evolution, String(evolution.evolved.id))
		_assert_from_data(evolution.evolved, String(evolution.evolved.id))
		assert_not_null(POOL.find(evolution.weapon), "%s is in the pool" % evolution.weapon)
		assert_not_null(POOL.find(evolution.partner), "%s is in the pool" % evolution.partner)
		weapon_files.append(evolution.evolved.resource_path)
	for path: String in _files(WEAPONS_DIR):
		assert_has(weapon_files, path, "%s is offered or evolved into" % path)


func test_ac24_every_weapon_level_has_sane_numbers() -> void:
	for path: String in _files(WEAPONS_DIR):
		var weapon: WeaponStats = load(path) as WeaponStats
		assert_gt(weapon.max_level(), 0, "%s has levels" % path)
		assert_ne(weapon.sound, &"", "%s has a sound" % path)
		for level: WeaponLevel in weapon.levels:
			assert_true(level.damage >= 0.0, "%s damage" % path)
			assert_gt(level.cooldown, 0.0, "%s cooldown" % path)
			assert_ne(level.card_text, "", "%s card text" % path)


func test_ac24_enemies_bosses_and_schedule_live_in_data() -> void:
	_assert_from_data(SCHEDULE.shambler, "shambler")
	_assert_from_data(SCHEDULE.elite_rules, "elite rules")
	for entry: SpawnEntry in SCHEDULE.entries:
		_assert_from_data(entry.enemy, "schedule entry")
		assert_lt(entry.start_seconds, RULES.goal_seconds, "comes before the goal")
	for elite: EliteSpawn in SCHEDULE.elites:
		_assert_from_data(elite.enemy, "elite")
	for boss: BossDef in [SCHEDULE.mini_boss, SCHEDULE.boss]:
		_assert_from_data(boss, "boss")
		_assert_from_data(boss.enemy, "boss body")
		assert_gt(boss.enemy.max_health, 0.0)
	for path: String in _files(ENEMIES_DIR):
		var enemy: EnemyStats = load(path) as EnemyStats
		assert_gt(enemy.max_health, 0.0, "%s health" % path)
		assert_gt(enemy.move_speed, 0.0, "%s speed" % path)
		assert_true(enemy.contact_damage >= 0.0, "%s damage" % path)


func test_ac24_rerolls_skips_and_banishes_live_in_data() -> void:
	assert_true(POOL.resource_path.begins_with("res://data/"))
	assert_gt(POOL.rerolls_per_run, 0)
	assert_gt(POOL.skips_per_run, 0)
	assert_gt(POOL.banishes_per_run, 0)
	assert_gt(POOL.max_weapons, 0)
	assert_gt(POOL.max_items, 0)


func test_ac24_no_game_code_makes_its_own_balance_data() -> void:
	var pattern: RegEx = RegEx.create_from_string(DATA_CLASSES)
	var offenders: Array[String] = []
	for path: String in _scripts("res://src/"):
		if pattern.search(FileAccess.get_file_as_string(path)) != null:
			offenders.append(path)
	assert_eq(offenders, [] as Array[String], "balance numbers come from .tres files")
