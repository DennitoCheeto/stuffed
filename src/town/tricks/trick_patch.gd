class_name TrickPatch
extends SewnButton
## One trick on the Tricks panel (spec 06 §2): a felt patch with the step badge, the name, one
## line of text and below it the price (jar counters, grey when short), "Needs Lv 2", "Buy the
## trick before it first" or the missing materials. A bought patch is sewn on with a teal check
## stitch. Patches that can't be bought yet are greyed (and say "nope"); no danger colours.

const PATCH_SIZE: Vector2 = Vector2(330, 300)
const BOUGHT_STITCH: Color = UiColors.TEAL
const READY_STITCH: Color = UiColors.GOLD_EDGE
const BOUGHT_TEXT: String = "Sewn on!"
const EARLIER_TEXT: String = "Buy the trick before it first"

var trick: TrickDef
## Where it stands (TrickBook.State), set by `show_state`.
var state: TrickBook.State = TrickBook.State.NEEDS_LEVEL
var badge: TrickBadge
var name_label: Label
var text_label: Label
var cost_row: HBoxContainer
var cost_counters: Dictionary[String, JarCounter] = {}
## "Needs Lv 2", "Needs 40 more coins", "Sewn on!" ... (empty while it can be bought).
var state_label: Label
var check: CheckStitch = CheckStitch.new()

var _sewing: Tween


func _init(shown: TrickDef) -> void:
	super._init()
	trick = shown
	name = "Trick_%s" % trick.id
	caption.visible = false
	grows_on_hover = false
	box.radius = 22.0
	box.pad(20, 16)
	face.custom_minimum_size = PATCH_SIZE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	badge = TrickBadge.new(clampi(trick.needs_level, 1, 3))
	top.add_child(badge)
	name_label = _line(trick.display_name, 28, UiColors.PURPLE, UiFonts.heading())
	name_label.custom_minimum_size = Vector2(PATCH_SIZE.x - TrickBadge.SIDE - 60.0, 0.0)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(name_label)
	text_label = _line(trick.text, 21, UiColors.INK)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(text_label)
	cost_row = HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override(&"separation", 18)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(cost_row)
	state_label = _line("", 20, UiColors.INK_SOFT, UiFonts.heading())
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(state_label)
	face.add_child(check)
	_show_cost()


## Shows the patch for the town in `save`: state, price colours and the check stitch.
func show_state(now: TrickBook.State, save: TownSave) -> void:
	state = now
	for material: String in cost_counters:
		var short: bool = save.material(material) < cost_counters[material].shown
		cost_counters[material].modulate = TownBuilding.SHORT_TINT if short else Color.WHITE
	cost_row.visible = state != TrickBook.State.BOUGHT
	state_label.text = state_text(state, trick, save)
	state_label.visible = not state_label.text.is_empty()
	disabled = not (state == TrickBook.State.CAN_BUY or state == TrickBook.State.BOUGHT)
	check.visible = state == TrickBook.State.BOUGHT
	if state == TrickBook.State.BOUGHT:
		set_stitch(BOUGHT_STITCH)
	elif state == TrickBook.State.CAN_BUY:
		set_stitch(READY_STITCH)
	else:
		set_stitch(UiColors.STITCH)


## The line under the price for `now` ("" while it can be bought).
static func state_text(now: TrickBook.State, shown: TrickDef, save: TownSave) -> String:
	match now:
		TrickBook.State.BOUGHT:
			return BOUGHT_TEXT
		TrickBook.State.NEEDS_LEVEL:
			return "Needs Lv %d" % shown.needs_level
		TrickBook.State.NEEDS_EARLIER:
			return EARLIER_TEXT
		TrickBook.State.MISSING:
			return BuildingCard.missing_text(save.missing(shown.cost()))
	return ""


## The buy moment: the check stitch is sewn on, stitch by stitch.
func sew_on() -> void:
	check.visible = true
	if _sewing != null:
		_sewing.kill()
	if UiFeel.reduced() or not is_inside_tree():
		check.progress = 1.0
		return
	check.progress = 0.0
	_sewing = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sewing.tween_property(check, "progress", 1.0, UiFeel.STYLE.open_seconds)


func is_sewing() -> bool:
	return _sewing != null and _sewing.is_running()


func _show_cost() -> void:
	var cost: Dictionary[String, int] = trick.cost()
	for material: String in cost:
		var counter: JarCounter = JarCounter.new(material, 22, 30.0).on_felt()
		counter.show_amount(cost[material])
		cost_row.add_child(counter)
		cost_counters[material] = counter


func _line(words: String, font_size: int, color: Color, font: Font = null) -> Label:
	var line: Label = UiFonts.label(words, font_size, color, font)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(PATCH_SIZE.x - 40.0, 0.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
