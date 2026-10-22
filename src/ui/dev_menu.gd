class_name DevMenu
extends CanvasLayer
## Developer menu (F1, spec 01 §9, spec 02 §13): a small panel of shortcuts for testing and
## tuning. The game keeps running while it is open, unless "Pause" is ticked. It acts on player 1.

## Restart with this seed (0 = new random seed).
signal restart_requested(seed_value: int)

const PANEL_COLOR: Color = Color(0.1, 0.09, 0.13, 0.92)
## The panel scrolls when it is taller than this.
const MAX_HEIGHT: float = 940.0
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")
const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")
const BLOATER: EnemyStats = preload("res://data/enemies/bloater.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const ENEMY_TYPES: Array[EnemyStats] = [SHAMBLER, RUNNER, SPITTER, BLOATER, TANK]
const MAX_EVERYTHING: String = "Max everything"
const REFILL: String = "Refill rerolls/skips/banishes"

var run: Run
## Everything the menu can do, by button text (tests press them by name).
var buttons: Dictionary[String, BaseButton] = {}
## Which weapon or item the "Give Lv N" buttons give.
var upgrade_picker: OptionButton

var _info_label: Label
var _hitboxes: HitboxOverlay
## Upgrade id of each entry in the picker.
var _picker_ids: Array[StringName] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40


func setup(owner_run: Run) -> void:
	run = owner_run
	_hitboxes = HitboxOverlay.new()
	_hitboxes.visible = false
	run.add_child(_hitboxes)
	_build()


func toggle() -> void:
	visible = not visible


## Presses the button with this text, as if clicked.
func press(text: String) -> void:
	var button: BaseButton = buttons[text]
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	else:
		button.pressed.emit()


## Selects the weapon or item `id` in the picker (for the "Give Lv N" buttons).
func choose_upgrade(id: StringName) -> void:
	upgrade_picker.select(_picker_ids.find(id))


## Gives player 1 the weapon or item `id` at `level` (clamped to its levels). Weapons are set to
## that level; items are raised to it (never lowered). Returns false when its slots are full,
## or the weapon has already evolved.
func give(id: StringName, level: int) -> bool:
	var player: Player = _player()
	var pool: UpgradePool = run.upgrade_pool
	var upgrade: UpgradeDef = pool.find(id)
	var levels: Dictionary[StringName, int] = player.upgrade_levels()
	var owned: int = levels.get(id, 0)
	level = clampi(level, 1, upgrade.top_level())
	if owned == Player.EVOLVED_LEVEL:
		return false
	if owned == 0 and pool.owned_count(levels, upgrade.kind) >= _slots(upgrade.kind):
		return false
	if upgrade.kind == UpgradeDef.Kind.WEAPON:
		var weapon: Weapon = player.weapon(id)
		if weapon == null:
			weapon = player.add_weapon(upgrade.weapon)
		weapon.level = level
		player.loadout_changed.emit()
		return true
	for next: int in range(owned + 1, level + 1):
		player.apply_upgrade(UpgradeOffer.new(upgrade, next))
	return true


## For performance checks: fills player 1's weapon and item slots (weapons that can evolve and
## their partners first), puts everything at its top level and evolves all it can.
func max_everything() -> void:
	var pool: UpgradePool = run.upgrade_pool
	var weapon_ids: Array[StringName] = []
	for evolution: EvolutionDef in pool.evolutions:
		weapon_ids.append(evolution.weapon)
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.WEAPON and not weapon_ids.has(upgrade.id):
			weapon_ids.append(upgrade.id)
	for id: StringName in weapon_ids:
		give(id, pool.find(id).top_level())
	var player: Player = _player()
	var item_ids: Array[StringName] = []
	for evolution: EvolutionDef in pool.evolutions:
		if player.upgrade_levels().get(evolution.weapon, 0) > 0:
			item_ids.append(evolution.partner)
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.ITEM and not item_ids.has(upgrade.id):
			item_ids.append(upgrade.id)
	for id: StringName in item_ids:
		give(id, pool.find(id).top_level())
	var ready: EvolutionDef = pool.ready_evolution(player.upgrade_levels())
	while ready != null:
		player.evolve(ready)
		ready = pool.ready_evolution(player.upgrade_levels())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_menu"):
		get_viewport().set_input_as_handled()
		toggle()


func _process(_delta: float) -> void:
	if not visible or run == null or not _info_label.visible:
		return
	var fps: float = Engine.get_frames_per_second()
	_info_label.text = "FPS %d   Zombies %d" % [fps, run.enemies.alive_count()]


func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(16, 90)
	add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0.0, MAX_HEIGHT)
	panel.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	scroll.add_child(column)
	_title(column, "Developer menu (F1)")
	_row(column, ["Give 10 XP", "Level up now"], [_give_xp, _level_up])
	_build_give(column)
	_row(column, [MAX_EVERYTHING, REFILL], [max_everything, _refill_card_controls])
	_build_spawns(column)
	_row(column, ["Spawn elite", "Drop gift box"], [_spawn_elite, _drop_gift_box])
	_row(column, ["Spawn Big Ted", "Jump to Big Ted"], [_spawn_mini_boss, _jump_to_mini_boss])
	_row(column, ["Spawn the King", "Jump to the King"], [_spawn_boss, _jump_to_boss])
	var evolutions: Array[EvolutionDef] = run.upgrade_pool.evolutions
	for first: int in range(0, evolutions.size(), 2):
		var labels: Array[String] = []
		var actions: Array[Callable] = []
		for evolution: EvolutionDef in evolutions.slice(first, first + 2):
			labels.append("Ready: %s" % evolution.display_name())
			actions.append(_ready_to_evolve.bind(evolution))
		_row(column, labels, actions)
	_row(column, ["Kill all"], [_kill_all])
	var late: float = run.rules.goal_seconds - 30.0
	var jump_label: String = "Jump to %s" % TimeFormat.clock(late)
	_row(column, ["+30 s", jump_label], [_skip_time.bind(30.0), _jump_to.bind(late)])
	_row(column, ["0.5x", "1x", "2x"], [_speed.bind(0.5), _speed.bind(1.0), _speed.bind(2.0)])
	_check(column, "Invincible", _set_invincible)
	_check(column, "Pause", _set_paused)
	_check(column, "Show FPS + count", _set_info)
	_check(column, "Show hitboxes", _set_hitboxes)
	_row(column, ["Restart same seed", "New seed"], [_restart.bind(true), _restart.bind(false)])
	_info_label = Label.new()
	_info_label.visible = false
	column.add_child(_info_label)


