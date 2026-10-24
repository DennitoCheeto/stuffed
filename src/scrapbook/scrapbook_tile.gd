class_name ScrapbookTile
extends SewnButton
## One spot on a Scrapbook page: the felt picture and the name, or a silhouette and "?" while it
## hasn't been seen. Focusing or hovering it shows its details next to the grid.
## Stitched Scrapbook look (spec 04 §6.7): a seen entry is a taped-on photo, a bit crooked; an
## unseen one is a plain felt patch still waiting for its photo. Both lift like sewn buttons.

## Focused or hovered: show my details.
signal looked_at(tile: ScrapbookTile)

const SIZE: Vector2 = Vector2(176, 176)
const PICTURE: float = 100.0
const UNSEEN_NAME: String = "?"
const UNSEEN_COLOR: Color = Color("#e4d8c2")
const NAME_COLOR: Color = UiColors.INK
## Photos lean a little, each its own way (degrees, picked by the entry's place on the page).
const TILTS: Array[float] = [-2.5, 1.5, -1.0, 2.5, -1.5, 1.0, 2.0]
const TAPES: Array[Color] = [UiColors.TAPE_TEAL, UiColors.TAPE_PINK, UiColors.TAPE_GOLD]

var entry: ScrapbookEntry
var seen: bool = false
var picture: ScrapbookPicture
var name_label: Label


func _init(what: ScrapbookEntry, is_seen: bool, index: int = 0) -> void:
	super("", false)
	entry = what
	seen = is_seen
	caption.visible = false
	face.custom_minimum_size = SIZE
	box.depth = 0.0
	if seen:
		box.fill = UiColors.PHOTO
		box.radius = 4.0
		box.stitch_inset = 0.0
		box.shadow = UiColors.SHADOW
		box.shadow_offset = 5.0
		box.add_tape(0.5, TILTS[(index + 3) % TILTS.size()], TAPES[index % TAPES.size()])
		turned = TILTS[index % TILTS.size()]
	else:
		box.fill = UNSEEN_COLOR
		box.radius = 18.0
		box.stitch_inset = 7.0
		set_stitch(UiColors.STITCH)
	box.pad(8, 10)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(column)
	picture = ScrapbookPicture.new(PICTURE)
	picture.show_entry(entry, seen)
	column.add_child(picture)
	var words: String = entry.display_name if seen else UNSEEN_NAME
	name_label = UiFonts.label(words, 22, NAME_COLOR, UiFonts.hand())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(SIZE.x - 16.0, 0.0)
	column.add_child(name_label)
	focus_entered.connect(func() -> void: looked_at.emit(self))
	mouse_entered.connect(func() -> void: looked_at.emit(self))


## How far the photo leans (degrees; 0 for an unseen patch).
func lean() -> float:
	return turned
