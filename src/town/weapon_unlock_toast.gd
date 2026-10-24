class_name WeaponUnlockToast
extends PanelContainer
## "New weapons!" near the bottom of the screen when a Toy Box Armory level adds weapons to the
## level-up cards (spec 03 §6): each new weapon's felt icon and name. Pops in, stays, fades.
## A taped felt patch with a hand-written title, a little crooked (spec 04 §6.6).

const SHOW_SECONDS: float = 3.2
const FADE_SECONDS: float = 0.5
const POP_SECONDS: float = 0.25
## Resting tilt in degrees.
const TILT: float = 1.0
const ICON_SIZE: float = 72.0
## Space between the toast and the bottom of the screen (the prompt sits below it).
const BOTTOM_GAP: float = 140.0

var title_label: Label
var box: StyleBoxFelt = StyleBoxFelt.new()
## The names shown in the last toast (for tests).
var names: PackedStringArray = []

var _row: HBoxContainer
var _left: float = 0.0


func _init() -> void:
	name = "WeaponUnlockToast"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.shadow = UiColors.SHADOW
	box.pad(30, 22)
	box.add_tape(0.12, -6.0, UiColors.TAPE_GOLD).add_tape(0.88, 5.0, UiColors.TAPE_PINK)
	add_theme_stylebox_override(&"panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	title_label = UiFonts.label("New weapons for your cards!", 40, UiColors.PURPLE, UiFonts.hand())
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", 36)
	column.add_child(_row)


## Shows `weapons` (upgrade pool entries) with their icons, near the bottom of the screen.
func show_weapons(weapons: Array[UpgradeDef]) -> void:
	for old: Node in _row.get_children():
		old.queue_free()
	names.clear()
	for weapon: UpgradeDef in weapons:
		names.append(weapon.display_name)
		var column: VBoxContainer = VBoxContainer.new()
		var icon: UpgradeIcon = UpgradeIcon.new()
		icon.icon = weapon.icon
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(icon)
		var words: Label = UiFonts.label(weapon.display_name, 22, UiColors.INK, UiFonts.heading())
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(words)
		_row.add_child(column)
	_left = SHOW_SECONDS
	modulate.a = 1.0
	visible = true
	reset_size()
	var screen: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2.ZERO
	position = Vector2((screen.x - size.x) / 2.0, screen.y - size.y - BOTTOM_GAP)
	pivot_offset = size / 2.0
	rotation = deg_to_rad(TILT)
	scale = Vector2.ONE * 0.6


func is_showing() -> bool:
	return visible


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	var shown: float = SHOW_SECONDS - _left
	var pop: float = 1.0 if UiFeel.reduced() else clampf(shown / POP_SECONDS, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.6, 1.0, ease(pop, -2.0))
	modulate.a = clampf(_left / FADE_SECONDS, 0.0, 1.0)
	if _left <= 0.0:
		visible = false
