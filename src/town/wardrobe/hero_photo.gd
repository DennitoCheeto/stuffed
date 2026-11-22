class_name HeroPhoto
extends Control
## A hero standing in the hero picker's photo (spec 08 §5): a plushie hero drawn like in the game
## (calmed colours), Banane as his felt puppet. A hero not rescued yet is a dark felt silhouette.

## Locked heroes are drawn in this colour (the look times it: a dark shape, no details).
const SILHOUETTE: Color = Color(0.2, 0.18, 0.26, 1.0)
## Banane's puppet is about 75 px tall; this fits him to the photo.
const BANANE_FILL: float = 0.8
const BANANE_HEIGHT: float = 80.0

var hero: HeroStats
var locked: bool = false
## Banane's puppet (null for plushie heroes).
var puppet: BananePuppet
## What the hero wears in the photo (spec 09 §7): drawn over it at the hero's gear anchors.
var worn: WornGear = WornGear.new()
## Draws the gear over the hero (a child, so it is drawn after the hero).
var gear_layer: Control = Control.new()


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
	gear_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gear_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear_layer.draw.connect(_draw_gear)
	add_child(gear_layer)


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


## Puts `gear` on the hero in the photo (hidden slots aren't drawn; locked heroes wear nothing).
func wear(gear: WornGear) -> void:
	worn = gear
	gear_layer.queue_redraw()


## The pieces drawn on the photo (tests).
func shown_gear() -> Array[GearDef]:
	return [] as Array[GearDef] if locked else worn.shown()


## Where a piece in `slot` sits in the photo: the hero's feet stand at 92% of the height and the
## hero fills 80% of it (like the plushie photos and Banane's puppet here).
func gear_point(slot: int) -> Vector2:
	return _feet() + hero.gear_anchor(slot) * _grow()


func _grow() -> float:
	var tall: float = BANANE_HEIGHT if hero.plushie == null else hero.puppet_height
	return size.y * BANANE_FILL / tall


func _feet() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.92)


func _draw_gear() -> void:
	var side: float = HeroGear.SIDE * hero.gear_scale * _grow()
	for piece: GearDef in shown_gear():
		var at: Vector2 = gear_point(piece.slot)
		GearLook.draw(gear_layer, piece, worn.level_of(piece), at, side, piece.color, 1.5)
