class_name BuildingCard
extends PanelContainer
## The small card next to a building while a player stands there (spec 03 §5): name, level,
## what it does now, what the next level adds, the price with jar icons (grey + the missing
## amount when the jars don't hold enough) and what E does. Lives in the town's world space.
## A taped-on felt patch, a little crooked, with a hand-written name and the level on a fabric
## tag (spec 04 §6.6); it pops in when it moves to another building.

const WIDTH: float = 440.0
## Space between the card and the building (or its sign).
const GAP: float = 18.0
## Height of the sign under a building (the card goes below it when the player is above).
const SIGN_HEIGHT: float = 120.0
## Resting tilt in degrees and how small it starts when it pops in.
const TILT: float = -1.5
## Room for the hand-written name next to the level tag.
const TITLE_WIDTH: float = 230.0
const POP_FROM: float = 0.9
const ACTION_COLOR: Color = UiColors.PURPLE
const MISSING_COLOR: Color = UiColors.INK_SOFT

## The building the card shows (null = hidden).
var building: TownBuilding
var title_label: Label
## The level on a fabric tag ("Ruin", "Level 2 of 3").
var level_tag: FabricTag = FabricTag.new("", UiColors.TAG, UiColors.INK, 18)
var level_label: Label = level_tag.label
var now_label: Label
var next_label: Label
## An extra line some buildings add ("Starting weapon: Peel Boomerang").
var note_label: Label
var cost_row: HBoxContainer
var cost_counters: Dictionary[String, JarCounter] = {}
## "E  Rebuild", "Needs 40 more coins", "Fully upgraded!" or what unlocks it.
var action_label: Label
var box: StyleBoxFelt = StyleBoxFelt.new()

var _pop: Tween


func _init() -> void:
	name = "BuildingCard"
	visible = false
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, 0.0)
	box.shadow = UiColors.SHADOW
	box.pad(26, 22)
	box.add_tape(0.5, 4.0, UiColors.TAPE_TEAL)
	add_theme_stylebox_override(&"panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 12)
	column.add_child(top)
	title_label = UiFonts.label("", 38, UiColors.PURPLE, UiFonts.hand())
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A fixed width, so the wrapped name knows its height before the first layout.
	title_label.custom_minimum_size = Vector2(TITLE_WIDTH, 0.0)
	top.add_child(title_label)
	level_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(level_tag)
	now_label = _line(column, 22, UiColors.INK)
	next_label = _line(column, 21, UiColors.INK_SOFT)
	note_label = _line(column, 21, UiColors.TEAL)
	cost_row = HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override(&"separation", 22)
	column.add_child(cost_row)
	action_label = _line(column, 24, ACTION_COLOR, UiFonts.heading())
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Shows the card for `target` with the town's jars in `save`, above the building or (when the
## player stands above it) below its sign, with an extra `note` line if there is one.
func show_for(target: TownBuilding, save: TownSave, above: bool, note: String = "") -> void:
	var moved: bool = building != target or not visible
	building = target
	var def: BuildingDef = target.building
	title_label.text = def.display_name
	level_label.text = level_text(target.level, def.max_level())
	if target.level == 0:
		now_label.text = def.summary
		next_label.text = "Rebuilt: " + def.effect_at(1)
	else:
		now_label.text = "Now: " + def.effect_at(target.level)
		var next: BuildingLevel = def.next(target.level)
		next_label.text = "" if next == null else "Next level: " + next.effect
	next_label.visible = not next_label.text.is_empty()
	note_label.text = note
	note_label.visible = not note.is_empty()
	_show_cost(target, save)
	action_label.text = action_text(target, save)
	var missing: bool = target.unlocked and not save.missing(_cost(target)).is_empty()
	action_label.add_theme_color_override(&"font_color", MISSING_COLOR if missing else ACTION_COLOR)
	visible = true
	reset_size()
	var rect: Rect2 = target.spot.rect
	var top: float = rect.position.y - size.y - GAP
	if not above:
		top = rect.end.y + SIGN_HEIGHT
	position = Vector2(rect.get_center().x - size.x / 2.0, top)
	pivot_offset = size / 2.0
	rotation = deg_to_rad(TILT)
	if moved:
		_pop_in()


func hide_card() -> void:
	building = null
	visible = false


## "Ruin", "Level 2 of 3" or "Level 3 of 3 (max)".
static func level_text(level: int, top: int) -> String:
	if level == 0:
		return "Ruin"
	if level >= top:
		return "Level %d of %d (max)" % [level, top]
	return "Level %d of %d" % [level, top]


## What pressing E at `target` does right now (also the prompt at the bottom of the screen).
static func action_text(target: TownBuilding, save: TownSave) -> String:
	if not target.unlocked:
		return target.spot.unlock_hint()
	var next: BuildingLevel = target.building.next(target.level)
	if next == null:
		if target.building.chooses_start_weapon(target.level):
			return "E   Choose starting weapon"
		return "Fully upgraded!"
	var missing: Dictionary[String, int] = save.missing(next.cost())
	if not missing.is_empty():
		return missing_text(missing)
	return "E   Rebuild" if target.level == 0 else "E   Upgrade to level %d" % (target.level + 1)


## "Needs 40 more stuffing", or "Needs 40 more coins and 5 more thread".
static func missing_text(missing: Dictionary[String, int]) -> String:
	var parts: PackedStringArray = []
	for material: String in JarIcon.MATERIALS:
		if missing.get(material, 0) > 0:
			parts.append("%d more %s" % [missing[material], JarIcon.NAMES[material].to_lower()])
	return "Needs " + " and ".join(parts)


func _show_cost(target: TownBuilding, save: TownSave) -> void:
	for counter: JarCounter in cost_counters.values():
		counter.queue_free()
	cost_counters.clear()
	var cost: Dictionary[String, int] = _cost(target)
	cost_row.visible = target.unlocked and not cost.is_empty()
	for material: String in cost:
		var counter: JarCounter = JarCounter.new(material, 24, 32.0).on_felt()
		counter.show_amount(cost[material])
		if save.material(material) < cost[material]:
			counter.modulate = TownBuilding.SHORT_TINT
		cost_row.add_child(counter)
		cost_counters[material] = counter


static func _cost(target: TownBuilding) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	var next: BuildingLevel = target.building.next(target.level)
	if next != null:
		result = next.cost()
	return result


## Pops the card in (a little small, then springs to size), unless menus move less.
func _pop_in() -> void:
	if _pop != null:
		_pop.kill()
	if UiFeel.reduced() or not is_inside_tree():
		scale = Vector2.ONE
		return
	scale = Vector2.ONE * POP_FROM
	_pop = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "scale", Vector2.ONE, UiFeel.STYLE.spring_seconds)


func _line(column: VBoxContainer, font_size: int, color: Color, font: Font = null) -> Label:
	var line: Label = UiFonts.label("", font_size, color, font)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(WIDTH - 52.0, 0.0)
	column.add_child(line)
	return line
