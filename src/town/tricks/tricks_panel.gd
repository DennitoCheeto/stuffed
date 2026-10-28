class_name TricksPanel
extends CanvasLayer
## The Tricks panel of one building (spec 06 §2, AC-67): its 3 tricks as felt patches sewn onto
## a strip of cloth, joined by a thread (1 → 2 → ★). Click a patch, or press 1 / 2 / 3, to buy
## it; arrow keys + Enter work too. T or Esc closes. Until the first trick is bought it shows
## the hint "Tricks work in every run. Buy them in order." Keeps working while the town waits.

## The player wants trick `index` of the shown building.
signal buy_requested(index: int)
signal closed

const FIRST_HINT: String = "Tricks work in every run. Buy them in order."
const CONTROLS_HINT: String = "Click or 1 / 2 / 3: buy        T or Esc: close"
const PICK_ACTIONS: Array[StringName] = [&"pick_card_1", &"pick_card_2", &"pick_card_3"]
const STRIP_COLOR: Color = UiColors.STICKER_PINK
const THREAD_COLOR: Color = UiColors.PURPLE
## How big the felt puff is when a trick is bought (a building's rebuild puff is 1).
const PUFF_SIZE: float = 0.45

## The building whose tricks are shown (null = closed).
var building: TownBuilding
## The player who opened it (their T closes it again).
var opener: int = 0
## One patch per trick, in branch order.
var patches: Array[TrickPatch] = []
var cloth: MenuCloth = MenuCloth.new(0.92)
var panel: FeltPanel = FeltPanel.new(-1.0)
var title: HandTitle = HandTitle.new("", 58)
## The first-time hint, or which keys do what.
var hint_label: Label
var level_tag: FabricTag = FabricTag.new("", UiColors.TAG, UiColors.INK, 20)
var strip: PanelContainer = PanelContainer.new()
var motion: ScreenMotion = ScreenMotion.new()

var _row: HBoxContainer = HBoxContainer.new()
var _thread: ThreadLine = ThreadLine.new()


func _init() -> void:
	name = "TricksPanel"
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cloth)
	add_child(motion)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel.add_tape(0.15, -5.0, UiColors.TAPE_TEAL).add_tape(0.85, 4.0)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	panel.content.add_child(column)
	column.add_child(title)
	level_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(level_tag)
	hint_label = UiFonts.label("", 24, UiColors.INK_SOFT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint_label)
	var box: StyleBoxFelt = StyleBoxFelt.new(STRIP_COLOR, STRIP_COLOR.lightened(0.4))
	box.radius = 18.0
	box.pad(26, 22)
	strip.add_theme_stylebox_override(&"panel", box)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(strip)
	_thread.color = THREAD_COLOR
	strip.add_child(_thread)
	_row.add_theme_constant_override(&"separation", 34)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(_row)


func is_open() -> bool:
	return visible


## Opens the panel for `target` with the town's jars in `save`; player `by` (0 = player 1)
## opened it and closes it with their own T.
func open(target: TownBuilding, save: TownSave, by: int = 0) -> void:
	building = target
	opener = by
	for old: TrickPatch in patches:
		_row.remove_child(old)
		old.queue_free()
	patches.clear()
	for index: int in target.building.tricks.size():
		var patch: TrickPatch = TrickPatch.new(target.building.tricks[index])
		patch.pressed.connect(_on_patch_pressed.bind(index))
		_row.add_child(patch)
		patches.append(patch)
	_thread.links.clear()
	_thread.links.append_array(patches)
	title.label.text = "%s tricks" % target.building.display_name
	refresh(save)
	visible = true
	motion.open([panel])
	var next_one: int = TrickBook.buyable(save, target.building)
	if not patches.is_empty():
		patches[maxi(next_one, 0)].grab_focus()


## Updates every patch, the level tag and the hint for the jars in `save` right now.
func refresh(save: TownSave) -> void:
	if building == null:
		return
	var def: BuildingDef = building.building
	level_tag.label.text = BuildingCard.level_text(building.level, def.max_level())
	var first_time: bool = save.tricks.is_empty()
	hint_label.text = FIRST_HINT if first_time else CONTROLS_HINT
	hint_label.add_theme_color_override(
		&"font_color", UiColors.TEAL if first_time else UiColors.INK_SOFT
	)
	for index: int in patches.size():
		patches[index].show_state(TrickBook.state_of(save, def, index), save)


## The buy moment for trick `index` (already paid for): check stitch, pop and a small puff.
func play_bought(index: int) -> void:
	var patch: TrickPatch = patches[index]
	patch.sew_on()
	Sfx.play(&"pop")
	if is_inside_tree():
		add_child(TownPuff.new(patch.get_global_rect(), PUFF_SIZE))


## True when the first-time hint shows.
func shows_first_hint() -> bool:
	return visible and hint_label.text == FIRST_HINT


func close() -> void:
	if not visible:
		return
	motion.finish()
	visible = false
	building = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var own_key: StringName = StringName("p%d_tricks" % (opener + 1))
	if event.is_action_pressed(&"pause") or event.is_action_pressed(own_key):
		get_viewport().set_input_as_handled()
		close()
		return
	for index: int in mini(PICK_ACTIONS.size(), patches.size()):
		if event.is_action_pressed(PICK_ACTIONS[index]):
			get_viewport().set_input_as_handled()
			patches[index].grab_focus()
			_on_patch_pressed(index)
			return


func _on_patch_pressed(index: int) -> void:
	var patch: TrickPatch = patches[index]
	if patch.state == TrickBook.State.BOUGHT:
		return
	if patch.disabled:
		patch.nope()
		return
	buy_requested.emit(index)
