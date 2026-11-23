class_name HeroPhoto
extends Control
## A hero standing in the hero picker's photo (spec 08 §5): a plushie hero drawn like in the game
## (calmed colours), Banane as his felt puppet. A hero not rescued yet is a dark felt silhouette.
## Gear is not drawn on the hero (spec 09 §7, #331).

## Locked heroes are drawn in this colour (the look times it: a dark shape, no details).
const SILHOUETTE: Color = Color(0.2, 0.18, 0.26, 1.0)
## Banane's puppet is about 75 px tall; this fits him to the photo.
const BANANE_FILL: float = 0.8
const BANANE_HEIGHT: float = 80.0

var hero: HeroStats
var locked: bool = false
## Banane's puppet (null for plushie heroes).
var puppet: BananePuppet


func _init(who: HeroStats, is_locked: bool) -> void:
	hero = who
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hero.plushie == null:
		puppet = BananePuppet.new()
		# Always: the town is frozen while the picker / sewing table is open, and the puppet
		# must still redraw its soft edges once the photo has popped in (#338).
		puppet.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(puppet)
	else:
		var look: PlushieDef = _silhouette(hero.plushie) if locked else hero.plushie.calmed()
		var photo: PlushiePhoto = PlushiePhoto.new(look)
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if locked:
			photo.modulate = SILHOUETTE
		add_child(photo)


## True when the hero shows as a silhouette (tests).
func is_silhouette() -> bool:
	return locked


## The plushie in one flat dark felt colour (no scarf, no face: a surprise).
static func _silhouette(who: PlushieDef) -> PlushieDef:
	var shape: PlushieDef = who.duplicate() as PlushieDef
	shape.body_color = SILHOUETTE
	shape.accent_color = SILHOUETTE
	shape.detail_color = SILHOUETTE
	shape.patch_color = SILHOUETTE
	return shape


func _ready() -> void:
	resized.connect(_place_puppet)
	if puppet != null:
		puppet.show_still()
	_place_puppet()


func _place_puppet() -> void:
	if puppet == null:
		return
	var grow: float = size.y * BANANE_FILL / BANANE_HEIGHT
	puppet.scale = Vector2.ONE * grow
	puppet.position = Vector2(size.x / 2.0, size.y * 0.92 - HeroMarker.FEET.y * grow)
