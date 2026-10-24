class_name FeltPanel
extends Wobbly
## A felt patch panel (spec 04 §2, look A): cream felt, a dashed stitch line inside the edge, a
## soft shadow, optionally tilted (look B) and held on with tape. Put content into `content`.

const PADDING: Vector2 = Vector2(34, 28)

## Where the panel's content goes (a PanelContainer with the felt look).
var content: PanelContainer = PanelContainer.new()
var box: StyleBoxFelt = StyleBoxFelt.new()


func _init(degrees: float = 0.0) -> void:
	box.shadow = UiColors.SHADOW
	box.pad(PADDING.x, PADDING.y)
	content.add_theme_stylebox_override("panel", box)
	set_body(content)
	tilt = degrees


## Adds a tape strip on the top edge (`at` = share of the width).
func add_tape(at: float, degrees: float, color: Color = UiColors.TAPE_GOLD) -> FeltPanel:
	box.add_tape(at, degrees, color)
	return self
