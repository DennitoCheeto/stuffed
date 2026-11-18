class_name PlushiePicture
extends Node2D
## A plushie drawn once on a soft light halo and shown as one sprite (feet at this node's
## origin). Drawn shape by shape every frame, one plushie cost ~50 draw calls (#209), so the
## Plushie Buddy and the siege's helping plushies bake their look into a small picture
## (`picture`, rendered once) and show it with `sprite`. Move `sprite` for hops and leans.

## The look is drawn at this scale (sharp when the camera zooms in).
const BAKE_SCALE: float = 3.0

## The baked look (rendered once) and the sprite that shows it.
var picture: SubViewport
var sprite: Sprite2D

var _plushie: PlushieDef
var _size: float = 10.0
var _halo: Color = Color.TRANSPARENT


## `who` is drawn as it is: pass `PlushieDef.calmed()` for the run and the siege.
func setup(who: PlushieDef, size: float, halo: Color) -> void:
	_plushie = who
	_size = size
	_halo = halo


func _ready() -> void:
	var top: float = PlushieLook.top(_plushie, _size)
	var box: Vector2 = Vector2(top * 1.6, top * 1.5)
	var origin: Vector2 = Vector2(box.x / 2.0, top * 1.2)
	picture = SubViewport.new()
	picture.transparent_bg = true
	picture.size = Vector2i((box * BAKE_SCALE).ceil())
	picture.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter: Node2D = Node2D.new()
	painter.scale = Vector2.ONE * BAKE_SCALE
	painter.position = origin * BAKE_SCALE
	painter.draw.connect(_paint.bind(painter))
	picture.add_child(painter)
	add_child(picture)
	sprite = Sprite2D.new()
	sprite.texture = picture.get_texture()
	sprite.centered = false
	sprite.offset = -origin * BAKE_SCALE
	sprite.scale = Vector2.ONE / BAKE_SCALE
	# The picture's see-through halo is stored premultiplied: blend it that way, or it darkens.
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	sprite.material = blend
	add_child(sprite)


## How tall the plushie is (pixels from its feet to the top of its head).
func height() -> float:
	return PlushieLook.top(_plushie, _size)


## Draws the halo and the plushie once into the picture (feet at the painter's origin).
func _paint(canvas: Node2D) -> void:
	var top: float = PlushieLook.top(_plushie, _size)
	if _halo.a > 0.0:
		var halo: PackedVector2Array = PlushieLook.ellipse(
			Vector2(0.0, -top * 0.5), top * 0.62, top * 0.66
		)
		FeltDraw.fill(canvas, halo, _halo)
	PlushieLook.draw(canvas, _plushie, Vector2.ZERO, _size)