## A picker with every weapon and item, and one "Give Lv N" button per level.
func _build_give(parent: Control) -> void:
	upgrade_picker = OptionButton.new()
	upgrade_picker.focus_mode = Control.FOCUS_NONE
	var top: int = 1
	for upgrade: UpgradeDef in run.upgrade_pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.SNACK:
			continue
		upgrade_picker.add_item(upgrade.display_name)
		_picker_ids.append(upgrade.id)
		top = maxi(top, upgrade.top_level())
	parent.add_child(upgrade_picker)
	var labels: Array[String] = []
	var actions: Array[Callable] = []
	for level: int in range(1, top + 1):
		labels.append("Give Lv %d" % level)
		actions.append(_give_picked.bind(level))
	_row(parent, labels, actions)


## 1 / 10 / 100 / 500 of each enemy type, and 1 or 10 of every type at once.
func _build_spawns(parent: Control) -> void:
	for stats: EnemyStats in ENEMY_TYPES:
		var name_text: String = stats.display_name.to_lower()
		var labels: Array[String] = ["1 %s" % name_text]
		var actions: Array[Callable] = [_spawn.bind(stats, 1)]
		for count: int in [10, 100, 500]:
			labels.append("%d %ss" % [count, name_text])
			actions.append(_spawn.bind(stats, count))
		_row(parent, labels, actions)
	_row(parent, ["1 of each", "10 of each"], [_spawn_each.bind(1), _spawn_each.bind(10)])


