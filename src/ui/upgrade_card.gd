class_name UpgradeCard
extends SewnButton
## One level-up card as a felt patch (spec 02 §5, §11; spec 04 §6.3): the key number and
## "New!" / "Lv 2 → 3" on fabric tags, the icon, the name, one line of what it does and, for
## weapons that can evolve, the icon of their partner item. Lifts on hover / focus like every
## sewn button but never tilts while the player chooses: cards must read at a glance.

const CARD_SIZE: Vector2 = Vector2(340, 400)
## While choosing a card to banish: how far (radians) and how fast (per second) the card wiggles.
const WIGGLE_ANGLE: float = 0.035
const WIGGLE_SPEED: float = 9.0
## New upgrades get a teal tag, level-ups a plain one.
const NEW_TAG: Color = UiColors.STICKER_TEAL

var offer: UpgradeOffer
## "Evolves with": the partner item's name and icon (weapons that can evolve only).
var partner_row: HBoxContainer = HBoxContainer.new()
var partner_icon: UpgradeIcon = UpgradeIcon.new()
var partner_label: Label = UiFonts.label("", 17, UiColors.INK_SOFT)
## The scissors mark shown while choosing a card to banish.
var banish_mark: UpgradeIcon = UpgradeIcon.new()
var marked: bool = false
## The key number and the level on fabric tags.
var key_tag: FabricTag = FabricTag.new("1", UiColors.TAG, UiColors.INK, 20)
var level_tag: FabricTag = FabricTag.new("", UiColors.TAG, UiColors.INK, 20)
var name_label: Label = UiFonts.label("", 32, UiColors.INK, UiFonts.heading(600))
var text_label: Label = UiFonts.label("", 21, UiColors.INK_SOFT)

var _icon: UpgradeIcon = UpgradeIcon.new()
var _wiggle_time: float = 0.0


func _init() -> void:
	super("", false)
	box.radius = 26.0
	box.stitch_inset = 11.0
	box.pad(26, 20)
	face.custom_minimum_size = CARD_SIZE
	caption.visible = false
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(column)
	var tags: HBoxContainer = HBoxContainer.new()
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap: Control = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part: Control in [key_tag, gap, level_tag]:
		tags.add_child(part)
	column.add_child(tags)
	_icon.custom_minimum_size = Vector2(100, 100)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_icon)
	for label: Label in [name_label, text_label, partner_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	column.add_child(text_label)
	var filler: Control = Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(filler)
	partner_row.alignment = BoxContainer.ALIGNMENT_CENTER
	partner_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	partner_icon.custom_minimum_size = Vector2(40, 40)
	partner_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Wraps instead of widening the card: all three cards keep the same width.
	partner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	partner_row.add_child(partner_label)
	partner_row.add_child(partner_icon)
	column.add_child(partner_row)
	banish_mark.icon = &"scissors"
	banish_mark.custom_minimum_size = Vector2(64, 64)
	banish_mark.size = banish_mark.custom_minimum_size
	# Top middle, half over the edge: it never hides the key or the level.
	banish_mark.position = Vector2(CARD_SIZE.x / 2.0 - 32.0, -34.0)
	banish_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banish_mark.visible = false
	add_child(banish_mark)


## Shows `card_offer` as card number `number` (1-3).
func show_offer(card_offer: UpgradeOffer, number: int) -> void:
	offer = card_offer
	key_tag.label.text = str(number)
	_icon.icon = offer.upgrade.icon
	name_label.text = offer.upgrade.display_name
	level_tag.label.text = offer.level_text()
	level_tag.visible = level_tag.label.text != ""
	var fresh: bool = offer.next_level <= 1
	level_tag.box.fill = NEW_TAG if fresh else UiColors.TAG
	level_tag.box.stitch = level_tag.box.fill.darkened(0.28)
	level_tag.label.add_theme_color_override(
		&"font_color", UiColors.STICKER_TEAL_INK if fresh else UiColors.INK
	)
	text_label.text = offer.description()
	partner_row.visible = offer.partner != null
	if offer.partner != null:
		partner_label.text = "Evolves with %s" % offer.partner.display_name
		partner_icon.icon = offer.partner.icon


## Marks the card while the player picks one to banish: scissors mark + a small wiggle.
func set_marked(on: bool) -> void:
	marked = on
	banish_mark.visible = on
	_wiggle_time = 0.0
	rotation = 0.0
	set_process(on)


func _process(delta: float) -> void:
	if not marked:
		return
	_wiggle_time += delta
	pivot_offset = size / 2.0
	rotation = sin(_wiggle_time * WIGGLE_SPEED) * WIGGLE_ANGLE
