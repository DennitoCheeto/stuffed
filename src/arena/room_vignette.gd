class_name RoomVignette
extends CanvasLayer
## A soft warm vignette at the screen edges of the Bedroom (spec 05 §2, §4.1): one stretched
## radial gradient over the world, under the HUD. Clear in the middle, the palette's see-through
## vignette colour in the corners. Never catches the mouse.

const TEXTURE_SIZE: int = 256

var shade: TextureRect = TextureRect.new()


func _init(room: BedroomRoom) -> void:
	name = "Vignette"
	var tint: Color = WorldPalette.current().vignette
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(tint, 0.0))
	gradient.set_offset(0, room.vignette_clear)
	gradient.set_color(1, tint)
	gradient.set_offset(1, 1.0)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	shade.texture = texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


## How strong the vignette is at a spot on the screen (0..1 of the palette's alpha; uv 0..1).
func strength_at(uv: Vector2) -> float:
	var texture: GradientTexture2D = shade.texture as GradientTexture2D
	var reach: float = texture.fill_from.distance_to(texture.fill_to)
	var share: float = clampf(uv.distance_to(texture.fill_from) / reach, 0.0, 1.0)
	return texture.gradient.sample(share).a / WorldPalette.current().vignette.a
