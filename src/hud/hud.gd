class_name Hud
extends CanvasLayer
## Run information on top of the game: the timer with the goal, player 1's health, XP, level,
## and their weapons and items as two rows of icons with levels (spec 02 §11).
## When a boss arrives: a banner with its name, then its big health bar at the top (spec 02 §9).

const BOSS_BAR_SIZE: Vector2 = Vector2(640.0, 30.0)
const BOSS_BAR_TOP: float = 84.0
const BOSS_COLOR: Color = Color("#e0413a")
const BOSS_BACK_COLOR: Color = Color(0.1, 0.09, 0.12, 0.85)
const BANNER_COLOR: Color = Color("#ffcf3a")
const TEXT_COLOR: Color = Color(0.95, 0.93, 0.88, 1)
const OUTLINE_COLOR: Color = Color(0.08, 0.07, 0.1, 1)
const BANNER_TOP: float = 170.0
## The banner fades out over its last this many seconds.
const BANNER_FADE: float = 0.5

## Upgrade cards by id, for the icons of owned weapons and items.
var pool: UpgradePool
## Player 1's weapon slots, left to right, in the order they were picked.
var weapon_slots: Array[LoadoutSlot] = []
## Player 1's item slots, left to right, in the order they were picked.
var item_slots: Array[LoadoutSlot] = []
## The boss's health bar (hidden while no boss is on the field) and its name on it.
var boss_bar: ProgressBar
var boss_label: Label
## The arrival banner: big name and a line under it.
var banner: VBoxContainer
var banner_title: Label
var banner_subtitle: Label

var _player: Player
var _boss: Zombie
var _banner_left: float = 0.0

@onready var timer_label: Label = %TimerLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var weapon_row: HBoxContainer = %WeaponRow
@onready var item_row: HBoxContainer = %ItemRow


func _ready() -> void:
	_build_boss_bar()
	_build_banner()


func _process(delta: float) -> void:
	if boss_bar.visible:
		if not is_instance_valid(_boss) or _boss.dead:
			boss_bar.visible = false
			_boss = null
		else:
			boss_bar.value = _boss.health
	if banner.visible:
		_banner_left -= delta
		banner.modulate.a = clampf(_banner_left / BANNER_FADE, 0.0, 1.0)
		banner.visible = _banner_left > 0.0


## Shows `boss`'s health bar until it is defeated.
func show_boss(boss: Zombie) -> void:
	_boss = boss
	boss_label.text = boss.display_name
	boss_bar.max_value = boss.max_health
	boss_bar.value = boss.health
	boss_bar.visible = true


## The big arrival banner for `seconds`.
func show_banner(title: String, subtitle: String, seconds: float) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
	banner_subtitle.visible = not subtitle.is_empty()
	_banner_left = seconds
	banner.modulate.a = 1.0
	banner.visible = true


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
	if upgrade != null:
		return upgrade.icon
	var evolution: EvolutionDef = pool.evolution_into(id)
	return evolution.icon if evolution != null else &""


func _build_boss_bar() -> void:
	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.5
	boss_bar.anchor_right = 0.5
	boss_bar.offset_left = -BOSS_BAR_SIZE.x / 2.0
	boss_bar.offset_right = BOSS_BAR_SIZE.x / 2.0
	boss_bar.offset_top = BOSS_BAR_TOP
	boss_bar.offset_bottom = BOSS_BAR_TOP + BOSS_BAR_SIZE.y
	boss_bar.show_percentage = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_theme_stylebox_override("background", _bar_style(BOSS_BACK_COLOR))
	boss_bar.add_theme_stylebox_override("fill", _bar_style(BOSS_COLOR))
	boss_bar.visible = false
	add_child(boss_bar)
	boss_label = _label(22)
	boss_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_bar.add_child(boss_label)


func _build_banner() -> void:
	banner = VBoxContainer.new()
	banner.anchor_right = 1.0
	banner.offset_top = BANNER_TOP
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	add_child(banner)
	banner_title = _label(80)
	banner_title.add_theme_color_override("font_color", BANNER_COLOR)
	banner.add_child(banner_title)
	banner_subtitle = _label(32)
	banner.add_child(banner_subtitle)


func _label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(int(font_size * 0.25), 6))
	label.add_theme_font_size_override("font_size", font_size)
	return label


static func _bar_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	return style


func _make_slots(row: HBoxContainer, count: int) -> Array[LoadoutSlot]:
	for old: Node in row.get_children():
		old.queue_free()
	var slots: Array[LoadoutSlot] = []
	for i: int in count:
		var slot: LoadoutSlot = LoadoutSlot.new()
		row.add_child(slot)
		slots.append(slot)
	return slots
