class_name EndScreen
extends Control
## After a run: "Today's page" (spec 04 §4). A hand-written title and the run line, "Your weapons"
## (one column per player: the Star of the run as a taped photo, the other weapons as rows with
## damage, kills, DPS and time held, items as tags), what the run brought home (counting into the
## jars), then "Back to the fort" (or Try again).

signal try_again_requested
signal fort_requested

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const WON_COLOR: Color = UiColors.GOLD
## Soft coral for a lost run (spec 04 §2.1).
const LOST_COLOR: Color = Color("#f0a08a")
const LIGHT_INK: Color = UiColors.FELT
const BACKGROUND: Color = Color("#4e4170")
const PAGE_MARGIN: Vector2 = Vector2(44, 28)
const TITLE_SIZE: int = 76
const RUN_LINE_SIZE: int = 24
## The sticker waits for the panels to drop in.
const STAR_DELAY: float = 0.35

var result: RunResult
## The haul counting into the jars (spec 03 §2.6).
var brought_home: BroughtHomePanel = BroughtHomePanel.new()
var title: HandTitle = HandTitle.new("You survived!", TITLE_SIZE, WON_COLOR, -2.0)
var title_label: Label = title.label
## Run titles go here as stickers (M3.5-05).
var sticker_row: HBoxContainer = HBoxContainer.new()
## "8:00 + 1:15 endless · Level 38 · 4,321 zombies stuffed"
var stats_label: Label = UiFonts.label("", RUN_LINE_SIZE, LIGHT_INK)
var seed_label: Label = UiFonts.label("", 15, Color(LIGHT_INK, 0.6))
var weapons_panel: FeltPanel = FeltPanel.new(-0.6)
var weapons_heading: HandTitle = HandTitle.new("Your weapons", 36, UiColors.PURPLE, -2.0)
## One per player.
var columns: Array[WeaponColumn] = []
## Damage that no weapon dealt ("Party Popper: 3.2k damage, 41 kills").
var extras_label: Label = UiFonts.label("", 17, UiColors.INK_SOFT)
var home_panel: FeltPanel = FeltPanel.new(1.2)
var fort_button: SewnButton = SewnButton.new("Back to the fort", true, 32)
var try_again_button: SewnButton = SewnButton.new("Try again", false, 26)
var motion: ScreenMotion = ScreenMotion.new()

var _columns_row: HBoxContainer = HBoxContainer.new()
var _star_tween: Tween


func _ready() -> void:
	_build()
	fort_button.pressed.connect(fort_requested.emit)
	try_again_button.pressed.connect(try_again_requested.emit)
	fort_button.grab_focus()
	motion.open([title, weapons_panel, home_panel])
	_star_tween = create_tween()
	_star_tween.tween_interval(UiFeel.seconds(STAR_DELAY))
	_star_tween.tween_callback(_slap_stars)


## Fills the screen with `run_result`. Call before or after adding to the tree.
func show_result(run_result: RunResult) -> void:
	result = run_result
	title_label.text = result.title()
	title_label.add_theme_color_override(&"font_color", WON_COLOR if result.won else LOST_COLOR)
	stats_label.text = " · ".join(stat_lines(result))
	seed_label.text = "Seed %d" % result.seed_value
	for column: WeaponColumn in columns:
		column.queue_free()
	columns.clear()
	var count: int = WeaponReport.player_count(result)
	for player: int in count:
		var column: WeaponColumn = WeaponColumn.new(result, player, POOL, count > 1)
		columns.append(column)
		_columns_row.add_child(column)
	extras_label.text = extras_text(result)
	extras_label.visible = not extras_label.text.is_empty()


## The parts of the run line under the title.
static func stat_lines(run_result: RunResult) -> PackedStringArray:
	var lines: PackedStringArray = []
	if run_result.endless_seconds > 0.0:
		var goal: float = run_result.survived_seconds - run_result.endless_seconds
		var endless: String = TimeFormat.clock(run_result.endless_seconds)
		lines.append("%s + %s endless" % [TimeFormat.clock(goal), endless])
	else:
		lines.append("Survived %s" % TimeFormat.clock(run_result.survived_seconds))
	lines.append("Level %d" % run_result.level)
	var zombies: String = "zombie" if run_result.kills == 1 else "zombies"
	lines.append("%s %s stuffed" % [WeaponReport.grouped(run_result.kills), zombies])
	if run_result.killed_by != "":
		lines.append("Got stuffed by %s" % run_result.killed_by)
	return lines


## The small line for damage no weapon dealt ("" = none).
static func extras_text(run_result: RunResult) -> String:
	var parts: PackedStringArray = []
	for row: Dictionary in WeaponReport.extras(run_result):
		var damage: String = WeaponReport.short_number(float(row["damage"]))
		var kills: String = WeaponReport.grouped(int(row["kills"]))
		parts.append("%s: %s damage, %s kills" % [row["name"], damage, kills])
	return "Also: " + " · ".join(parts) if not parts.is_empty() else ""


## Every item tag on the page (all players), for tests.
func item_tag_texts() -> PackedStringArray:
	var texts: PackedStringArray = []
	for column: WeaponColumn in columns:
		for tag: FabricTag in column.item_tags:
			texts.append(tag.label.text)
	return texts


func _slap_stars() -> void:
	var slapped: bool = false
	for column: WeaponColumn in columns:
		if column.star_sticker != null:
			column.slap_star()
			slapped = true
	if slapped:
		Sfx.play(&"star")


func _build() -> void:
	add_child(motion)
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, int(PAGE_MARGIN.x))
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(PAGE_MARGIN.y))
	add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 16)
	margin.add_child(page)
	page.add_child(_header())
	page.add_child(_middle())
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 40)
	buttons.add_child(fort_button)
	buttons.add_child(try_again_button)
	page.add_child(buttons)


func _header() -> VBoxContainer:
	var header: VBoxContainer = VBoxContainer.new()
	header.add_theme_constant_override(&"separation", 2)
	var top: HBoxContainer = HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override(&"separation", 28)
	top.add_child(title)
	sticker_row.add_theme_constant_override(&"separation", 14)
	top.add_child(sticker_row)
	header.add_child(top)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_override(&"font", UiFonts.heading(500))
	header.add_child(stats_label)
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(seed_label)
	return header


func _middle() -> HBoxContainer:
	var middle: HBoxContainer = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override(&"separation", 28)
	weapons_panel.add_tape(0.08, -8.0, UiColors.TAPE_TEAL).add_tape(0.92, 6.0)
	weapons_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var weapons: VBoxContainer = VBoxContainer.new()
	weapons.add_theme_constant_override(&"separation", 10)
	weapons_panel.content.add_child(weapons)
	weapons_heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	weapons.add_child(weapons_heading)
	_columns_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns_row.add_theme_constant_override(&"separation", 32)
	weapons.add_child(_columns_row)
	extras_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapons.add_child(extras_label)
	middle.add_child(weapons_panel)
	home_panel.add_tape(0.5, 3.0, UiColors.TAPE_PINK)
	home_panel.content.add_child(brought_home)
	middle.add_child(home_panel)
	return middle
