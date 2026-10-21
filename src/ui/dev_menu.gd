class_name DevMenu
extends CanvasLayer
## Developer menu (F1, spec 01 §9): a small panel of shortcuts for testing and tuning.
## The game keeps running while it is open, unless "Pause" is ticked.

## Restart with this seed (0 = new random seed).
signal restart_requested(seed_value: int)

const PANEL_COLOR: Color = Color(0.1, 0.09, 0.13, 0.92)
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")
const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")
const BLOATER: EnemyStats = preload("res://data/enemies/bloater.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")

var run: Run
## Everything the menu can do, by button text (tests press them by name).
var buttons: Dictionary[String, BaseButton] = {}

var _info_label: Label
var _hitboxes: HitboxOverlay


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
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	_title(column, "Developer menu (F1)")
	_row(column, ["Give 10 XP", "Level up now"], [_give_xp, _level_up])
	for stats: EnemyStats in [SHAMBLER, RUNNER, SPITTER, BLOATER, TANK]:
		var labels: Array[String] = []
		var actions: Array[Callable] = []
		for count: int in [10, 100, 500]:
			labels.append("%d %ss" % [count, stats.display_name.to_lower()])
			actions.append(_spawn.bind(stats, count))
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


func _give_xp() -> void:
	_player().add_xp(10)


func _level_up() -> void:
	_player().progress.level_up_now()


func _spawn(stats: EnemyStats, count: int) -> void:
	for i: int in count:
		run.spawner.spawn_one(stats)


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
