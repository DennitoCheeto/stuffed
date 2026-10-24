class_name WeaponRow
extends HBoxContainer
## One weapon on the end screen (spec 04 §4.1): icon, name, level or EVO tag, damage bar, damage,
## kills, DPS and time held. `header()` builds the caption row with the same column widths.

const SEPARATION: int = 8
const ICON_SIDE: float = 40.0
## Name column: wide with one player, narrow with more (their columns sit side by side).
const NAME_WIDTH: float = 200.0
const NAME_WIDTH_NARROW: float = 120.0
const TAG_WIDTH: float = 58.0
const BAR_WIDTH: float = 70.0
## Widths of the number columns: damage, kills, DPS, held.
const NUMBER_WIDTHS: Array[float] = [70.0, 58.0, 54.0, 56.0]
const CAPTIONS: Array[String] = ["damage", "kills", "DPS", "held"]
const NAME_SIZE: int = 20
const NUMBER_SIZE: int = 20
const CAPTION_SIZE: int = 15

## The RunResult.weapons dictionary shown here.
var row: Dictionary = {}
var icon: UpgradeIcon
var name_label: Label
var level_tag: FabricTag
var bar: DamageBar
## Damage, kills, DPS and time held.
var number_labels: Array[Label] = []


func _init(
	shown: Dictionary = {},
	icon_name: StringName = &"",
	total_damage: float = 0.0,
	name_width: float = NAME_WIDTH
) -> void:
	row = shown
	add_theme_constant_override(&"separation", SEPARATION)
	if shown.is_empty():
		return
	icon = UpgradeIcon.new()
	icon.icon = icon_name
	icon.custom_minimum_size = Vector2.ONE * ICON_SIDE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(icon)
	name_label = UiFonts.label(str(shown.get("name", "")), NAME_SIZE, UiColors.INK)
	name_label.add_theme_font_override(&"font", UiFonts.body(800))
	_name_column(name_label, name_width)
	add_child(name_label)
	var evolved: bool = shown.get("evolved", false)
	var tag_fill: Color = UiColors.GOLD if evolved else UiColors.TAG
	level_tag = FabricTag.new(WeaponReport.level_text(shown), tag_fill, UiColors.INK, 15)
	add_child(_fixed(level_tag, TAG_WIDTH))
	bar = DamageBar.new(WeaponReport.share(shown, total_damage), BAR_WIDTH)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(bar)
	var values: PackedStringArray = [
		WeaponReport.short_number(float(shown.get("damage", 0))),
		WeaponReport.grouped(int(shown.get("kills", 0))),
		WeaponReport.short_number(WeaponReport.dps(shown)),
		TimeFormat.clock(float(shown.get("seconds_held", 0.0))),
	]
	for index: int in values.size():
		var label: Label = _number(values[index], NUMBER_WIDTHS[index], NUMBER_SIZE)
		label.add_theme_font_override(&"font", UiFonts.heading(600))
		number_labels.append(label)
		add_child(label)


## The caption row above the weapon rows ("damage  kills  DPS  held").
static func header(name_width: float = NAME_WIDTH) -> WeaponRow:
	var captions: WeaponRow = WeaponRow.new()
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(ICON_SIDE, 0)
	captions.add_child(spacer)
	var gap: Control = Control.new()
	_name_column(gap, name_width)
	captions.add_child(gap)
	var tag_gap: Control = Control.new()
	tag_gap.custom_minimum_size = Vector2(TAG_WIDTH + SEPARATION + BAR_WIDTH, 0)
	tag_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	captions.add_child(tag_gap)
	for index: int in CAPTIONS.size():
		var caption: Label = _number(CAPTIONS[index], NUMBER_WIDTHS[index], CAPTION_SIZE)
		caption.add_theme_color_override(&"font_color", UiColors.INK_SOFT)
		captions.number_labels.append(caption)
		captions.add_child(caption)
	return captions


## What the row says: name, level/EVO, damage, kills, DPS, held (for tests).
func texts() -> PackedStringArray:
	var shown: PackedStringArray = [name_label.text, level_tag.label.text]
	for label: Label in number_labels:
		shown.append(label.text)
	return shown


static func _name_column(part: Control, width: float) -> void:
	part.custom_minimum_size = Vector2(width, 0)
	var label: Label = part as Label
	if label != null:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func _number(words: String, width: float, font_size: int) -> Label:
	var label: Label = UiFonts.label(words, font_size, UiColors.INK)
	label.custom_minimum_size = Vector2(width, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label


static func _fixed(part: Control, width: float) -> CenterContainer:
	var holder: CenterContainer = CenterContainer.new()
	holder.custom_minimum_size = Vector2(width, 0)
	holder.add_child(part)
	return holder
