class_name WeaponColumn
extends VBoxContainer
## One player's weapons on the end screen (spec 04 §4.1, §4.4): the Star of the run as a taped-on
## photo with its sticker and numbers, then the other weapons as rows (they scroll when there are
## many) and the items as fabric tags.

const STAR_ICON: float = 84.0
const STAR_PICTURE: Vector2 = Vector2(128, 100)
const STAR_DAMAGE_SIZE: int = 40
const STAR_LINE_SIZE: int = 19
const TAG_SIZE: int = 15
const HEADING_COLORS: Array[Color] = [UiColors.PURPLE, UiColors.TEAL]

## 0-based player index.
var player: int = 0
## The Star of the run's row ({} = this player had no weapon).
var star: Dictionary = {}
## "Player 1" over the column (only with more than one player).
var heading: HandTitle
var star_photo: PhotoFrame
var star_icon: UpgradeIcon
var star_sticker: Sticker
var star_damage_label: Label
## "EVO · 1,912 kills · 381 DPS · held 6:40"
var star_line_label: Label
## The other weapons, biggest damage first.
var rows: Array[WeaponRow] = []
## Item tags ("Quick Feet 3").
var item_tags: Array[FabricTag] = []
var scroll: ScrollContainer
var empty_label: Label


func _init(result: RunResult, who: int, pool: UpgradePool, show_heading: bool) -> void:
	player = who
	name = "Player%dWeapons" % (who + 1)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 10)
	if show_heading:
		var color: Color = HEADING_COLORS[who % HEADING_COLORS.size()]
		heading = HandTitle.new("Player %d" % (who + 1), 32, color, -1.5)
		heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_child(heading)
	var weapons: Array[Dictionary] = WeaponReport.rows_of(result, who)
	var name_width: float = WeaponRow.NAME_WIDTH_NARROW if show_heading else WeaponRow.NAME_WIDTH
	if weapons.is_empty():
		empty_label = UiFonts.label("No weapons this time.", 20, UiColors.INK_SOFT)
		add_child(empty_label)
	else:
		star = weapons[0]
		add_child(_star_block(result, pool))
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 6)
	scroll.add_child(list)
	if weapons.size() > 1:
		list.add_child(WeaponRow.header(name_width))
	for index: int in range(1, weapons.size()):
		var weapon: Dictionary = weapons[index]
		var icon_name: StringName = WeaponReport.icon_for(pool, StringName(weapon["id"]))
		var shown: WeaponRow = WeaponRow.new(weapon, icon_name, result.total_damage, name_width)
		rows.append(shown)
		list.add_child(shown)
	_add_items(list, WeaponReport.item_tags(result, who))


## Every weapon this column lists, the star first (for tests).
func listed() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	if not star.is_empty():
		all.append(star)
	for weapon_row: WeaponRow in rows:
		all.append(weapon_row.row)
	return all


## Slaps the "Star of the run" sticker on (after the screen dropped in).
func slap_star() -> void:
	if star_sticker != null:
		star_sticker.slap()


## The star's line under its damage: EVO/level, kills, DPS and time held.
static func star_line(weapon: Dictionary) -> String:
	var parts: PackedStringArray = [
		WeaponReport.level_text(weapon),
		"%s kills" % WeaponReport.grouped(int(weapon.get("kills", 0))),
		"%s DPS" % WeaponReport.short_number(WeaponReport.dps(weapon)),
		"held %s" % TimeFormat.clock(float(weapon.get("seconds_held", 0.0))),
	]
	return " · ".join(parts)


func _star_block(result: RunResult, pool: UpgradePool) -> HBoxContainer:
	var block: HBoxContainer = HBoxContainer.new()
	block.add_theme_constant_override(&"separation", 18)
	star_photo = PhotoFrame.new(str(star.get("name", "")), STAR_PICTURE, -3.0, UiColors.TAPE_GOLD)
	star_photo.caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star_photo.caption.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	star_photo.caption.custom_minimum_size = Vector2(STAR_PICTURE.x, 0)
	var middle: CenterContainer = CenterContainer.new()
	star_photo.picture.add_child(middle)
	star_icon = UpgradeIcon.new()
	star_icon.icon = WeaponReport.icon_for(pool, StringName(star.get("id", "")))
	star_icon.custom_minimum_size = Vector2.ONE * STAR_ICON
	middle.add_child(star_icon)
	block.add_child(star_photo)
	var words: VBoxContainer = VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override(&"separation", 4)
	block.add_child(words)
	var sticker_row: HBoxContainer = HBoxContainer.new()
	sticker_row.add_theme_constant_override(&"separation", 6)
	sticker_row.add_child(StarBadge.new())
	star_sticker = Sticker.new("Star of the run", UiColors.GOLD, UiColors.GOLD_INK, 4.0, 24)
	# Hidden until it slaps on (after the screen dropped in).
	star_sticker.fade = 1.0 if UiFeel.reduced() else 0.0
	sticker_row.add_child(star_sticker)
	words.add_child(sticker_row)
	var damage: String = WeaponReport.short_number(float(star.get("damage", 0)))
	star_damage_label = UiFonts.label(
		"%s damage" % damage, STAR_DAMAGE_SIZE, UiColors.PURPLE, UiFonts.heading()
	)
	words.add_child(star_damage_label)
	var bar: DamageBar = DamageBar.new(WeaponReport.share(star, result.total_damage), 220.0)
	words.add_child(bar)
	star_line_label = UiFonts.label(star_line(star), STAR_LINE_SIZE, UiColors.INK_SOFT)
	star_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star_line_label.custom_minimum_size = Vector2(160, 0)
	words.add_child(star_line_label)
	return block


func _add_items(list: VBoxContainer, tags: PackedStringArray) -> void:
	if tags.is_empty():
		return
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override(&"h_separation", 6)
	flow.add_theme_constant_override(&"v_separation", 6)
	list.add_child(flow)
	for words: String in tags:
		var tag: FabricTag = FabricTag.new(words, UiColors.TAG, UiColors.INK, TAG_SIZE)
		item_tags.append(tag)
		flow.add_child(tag)
