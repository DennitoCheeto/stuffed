class_name FeltAtlas
extends RefCounted
## Hundreds of zombies drawn as many small felt shapes would cost tens of thousands of draw calls.
## So every felt part (a zombie's arm, body, head, ...) is drawn once, in code, into one shared
## texture; zombies show those parts as sprites, which the renderer draws in big batches.
## The look stays "drawn in code", it is just cached. Main calls `bake` once at startup.

## Parts are baked at this many pixels per concept unit (twice the on-screen size, so they stay
## sharp when the camera or window scales them).
const BAKE_SCALE: float = 0.6
const PADDING: int = 4
const ATLAS_WIDTH: int = 1024
const FELT_MATERIAL: ShaderMaterial = preload("res://src/puppet/felt_material.tres")

## The shared texture. It stays the same object after baking, so sprites made before the bake
## show their parts as soon as it is done.
static var texture: ImageTexture
static var is_baked: bool = false

static var _parts: Dictionary[StringName, AtlasPart] = {}
static var _atlas_size: Vector2i = Vector2i.ZERO


## A sprite showing part `key` (e.g. "shambler/body") with the part's pivot at the sprite's
## position, sized in concept units.
static func make_sprite(key: StringName) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	show_part(sprite, key)
	return sprite


## Makes an existing sprite show part `key` (same rules as `make_sprite`).
static func show_part(sprite: Sprite2D, key: StringName) -> void:
	_ensure_layout()
	var atlas_part: AtlasPart = _parts[key]
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = atlas_part.region
	sprite.centered = false
	sprite.offset = -atlas_part.origin
	sprite.scale = Vector2.ONE / BAKE_SCALE


static func has_part(key: StringName) -> bool:
	_ensure_layout()
	return _parts.has(key)


## Draws all parts into an off-screen viewport (under `host`) once and keeps the picture.
## Without a screen (headless tests) the atlas stays blank, which doesn't matter there.
static func bake(host: Node) -> void:
	_ensure_layout()
	if is_baked or DisplayServer.get_name() == "headless":
		return
	is_baked = true
	var viewport: SubViewport = SubViewport.new()
	viewport.size = _atlas_size
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var holder: Node2D = Node2D.new()
	holder.material = FELT_MATERIAL
	viewport.add_child(holder)
	var pieces: Dictionary[StringName, FeltPiece] = _all_pieces()
	for key: StringName in pieces:
		var piece: FeltPiece = pieces[key]
		var atlas_part: AtlasPart = _parts[key]
		piece.position = atlas_part.region.position + atlas_part.origin
		piece.scale = Vector2.ONE * BAKE_SCALE
		piece.use_parent_material = true
		holder.add_child(piece)
	host.add_child(viewport)
	await RenderingServer.frame_post_draw
	texture.set_image(viewport.get_texture().get_image())
	viewport.queue_free()


## Every felt part of the game, freshly built.
static func _all_pieces() -> Dictionary[StringName, FeltPiece]:
	var pieces: Dictionary[StringName, FeltPiece] = {}
	pieces.merge(ZombiePuppet.make_parts())
	pieces.merge(XpButtonLook.make_parts())
	return pieces


## Places every part on rows ("shelves") in the atlas, once.
static func _ensure_layout() -> void:
	if texture != null:
		return
	var pieces: Dictionary[StringName, FeltPiece] = _all_pieces()
	var cursor: Vector2i = Vector2i(PADDING, PADDING)
	var row_height: int = 0
	for key: StringName in pieces:
		var box: Rect2 = pieces[key].bounds()
		var size: Vector2i = Vector2i((box.size * BAKE_SCALE).ceil())
		if cursor.x + size.x + PADDING > ATLAS_WIDTH:
			cursor = Vector2i(PADDING, cursor.y + row_height + PADDING)
			row_height = 0
		var atlas_part: AtlasPart = AtlasPart.new()
		atlas_part.region = Rect2(cursor, size)
		atlas_part.origin = -box.position * BAKE_SCALE
		_parts[key] = atlas_part
		cursor.x += size.x + PADDING
		row_height = maxi(row_height, size.y)
		pieces[key].free()
	_atlas_size = Vector2i(ATLAS_WIDTH, cursor.y + row_height + PADDING)
	var blank: Image = Image.create_empty(_atlas_size.x, _atlas_size.y, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(blank)


## Where one part sits in the atlas.
class AtlasPart:
	## Pixel rectangle in the atlas texture.
	var region: Rect2 = Rect2()
	## The part's pivot inside `region`, in pixels.
	var origin: Vector2 = Vector2.ZERO
