class_name WorldPalette
extends Resource
## Every colour of the town and the Bedroom (spec 05 §2.1, "Sunny patchwork"): warm daylight
## floors, calm patterns and no danger red/orange (that belongs to enemies, vision §6). The
## numbers live in `data/art/world_palette.tres` so brightness can be tuned in minutes.
## Floor colours must stay inside a brightness band, and colours of one floor group (they lie
## next to each other) may differ only a little, so the ground never competes with zombies.

const PATH: String = "res://data/art/world_palette.tres"
const FELT_SHADER: Shader = preload("res://src/puppet/felt.gdshader")

static var _current: WorldPalette

@export_group("Bedroom floor")
## Floorboards, in the order they lie next to each other.
@export var board_colors: Array[Color] = []
## The gaps between boards.
@export var board_seam: Color = Color.WHITE
## Wood grain lines and knots on the boards.
@export var board_grain: Color = Color.WHITE
## Rug patches (gingham, corduroy, polka dot, twill, plain, ...).
@export var rug_patches: Array[Color] = []
## The rug's edge band.
@export var rug_border: Color = Color.WHITE
## Hand-stitched seams between rug patches.
@export var rug_seams: Array[Color] = []
## Toy-block walls around the room.
@export var wall_blocks: Array[Color] = []

@export_group("Bedroom furniture")
@export var bed_frame: Color = Color.WHITE
@export var bed_blanket: Color = Color.WHITE
@export var bed_fold: Color = Color.WHITE
@export var bed_pillow: Color = Color.WHITE
@export var toy_box: Color = Color.WHITE
@export var toy_box_lid: Color = Color.WHITE
@export var toy_box_band: Color = Color.WHITE
## Alphabet block towers.
@export var tower_blocks: Array[Color] = []

@export_group("Town ground")
## Quilt patches under the Pillow Fort.
@export var quilt_patches: Array[Color] = []
## Stitched seams between quilt patches.
@export var quilt_seam: Color = Color.WHITE
## Pillow walls around the town.
@export var pillow_walls: Array[Color] = []
## Loose cushions and toy blocks lying around.
@export var cushions: Array[Color] = []
@export var prop_blocks: Array[Color] = []
@export var lamp_shade: Color = Color.WHITE
@export var lamp_pole: Color = Color.WHITE
## See-through warm glow under a lamp.
@export var lamp_glow: Color = Color.WHITE

@export_group("Shared")
## The one even outline around world pieces (like the zombies').
@export var ink: Color = Color.BLACK
## Contact shadows on the floor (see-through).
@export var shadow: Color = Color.BLACK
## Light stitched seams sewn inside a shape.
@export var seam_light: Color = Color.WHITE
## Sunbeams falling across the floor (see-through).
@export var sunbeam: Color = Color.WHITE
## The soft warm vignette at the screen edges (see-through).
@export var vignette: Color = Color.BLACK
## Text on signs in the world and its outline.
@export var sign_text: Color = Color.WHITE
@export var sign_outline: Color = Color.BLACK
## A building's effect line, and the hint on a locked ruin.
@export var sign_effect: Color = Color.WHITE
@export var sign_hint: Color = Color.WHITE

@export_group("Rules")
## Every floor colour's brightness (`brightness()`) lies in this band.
@export_range(0.0, 1.0) var floor_brightness_min: float = 0.6
@export_range(0.0, 1.0) var floor_brightness_max: float = 0.95
## Colours of one floor group differ by less than this in brightness.
@export_range(0.0, 1.0) var floor_max_step: float = 0.1
## How strongly floor patterns (plaid bands, checks) show over the base colour.
@export_range(0.0, 1.0) var pattern_alpha: float = 0.35
## Felt grain on world art (the puppets' felt shader): how strong and how fine.
@export_range(0.0, 0.5) var grain_strength: float = 0.06
@export var grain_scale: float = 0.15


## The game's palette (loaded once).
static func current() -> WorldPalette:
	if _current == null:
		_current = load(PATH) as WorldPalette
	return _current


## How bright a colour looks (0 = black, 1 = white).
static func brightness(color: Color) -> float:
	return color.get_luminance()


## The floor groups: colours in one group lie next to each other on the ground.
func floor_groups() -> Array[Array]:
	return [board_colors, rug_patches, quilt_patches]


## Every colour in the palette, so tests cover new entries by themselves.
func all_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for property: Dictionary in get_property_list():
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var value: Variant = get(property.name)
		if value is Color:
			colors.append(value)
		elif value is Array:
			for item: Variant in value:
				if item is Color:
					colors.append(item)
	return colors


## A felt grain material for a world node: the grain sticks to the node's own coordinates.
func grain_material() -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FELT_SHADER
	material.set_shader_parameter(&"grain_strength", grain_strength)
	material.set_shader_parameter(&"grain_scale", grain_scale)
	return material


## Picks a colour from a list, wrapping around.
static func pick(colors: Array[Color], index: int) -> Color:
	return colors[posmod(index, colors.size())]
