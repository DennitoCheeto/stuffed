class_name HeroGear
extends Node2D
## The sewn-on gear a hero wears, drawn on its puppet (spec 09 §7, AC-100): every shown piece is
## baked once into one small picture (a SubViewport, like the plushie heroes' walk sheet) and
## shown as one sprite per piece, at the anchors in the hero's data. The puppet hangs each sprite
## on the part it moves with (Banane's head, a plushie's whole body), so the gear bobs, waddles,
## hops, squashes, leans and flashes with it. The sprites share the heroes' ink outline shader.
## At most 3 sprites: a fully geared hero costs at most 3 more draw calls (AC-104).

const SHADER: Shader = preload("res://src/player/hero_sprite.gdshader")
## The picture is drawn at this scale (sharp when the camera zooms in).
const BAKE_SCALE: float = 2.0
## How big a piece is on a hero with `HeroStats.gear_scale` 1 (pixels).
const SIDE: float = 24.0
## Room around each piece in the picture for the outline (pixels).
const PAD: float = 4.0
## The ink line between a piece's own parts (pixels); the shader draws the outline around it.
const INNER_LINE: float = 1.0
## The heroes' ink outline (BananePuppet.OUTLINE_COLOR, about 2 px on screen: #172). Copied, not
## referenced: the puppets use this class, and a loop of script references leaks at exit.
const OUTLINE_COLOR: Color = Color("#1d1a24")
const OUTLINE_PIXELS: float = 2.04

## What the hero wears right now.
var worn: WornGear = WornGear.new()
## The baked pieces (null while nothing is shown) and the sprite per slot name shown on the hero.
var picture: SubViewport
var sprites: Dictionary[String, Sprite2D] = {}
var gear_material: ShaderMaterial = ShaderMaterial.new()

var _key: String = ""
var _side: float = SIDE
var _shown: Array[GearDef] = []
## Patch Vest: true while its patch is on (the vest shows the picture cell with the patch).
var _patch_on: bool = true


func _init() -> void:
	name = "Gear"
	gear_material.shader = SHADER
	gear_material.set_shader_parameter("outline_color", OUTLINE_COLOR)
	gear_material.set_shader_parameter("outline_texels", OUTLINE_PIXELS * BAKE_SCALE)


## Puts `gear` on a hero whose pieces are `side` pixels big. `place` hangs each new sprite on the
## puppet: `place.call(piece: GearDef, sprite: Sprite2D)` adds it as a child and moves it to its
## anchor. Rebakes only when what is shown changed. Returns true if it rebaked.
func dress(gear: WornGear, side: float, place: Callable) -> bool:
	worn = gear
	var key: String = "%s@%.2f" % [gear.look_key(), side]
	if key == _key:
		return false
	_key = key
	_side = side
	_clear()
	_shown = gear.shown()
	if _shown.is_empty():
		return true
	_bake()
	for i: int in _shown.size():
		var piece: GearDef = _shown[i]
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Gear_%s" % piece.slot_name()
		sprite.texture = picture.get_texture()
		sprite.region_enabled = true
		sprite.region_rect = _cell_rect(i)
		sprite.scale = Vector2.ONE / BAKE_SCALE
		sprite.material = gear_material
		sprites[piece.slot_name()] = sprite
		place.call(piece, sprite)
	show_patch(_patch_on)
	return true


## Patch Vest: shows the vest with its patch on or off (the picture holds both, so this costs
## no draws). Does nothing when no Patch Vest is shown.
func show_patch(on: bool) -> void:
	_patch_on = on
	for i: int in _shown.size():
		if GearLook.has_patch(_shown[i]):
			var cell: int = i if on else _shown.size()
			sprites[_shown[i].slot_name()].region_rect = _cell_rect(cell)


## True while a shown Patch Vest wears its patch (tests).
func shows_patch() -> bool:
	return _patch_on


## The sprite showing what is worn in `slot` (null = nothing shown there).
func sprite(slot: GearDef.Slot) -> Sprite2D:
	return sprites.get(GearDef.SLOT_NAMES[slot], null)


## How white the hit flash is on the pieces (the puppet passes its own).
func set_flash(amount: float) -> void:
	gear_material.set_shader_parameter("flash", amount)


func flash() -> float:
	var amount: Variant = gear_material.get_shader_parameter("flash")
	return float(amount) if amount is float else 0.0


## How big a piece is on the hero (pixels).
func side() -> float:
	return _side


func _cell() -> float:
	return _side + PAD * 2.0


## Cells in the picture: one per shown piece, plus the Patch Vest without its patch.
func _cells() -> int:
	for piece: GearDef in _shown:
		if GearLook.has_patch(piece):
			return _shown.size() + 1
	return _shown.size()


## Where cell `index` is in the picture (its pixels).
func _cell_rect(index: int) -> Rect2:
	return Rect2(Vector2(index * _cell(), 0.0) * BAKE_SCALE, Vector2.ONE * _cell() * BAKE_SCALE)


func _clear() -> void:
	for slot_name: String in sprites:
		var old: Sprite2D = sprites[slot_name]
		if is_instance_valid(old):
			old.free()
	sprites.clear()
	if picture != null:
		picture.free()
		picture = null


func _bake() -> void:
	picture = SubViewport.new()
	picture.transparent_bg = true
	picture.size = Vector2i((Vector2(_cells(), 1.0) * _cell() * BAKE_SCALE).ceil())
	picture.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter: Node2D = Node2D.new()
	painter.scale = Vector2.ONE * BAKE_SCALE
	painter.draw.connect(_paint.bind(painter))
	picture.add_child(painter)
	add_child(picture)


func _paint(canvas: Node2D) -> void:
	for i: int in _shown.size():
		var piece: GearDef = _shown[i]
		var middle: Vector2 = Vector2(i * _cell() + _cell() / 2.0, _cell() / 2.0)
		GearLook.draw(canvas, piece, worn.level_of(piece), middle, _side, piece.color, INNER_LINE)
		if GearLook.has_patch(piece):
			var spare: Vector2 = Vector2(_shown.size() * _cell() + _cell() / 2.0, _cell() / 2.0)
			var level: int = worn.level_of(piece)
			GearLook.draw(canvas, piece, level, spare, _side, piece.color, INNER_LINE, false)
