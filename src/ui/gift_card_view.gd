class_name GiftCardView
extends Wobbly
## One big card on the gift box screen (spec 02 §20, spec 04 §6.4): a felt patch taped onto the
## cloth, a little crooked, with the felt icon (old → new for an evolution), the name, the level
## change on a fabric tag and one line of what it does. Evolutions get pink stitches and tape.

const CARD_SIZE: Vector2 = Vector2(320, 380)
const EVOLUTION_SIZE: Vector2 = Vector2(460, 380)
const EVOLUTION_STITCH: Color = Color("#d0679f")

var card: GiftCard
var patch: PanelContainer = PanelContainer.new()
var box: StyleBoxFelt = StyleBoxFelt.new()
var icon: UpgradeIcon = UpgradeIcon.new()
## Evolutions only: the weapon it evolved from, left of an arrow.
var from_icon: UpgradeIcon = UpgradeIcon.new()
var arrow_label: Label = UiFonts.label("→", 48, UiColors.INK, UiFonts.heading())
var title_label: Label = UiFonts.label("", 32, UiColors.INK, UiFonts.heading(600))
var level_tag: FabricTag
var level_label: Label
var text_label: Label = UiFonts.label("", 21, UiColors.INK_SOFT)


func _init(shown: GiftCard, degrees: float = 0.0) -> void:
	card = shown
	var evolution: bool = card.is_evolution()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.custom_minimum_size = EVOLUTION_SIZE if evolution else CARD_SIZE
	box.shadow = UiColors.SHADOW
	box.pad(24, 26)
	if evolution:
		box.stitch = EVOLUTION_STITCH
		box.add_tape(0.3, -6.0, UiColors.TAPE_PINK)
		box.add_tape(0.7, 5.0, UiColors.TAPE_PINK)
	else:
		box.add_tape(0.5, 4.0 if degrees < 0.0 else -4.0, UiColors.TAPE_GOLD)
	patch.add_theme_stylebox_override(&"panel", box)
	set_body(patch)
	tilt = degrees
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.add_child(column)
	var icons: HBoxContainer = HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override(&"separation", 16)
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icons)
	for part: UpgradeIcon in [from_icon, icon]:
		part.custom_minimum_size = Vector2(110, 110)
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	from_icon.icon = card.from_icon
	icon.icon = card.icon
	from_icon.visible = evolution
	arrow_label.visible = evolution
	icons.add_child(from_icon)
	icons.add_child(arrow_label)
	icons.add_child(icon)
	title_label.text = card.title
	var tag_fill: Color = UiColors.STICKER_PINK if evolution else UiColors.TAG
	var tag_ink: Color = UiColors.STICKER_PINK_INK if evolution else UiColors.INK
	level_tag = FabricTag.new(card.level_text, tag_fill, tag_ink, 22)
	level_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	level_label = level_tag.label
	level_tag.visible = card.level_text != ""
	text_label.text = card.text
	for label: Label in [title_label, text_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title_label)
	column.add_child(level_tag)
	column.add_child(text_label)