func _title(parent: Control, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#f2b52e"))
	parent.add_child(label)


func _row(parent: Control, labels: Array[String], actions: Array[Callable]) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	for i: int in labels.size():
		var button: Button = Button.new()
		button.text = labels[i]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(actions[i])
		row.add_child(button)
		buttons[labels[i]] = button


func _check(parent: Control, text: String, action: Callable) -> void:
	var check: CheckBox = CheckBox.new()
	check.text = text
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(action)
	parent.add_child(check)
	buttons[text] = check


func _player() -> Player:
	return Players.all(run.get_tree())[0]


func _slots(kind: UpgradeDef.Kind) -> int:
	var pool: UpgradePool = run.upgrade_pool
	return pool.max_weapons if kind == UpgradeDef.Kind.WEAPON else pool.max_items


func _give_picked(level: int) -> void:
	give(_picker_ids[upgrade_picker.selected], level)


func _give_xp() -> void:
	_player().add_xp(10)


func _level_up() -> void:
	_player().progress.level_up_now()


## Every player gets their rerolls, skips and banishes back (an open level-up shows it at once).
func _refill_card_controls() -> void:
	for player: Player in Players.all(run.get_tree()):
		player.card_controls.refill()
	if run.level_up_screen.is_open():
		run.level_up_screen.show_controls(_player().card_controls)


func _spawn(stats: EnemyStats, count: int) -> void:
	for i: int in count:
		run.spawner.spawn_one(stats)


func _spawn_each(count: int) -> void:
	for stats: EnemyStats in ENEMY_TYPES:
		_spawn(stats, count)


## An elite of a random type from the schedule's elites.
func _spawn_elite() -> void:
	var schedule: SpawnSchedule = run.spawner.schedule
	var index: int = randi_range(0, schedule.elites.size() - 1)
	run.spawner.spawn_elite(schedule.elite_enemy(index))


func _spawn_mini_boss() -> void:
	run.spawner.spawn_boss(run.spawner.schedule.mini_boss)


## A second before the mini-boss arrives (if he hasn't come yet).
func _jump_to_mini_boss() -> void:
	_jump_to(run.spawner.schedule.mini_boss.at_seconds - 1.0)


func _spawn_boss() -> void:
	run.spawner.spawn_boss(run.spawner.schedule.boss)


## A second before the boss arrives (at the run goal).
func _jump_to_boss() -> void:
	_jump_to(run.rules.goal_seconds - 1.0)


## A gift box a few steps to the right of player 1.
func _drop_gift_box() -> void:
	run.drop_gift_box(_player().global_position + Vector2(80.0, 0.0))


## Gives player 1 the weapon of `evolution` at its top level and its partner item, and drops a
## gift box next to them: walk onto it to evolve.
func _ready_to_evolve(evolution: EvolutionDef) -> void:
	var player: Player = _player()
	var pool: UpgradePool = run.upgrade_pool
	var base: UpgradeDef = pool.find(evolution.weapon)
	var weapon: Weapon = player.weapon(evolution.weapon)
	if weapon == null:
		weapon = player.add_weapon(base.weapon)
	weapon.level = base.top_level()
	if not player.item_levels.has(evolution.partner):
		player.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	player.loadout_changed.emit()
	_drop_gift_box()


func _kill_all() -> void:
	run.enemies.kill_all()


func _skip_time(seconds: float) -> void:
	run.elapsed += seconds


func _jump_to(seconds: float) -> void:
	run.elapsed = maxf(run.elapsed, seconds)


func _speed(factor: float) -> void:
	Engine.time_scale = factor


func _set_invincible(on: bool) -> void:
	for player: Player in Players.all(run.get_tree()):
		player.invincible = on


func _set_paused(on: bool) -> void:
	if on:
		run.freeze(&"dev")
	else:
		run.unfreeze(&"dev")


func _set_info(on: bool) -> void:
	_info_label.visible = on


func _set_hitboxes(on: bool) -> void:
	_hitboxes.visible = on


func _restart(same_seed: bool) -> void:
	Engine.time_scale = 1.0
	restart_requested.emit(run.seed_value if same_seed else 0)
