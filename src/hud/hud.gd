class_name Hud
extends CanvasLayer
## Run information on top of the game: the timer with the goal, player 1's health, XP, level,
## and their weapons and items as two rows of icons with levels (spec 02 §11).

@onready var timer_label: Label = %TimerLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var weapon_row: HBoxContainer = %WeaponRow
@onready var item_row: HBoxContainer = %ItemRow

## Upgrade cards by id, for the icons of owned weapons and items.
var pool: UpgradePool
## Player 1's weapon slots, left to right, in the order they were picked.
var weapon_slots: Array[LoadoutSlot] = []
## Player 1's item slots, left to right, in the order they were picked.
var item_slots: Array[LoadoutSlot] = []

var _player: Player


func show_time(elapsed: float, goal: float) -> void:
	timer_label.text = TimeFormat.run_timer(elapsed, goal)


func show_endless_time(seconds: float) -> void:
	timer_label.text = TimeFormat.endless(seconds)


## Shows this player's health, XP and loadout from now on. `upgrade_pool` gives the icons and
## the number of slots.
func follow_player(player: Player, upgrade_pool: UpgradePool) -> void:
	_player = player
	pool = upgrade_pool
	weapon_slots = _make_slots(weapon_row, pool.max_weapons)
	item_slots = _make_slots(item_row, pool.max_items)
	player.loadout_changed.connect(show_loadout)
	show_loadout()
	player.health_changed.connect(show_health)
	show_health(player.health, player.max_health)
	player.progress.xp_changed.connect(show_xp)
	show_xp(player.progress.xp, player.progress.xp_needed(), player.progress.level)


func show_xp(xp: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	level_label.text = "Lv %d" % level


func show_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), roundi(maximum)]


## Redraws the weapon and item icons of the followed player.
func show_loadout() -> void:
	var weapons: Array[Weapon] = _player.weapons()
	for index: int in weapon_slots.size():
		if index < weapons.size():
			var owned: Weapon = weapons[index]
			weapon_slots[index].show_upgrade(_icon_for(owned.stats.id), owned.level)
		else:
			weapon_slots[index].show_upgrade(&"", 0)
	for index: int in item_slots.size():
		if index < _player.items.size():
			var item: UpgradeDef = _player.items[index]
			item_slots[index].show_upgrade(item.icon, _player.item_levels[item.id])
		else:
			item_slots[index].show_upgrade(&"", 0)


func _icon_for(id: StringName) -> StringName:
	var upgrade: UpgradeDef = pool.find(id)
	return upgrade.icon if upgrade != null else &""


func _make_slots(row: HBoxContainer, count: int) -> Array[LoadoutSlot]:
	for old: Node in row.get_children():
		old.queue_free()
	var slots: Array[LoadoutSlot] = []
	for i: int in count:
		var slot: LoadoutSlot = LoadoutSlot.new()
		row.add_child(slot)
		slots.append(slot)
	return slots
