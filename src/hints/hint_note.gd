class_name HintNote
extends Wobbly
## A first-time hint (spec 10 §6): a small taped paper note with hand-written words and the
## bound keys on fabric tags. It only shows; it never takes the mouse or keys.

const TOKEN: String = "\\{([a-z_0-9]+)\\}"

## The hint this note shows.
var hint: HintDef
## The hand-written parts and the key tags, in reading order.
var words: Array[Label] = []
var key_tags: Array[FabricTag] = []
var box: StyleBoxFelt = StyleBoxFelt.new(UiColors.FELT_LIGHT, UiColors.STITCH)
var _row: HBoxContainer = HBoxContainer.new()
var _font_size: int = 30


func _init(shown: HintDef, font_size: int = 30, degrees: float = 1.5) -> void:
	hint = shown
	_font_size = font_size
	name = "Hint_%s" % shown.id
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.radius = 6.0
	box.stitch_inset = 0.0
	box.shadow = UiColors.SHADOW
	box.shadow_offset = 4.0
	box.pad(22, 12)
	box.add_tape(0.5, -4.0, UiColors.TAPE_TEAL)
	var paper: PanelContainer = PanelContainer.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", box)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 8)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(_row)
	set_body(paper)
	tilt = degrees
	add_to_group(KeyBindings.HINTS)
	show_keys()


## Builds the words and key tags again (a key was rebound).
func show_keys() -> void:
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	words.clear()
	key_tags.clear()
	for part: Dictionary in parts(hint.text):
		if part["key"]:
			_add_tag(str(part["text"]))
		else:
			_add_words(str(part["text"]))


## Everything the note says, keys filled in ("WASD to walk · Space to dash").
func shown_text() -> String:
	var text: String = ""
	for part: Dictionary in parts(hint.text):
		text += str(part["text"])
	return text


## `text` cut into hand-written words and keys: [{text, key}]. Tokens next to each other share
## one key tag ("{move_up}{move_left}{move_down}{move_right}" -> "WASD").
static func parts(text: String) -> Array[Dictionary]:
	var regex: RegEx = RegEx.create_from_string(TOKEN)
	var result: Array[Dictionary] = []
	var at: int = 0
	for found: RegExMatch in regex.search_all(text):
		var before: String = text.substr(at, found.get_start() - at)
		var key: String = KeyBindings.key_text(found.get_string(1))
		if before == "" and not result.is_empty() and result[-1]["key"]:
			result[-1]["text"] = str(result[-1]["text"]) + key
		else:
			if before != "":
				result.append({"text": before, "key": false})
			result.append({"text": key, "key": true})
		at = found.get_end()
	if at < text.length():
		result.append({"text": text.substr(at), "key": false})
	return result


func _add_words(text: String) -> void:
	var label: Label = UiFonts.label(text.strip_edges(), _font_size, UiColors.INK, UiFonts.hand())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(label)
	words.append(label)


func _add_tag(key: String) -> void:
	var tag: FabricTag = FabricTag.new(key, UiColors.TAG, UiColors.INK, _font_size - 8)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(tag)
	key_tags.append(tag)
