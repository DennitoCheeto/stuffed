extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §4.1, AC-52): in a real run every hit and kill lands on the weapon (and
## player) that dealt it, the Party Popper and the King's victory pops get their own rows, an
## evolved weapon keeps its old weapon's numbers, and everything adds up to the run's kills and
## damage. The run log has the `weapons` field.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Seconds the weapons get to work on the zombies.
const FIGHT_SECONDS: float = 4.0

var run: Run


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	for player: Player in Players.all(run.get_tree()):
		player.invincible = true
	return run


## A ring of shamblers around `at`.
func _ring(at: Vector2, count: int, distance: float) -> void:
	for i: int in count:
		run.enemies.spawn(SHAMBLER, at + Vector2.from_angle(TAU * i / count) * distance)


func _sum(rows: Array[Dictionary], key: String) -> int:
	var total: int = 0
	for row: Dictionary in rows:
		total += int(row[key])
	return total


func _assert_adds_up() -> void:
	var tally: WeaponTally = run.enemies.tally
	var kills: int = 0
	var damage: float = 0.0
	for row: WeaponTallyEntry in tally.entries:
		kills += row.kills
		damage += row.damage
	assert_eq(kills, run.enemies.kills, "the rows' kills add up to the run's kills")
	assert_almost_eq(damage, tally.total_damage, 0.01, "the rows' damage adds up to the total")


func test_ac52_hits_kills_and_time_held_per_weapon_add_up() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var start: float = run.elapsed
	_ring(banane.global_position, 10, 160.0)
	await wait_seconds(FIGHT_SECONDS)
	var tally: WeaponTally = run.enemies.tally
	var boomerang: WeaponTallyEntry = tally.find(0, &"peel_boomerang")
	assert_not_null(boomerang, "a row for the starting weapon")
	if boomerang == null:
		return
	assert_gt(boomerang.damage, 0.0, "it did damage")
	assert_gt(boomerang.kills, 0, "it stuffed zombies")
	assert_almost_eq(boomerang.seconds, run.elapsed - start, 0.3, "held the whole fight")
	assert_gt(tally.total_damage, 0.0)
	_assert_adds_up()
	_ring(banane.global_position, 5, 300.0)
	run.party_pop(banane)
	var popper: WeaponTallyEntry = tally.find(-1, WeaponTally.PARTY_POPPER)
	assert_not_null(popper, "the Party Popper has its own row")
	if popper != null:
		assert_gte(popper.kills, 5, "its pops count for it")
		assert_false(popper.is_weapon)
	_assert_adds_up()


func test_ac52_an_evolved_weapon_includes_its_old_weapon() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_ring(banane.global_position, 8, 160.0)
	await wait_seconds(FIGHT_SECONDS / 2.0)
	var before: WeaponTallyEntry = run.enemies.tally.find(0, &"peel_boomerang")
	assert_not_null(before)
	if before == null:
		return
	var old_damage: float = before.damage
	var old_seconds: float = before.seconds
	assert_gt(old_damage, 0.0, "the boomerang hit something first")
	var evolution: EvolutionDef = run.upgrade_pool.evolution_into(&"banana_split")
	banane.evolve(evolution)
	_ring(banane.global_position, 8, 160.0)
	await wait_seconds(FIGHT_SECONDS / 2.0)
	var tally: WeaponTally = run.enemies.tally
	assert_null(tally.find(0, &"peel_boomerang"), "the old weapon has no row of its own")
	var split: WeaponTallyEntry = tally.find(0, &"banana_split")
	assert_not_null(split, "one row for the Banana Split")
	if split == null:
		return
	assert_true(split.evolved, "marked EVO")
	assert_gt(split.damage, old_damage, "the boomerang's damage plus its own")
	assert_gt(split.seconds, old_seconds, "time held goes on")
	_assert_adds_up()


func test_ac52_two_players_get_their_own_rows() -> void:
	main.player_count = 2
	await _quiet_run()
	var players: Array[Player] = Players.all(run.get_tree())
	assert_eq(players.size(), 2)
	disarm(players[0])
	var second: Player = players[1]
	_ring(second.global_position, 8, 160.0)
	await wait_seconds(FIGHT_SECONDS)
	var tally: WeaponTally = run.enemies.tally
	var theirs: WeaponTallyEntry = tally.find(1, &"peel_boomerang")
	assert_not_null(theirs, "player 2's boomerang has its own row")
	if theirs != null:
		assert_gt(theirs.kills, 0, "player 2 stuffed zombies")
	var mine: WeaponTallyEntry = tally.find(0, &"peel_boomerang")
	if mine != null:
		assert_eq(mine.kills, 0, "player 1 had no weapon after the first frame")
	_assert_adds_up()


func test_ac52_the_victory_pops_and_the_run_log_add_up() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_ring(banane.global_position, 6, 160.0)
	await wait_seconds(FIGHT_SECONDS / 2.0)
	_ring(banane.global_position, 6, 900.0)
	beat_the_boss(run)
	await wait_for_goal_screen(run)
	var pops: WeaponTallyEntry = run.enemies.tally.find(-1, WeaponTally.GOAL_POPS)
	assert_not_null(pops, "the victory pops have their own row")
	_assert_adds_up()
	run.goal_screen.choose_end()
	await wait_physics_frames(3)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1, "the run was logged")
	if entries.is_empty():
		return
	var entry: Dictionary = entries[0]
	assert_true(entry.has("weapons"), "the log has the weapons field")
	var rows: Array[Dictionary] = []
	rows.assign(entry["weapons"])
	assert_eq(_sum(rows, "kills"), int(entry["kills"]), "the logged kills add up")
	for i: int in range(1, rows.size()):
		assert_gte(int(rows[i - 1]["damage"]), int(rows[i]["damage"]), "biggest damage first")
	var ids: Array[String] = []
	for row: Dictionary in rows:
		ids.append(String(row["id"]))
	assert_has(ids, "peel_boomerang", "the boomerang is logged")
