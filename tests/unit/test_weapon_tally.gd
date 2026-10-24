extends GutTest
## Spec 04 §4.1 (AC-52): damage, kills and time held per weapon and player; an evolved weapon keeps
## its old weapon's numbers; damage from no weapon has its own row; the rows add up to the totals.

const BOOMERANG: WeaponStats = preload("res://data/weapons/peel_boomerang.tres")
const BANANA_SPLIT: WeaponStats = preload("res://data/weapons/banana_split.tres")
const MORTAR: WeaponStats = preload("res://data/weapons/thimble_mortar.tres")

var tally: WeaponTally


func before_each() -> void:
	tally = WeaponTally.new()


func _weapon(stats: WeaponStats, player_index: int = 0) -> Weapon:
	var player: Player = autofree(Player.new())
	player.player_index = player_index
	var weapon: Weapon = autofree(stats.behaviour.new())
	weapon.setup(stats, player)
	return weapon


func test_hits_and_kills_count_per_weapon() -> void:
	var boomerang: Weapon = _weapon(BOOMERANG)
	var mortar: Weapon = _weapon(MORTAR)
	tally.add_hit(boomerang, 10.0, false)
	tally.add_hit(boomerang, 5.0, true)
	tally.add_hit(mortar, 40.0, true)
	var row: WeaponTallyEntry = tally.find(0, BOOMERANG.id)
	assert_eq(row.damage, 15.0)
	assert_eq(row.kills, 1)
	assert_eq(row.display_name, BOOMERANG.display_name)
	assert_eq(tally.find(0, MORTAR.id).kills, 1)
	assert_eq(tally.total_damage, 55.0)
	assert_eq(tally.total_kills, 2)


func test_the_same_weapon_of_two_players_has_two_rows() -> void:
	tally.add_hit(_weapon(BOOMERANG, 0), 10.0, true)
	tally.add_hit(_weapon(BOOMERANG, 1), 3.0, false)
	assert_eq(tally.entries.size(), 2)
	assert_eq(tally.find(0, BOOMERANG.id).damage, 10.0)
	assert_eq(tally.find(1, BOOMERANG.id).damage, 3.0)


func test_an_evolved_weapon_keeps_the_old_weapons_numbers() -> void:
	var boomerang: Weapon = _weapon(BOOMERANG)
	tally.add_hit(boomerang, 100.0, true)
	tally.find(0, BOOMERANG.id).seconds = 60.0
	var split: Weapon = _weapon(BANANA_SPLIT)
	split.player = boomerang.player
	tally.evolve(split)
	tally.add_hit(split, 50.0, true)
	assert_null(tally.find(0, BOOMERANG.id), "no row for the old weapon any more")
	var row: WeaponTallyEntry = tally.find(0, BANANA_SPLIT.id)
	assert_true(row.evolved, "EVO")
	assert_eq(row.damage, 150.0, "old damage included")
	assert_eq(row.kills, 2)
	assert_eq(row.seconds, 60.0, "old time held included")
	assert_eq(tally.entries.size(), 1, "one row")


func test_damage_from_no_weapon_has_its_own_row() -> void:
	tally.add_other(WeaponTally.PARTY_POPPER, 30.0, true)
	tally.add_other(WeaponTally.PARTY_POPPER, 20.0, true)
	tally.add_hit(null, 4.0, false)
	var popper: WeaponTallyEntry = tally.find(-1, WeaponTally.PARTY_POPPER)
	assert_eq(popper.display_name, "Party Popper")
	assert_false(popper.is_weapon)
	assert_eq(popper.damage, 50.0)
	assert_eq(popper.kills, 2)
	assert_eq(tally.find(-1, WeaponTally.OTHER).damage, 4.0, "a hit without a weapon")


func test_list_is_sorted_by_damage_and_adds_up() -> void:
	tally.add_hit(_weapon(BOOMERANG), 10.0, true)
	tally.add_hit(_weapon(MORTAR), 90.0, true)
	tally.add_other(WeaponTally.GOAL_POPS, 0.0, true)
	var list: Array[Dictionary] = tally.to_list()
	assert_eq(list[0]["id"], String(MORTAR.id), "biggest damage first")
	var damage: int = 0
	var kills: int = 0
	for row: Dictionary in list:
		damage += int(row["damage"])
		kills += int(row["kills"])
	assert_eq(damage, 100)
	assert_eq(kills, 3)
	assert_eq(kills, tally.total_kills)
	for key: String in ["id", "name", "player", "damage", "kills", "seconds_held", "level"]:
		assert_true(list[0].has(key), "row has %s" % key)
	assert_true(list[0].has("evolved"))


func test_dps_is_damage_per_second_held() -> void:
	var row: WeaponTallyEntry = WeaponTallyEntry.new()
	assert_eq(row.dps(), 0.0, "never held")
	row.damage = 300.0
	row.seconds = 60.0
	assert_eq(row.dps(), 5.0)
