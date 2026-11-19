class_name GearPicture
extends Control
## A piece of gear on its sewing table tile (spec 09 §6): the piece as it looks on the heroes
## (GearLook: a cap, a vest, a charm on a loop in its own calm colour with the ink outline and
## one more detail per stitch level). A piece whose pattern wasn't found yet is a dark
## silhouette; a found piece not sewn yet shows its plain seam.

const SILHOUETTE: Color = Color(0.2, 0.18, 0.26, 1.0)
const OUTLINE_WIDTH: float = 2.5

var piece: GearDef
var locked: bool = false
## Its stitch level (0 = not sewn yet: drawn with the Lv 1 look).
var level: int = 0


func _init(shown: GearDef, is_locked: bool) -> void:
	piece = shown
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72, 72)


## The colour it is drawn in.
func fill_color() -> Color:
	return SILHOUETTE if locked else piece.color


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	var shown_level: int = 0 if locked else maxi(level, 1)
	GearLook.draw(self, piece, shown_level, size / 2.0, side, fill_color(), OUTLINE_WIDTH)
