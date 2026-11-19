class_name GearTile
extends SewnButton
## One piece on the sewing table (spec 09 §6, AC-98): its picture, name, effect in one line,
## stitch dots (●●○), the price of its next step and its main action (Sew / Stitch / Wear /
## Take off). A piece whose pattern wasn't found is a silhouette that says where the pattern
## comes from; a piece the Workshop can't sew yet says which level it needs. No danger colours.

const TILE_SIZE: Vector2 = Vector2(330, 172)
const PICTURE_SIDE: float = 72.0
const READY_STITCH: Color = UiColors.GOLD_EDGE
const WORN_STITCH: Color = UiColors.TEAL
const WORN_FILL: Color = UiColors.STICKER_TEAL
const DOT_ON: String = "●"
const DOT_OFF: String = "○"

var piece: GearDef
## The main action for the player at the table (GearBook.Action), set by `show_state`.
var action: GearBook.Action = GearBook.Action.NONE
## True when the main action works right now.
var can_act: bool = false
## True when the player at the table wears it.
var worn: bool = false
var picture: GearPicture
var name_label: Label
var text_label: Label
var dots_label: Label
var cost_row: HBoxContainer
var cost_counters: Dictionary[String, JarCounter] = {}
## Sew / Stitch to Lv 2 / Wear / Take off (hidden when there is nothing to do).
var action_tag: FabricTag = FabricTag.new("", UiColors.GOLD, UiColors.GOLD_INK, 17)
## Why it can't do more: where the pattern comes from, "Needs Workshop Lv 2", what's missing ...
var note_label: Label
var needle: SewingNeedle = SewingNeedle.new()

var _rules: GearRules
var _sewing: Tween


func _init(shown: GearDef, rules: GearRules = GearRules.current()) -> void:
	super._init()
	piece = shown
	_rules = rules
	name = "Gear_%s" % piece.id
	caption.visible = false
	grows_on_hover = false
	box.radius = 20.0
	box.pad(14, 10)
	face.custom_minimum_size = TILE_SIZE
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(row)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override(&"separation", 2)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left)
	picture = GearPicture.new(piece, true)
	picture.custom_minimum_size = Vector2.ONE * PICTURE_SIDE
	left.add_child(picture)
	dots_label = _line("", 20, UiColors.PURPLE, PICTURE_SIDE)
	dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(dots_label)
	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override(&"separation", 3)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var words_width: float = TILE_SIZE.x - PICTURE_SIDE - 30.0
	name_label = _line(piece.display_name, 24, UiColors.PURPLE, words_width, UiFonts.heading())
	right.add_child(name_label)
	text_label = _line(KeyBindings.fill(piece.text), 16, UiColors.INK, words_width)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(text_label)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(bottom)
	cost_row = HBoxContainer.new()
	cost_row.add_theme_constant_override(&"separation", 10)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cost_row)
	action_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(action_tag)
	note_label = _line("", 16, UiColors.INK_SOFT, words_width, UiFonts.heading())
	right.add_child(note_label)
	face.add_child(needle)


## Shows the tile for player `player` and the town in `save`: picture, dots, price, action
## and note. `building_names` maps a building id to its name ("Build the Watchtower to Lv 2").
func show_state(save: TownSave, player: int, building_names: Dictionary[String, String]) -> void:
	var id: String = String(piece.id)
	var at: int = save.gear.stitch_level(id)
	var known: bool = at > 0 or save.gear.has_pattern(id)
	picture.locked = not known
	picture.queue_redraw()
	name_label.text = piece.display_name if known else "?"
	text_label.visible = known
	dots_label.text = dots(at, piece.max_level()) if at > 0 else ""
	action = GearBook.action_for(save, piece, player, _rules)
	can_act = GearBook.can_act(save, piece, player, _rules)
	worn = save.gear.wearer_of(id) == player
	action_tag.label.text = action_text(action, at)
	action_tag.visible = action != GearBook.Action.NONE
	action_tag.modulate = Color.WHITE if can_act else TownBuilding.SHORT_TINT
	_show_cost(save)
	note_label.text = note(save, player, building_names)
	note_label.visible = not note_label.text.is_empty()
	if worn:
		box.fill = WORN_FILL
		set_stitch(WORN_STITCH)
	else:
		box.fill = UiColors.FELT
		set_stitch(READY_STITCH if can_act else UiColors.STITCH)
	queue_redraw()


## The label of the main action ("Sew", "Stitch to Lv 2" ...; "" for NONE).
func action_text(now: GearBook.Action, at: int) -> String:
	match now:
		GearBook.Action.SEW:
			return _rules.sew_text
		GearBook.Action.STITCH:
			return _rules.stitch_text % (at + 1)
		GearBook.Action.WEAR:
			return _rules.wear_text
		GearBook.Action.TAKE_OFF:
			return _rules.take_off_text
	return ""


## Why the tile can't do more right now ("" when nothing is in the way).
func note(save: TownSave, player: int, building_names: Dictionary[String, String]) -> String:
	var wear: GearBook.Wear = GearBook.wear_state(save, piece, player, _rules)
	match wear:
		GearBook.Wear.TAKEN:
			return _rules.taken_text % (save.gear.wearer_of(String(piece.id)) + 1)
		GearBook.Wear.SLOT_LOCKED:
			return _rules.needs_workshop_text % _rules.slot_level(piece.slot)
		GearBook.Wear.CAN_WEAR:
			return ""
	return _step_note(save, building_names)


## The note about the piece's next sewing step (for pieces not sewn yet or worn by this player).
func _step_note(save: TownSave, building_names: Dictionary[String, String]) -> String:
	var text: String = ""
	match GearBook.step_of(save, piece, _rules):
		GearBook.Step.NO_PATTERN:
			text = source_text(building_names)
		GearBook.Step.NO_WORKSHOP:
			text = _rules.repair_text
		GearBook.Step.NEEDS_LEVEL:
			var level: int = GearBook.workshop_level_needed(save, piece, _rules)
			text = _rules.needs_workshop_text % level
		GearBook.Step.MISSING:
			text = BuildingCard.missing_text(save.missing(_next_cost(save)))
		GearBook.Step.MAXED:
			text = _rules.maxed_text if worn else ""
	return text


## Where the pattern comes from ("Build the Watchtower to Lv 2", "Big Ted drops this").
func source_text(building_names: Dictionary[String, String]) -> String:
	if piece.source_kind != GearDef.Source.BUILDING:
		return piece.found_text
	var building: String = building_names.get(String(piece.source), String(piece.source))
	return _rules.building_source_text % [building, piece.source_level]


## "●●○" for stitch level `at` of `top`.
static func dots(at: int, top: int) -> String:
	return DOT_ON.repeat(at) + DOT_OFF.repeat(maxi(top - at, 0))


## The sewing moment: the needle bobs along a row of stitches, then a pop.
func play_sewn() -> void:
	if _sewing != null:
		_sewing.kill()
	if UiFeel.reduced() or not is_inside_tree():
		needle.progress = 1.0
		return
	needle.progress = 0.0
	_sewing = create_tween()
	_sewing.tween_property(needle, "progress", 1.0, _rules.sewing_seconds)


func is_sewing() -> bool:
	return needle.is_sewing()


## The price of its next step (sew or stitch), or nothing when it is maxed.
func _next_cost(save: TownSave) -> Dictionary[String, int]:
	var next: GearLevel = piece.level(save.gear.stitch_level(String(piece.id)) + 1)
	return next.cost() if next != null else {}


func _show_cost(save: TownSave) -> void:
	for counter: JarCounter in cost_counters.values():
		cost_row.remove_child(counter)
		counter.queue_free()
	cost_counters.clear()
	if action != GearBook.Action.SEW and action != GearBook.Action.STITCH:
		return
	var cost: Dictionary[String, int] = _next_cost(save)
	for material: String in cost:
		if cost[material] <= 0:
			continue
		var counter: JarCounter = JarCounter.new(material, 18, 24.0).on_felt()
		counter.show_amount(cost[material])
		if save.material(material) < cost[material]:
			counter.modulate = TownBuilding.SHORT_TINT
		cost_row.add_child(counter)
		cost_counters[material] = counter


func _line(words: String, font_size: int, color: Color, width: float, font: Font = null) -> Label:
	var line: Label = UiFonts.label(words, font_size, color, font)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(width, 0.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
