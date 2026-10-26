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
## Tone-on-tone patterns on the quilt patches (gingham checks, polka dots, corduroy ribs), one
## per patch kind, drawn at `pattern_alpha`.
@export var quilt_patterns: Array[Color] = []
## Felt patches (stars, hearts) sewn onto the plain patches.
@export var quilt_appliques: Array[Color] = []
## The tape measure road: its face and the stripe along its edges (they lie next to each other).
@export var road_tape: Array[Color] = []
## Tick marks and numbers on the tape.
@export var tape_ticks: Color = Color.WHITE
## The coloured thread paths to the buildings, one per building.
@export var thread_paths: Array[Color] = []
## The rick-rack trim along the pillow walls.
@export var rick_rack: Color = Color.WHITE
## Felt flowers: petals and the middle.
@export var flower_petals: Array[Color] = []
@export var flower_middle: Color = Color.WHITE
## Glass marbles (see-through tints; the swirl uses `toys`).
@export var marbles: Array[Color] = []

@export_group("Buildings")
## Wood in 3/4 view, lit from the top-left: top faces lightest, side faces darkest.
@export var wood_top: Color = Color.WHITE
@export var wood: Color = Color.WHITE
@export var wood_side: Color = Color.WHITE
## Plank gaps and grain lines drawn on the wood.
@export var wood_grain: Color = Color.WHITE
## The dark inside of an open box.
@export var box_inside: Color = Color.WHITE
@export var nail: Color = Color.WHITE
## Brass corners and clasps, and plain metal (scissors, needles, brackets).
@export var brass: Color = Color.WHITE
@export var brass_dark: Color = Color.WHITE
@export var metal: Color = Color.WHITE
@export var metal_dark: Color = Color.WHITE
## Glass: the body, its shaded side and the white shine.
@export var glass: Color = Color.WHITE
@export var glass_side: Color = Color.WHITE
@export var glass_shine: Color = Color.WHITE
## A gold jar lid and coins.
@export var gold_lid: Color = Color.WHITE
@export var gold_lid_dark: Color = Color.WHITE
@export var coin: Color = Color.WHITE
@export var coin_rim: Color = Color.WHITE
## Gingham cloth: the base and its checks.
@export var gingham: Color = Color.WHITE
@export var gingham_check: Color = Color.WHITE
## Ribbons and bows (pink, never red), and plain twine.
@export var ribbon: Color = Color.WHITE
@export var ribbon_dark: Color = Color.WHITE
@export var twine: Color = Color.WHITE
## Sewing buttons and their holes.
@export var buttons: Array[Color] = []
@export var button_hole: Color = Color.WHITE
## Toys and weapons in the Armory: pencil yellow, pink, teal, lavender, cream.
@export var toys: Array[Color] = []
## A sharpened pencil's bare wood.
@export var pencil_wood: Color = Color.WHITE
## Paint on a finished building: the main colour and its trim.
@export var paint: Color = Color.WHITE
@export var paint_trim: Color = Color.WHITE
## Paper tags and labels.
@export var tag: Color = Color.WHITE
@export var clover: Color = Color.WHITE
## Fairy light bulbs and their cord.
@export var fairy_lights: Array[Color] = []
@export var light_cord: Color = Color.WHITE
@export var sparkle: Color = Color.WHITE
## The Snack Bar's cookie tin (front, side, lid) and its cookies.
@export var tin: Color = Color.WHITE
@export var tin_side: Color = Color.WHITE
@export var tin_lid: Color = Color.WHITE
@export var cookie: Color = Color.WHITE
## The Party Shop's strawberry pincushion (pink, never red) and its shaded side.
@export var pincushion: Color = Color.WHITE
@export var pincushion_dark: Color = Color.WHITE
## The Plush Hospital's tissue box, its tissues and the plaster cross.
@export var tissue_box: Color = Color.WHITE
@export var tissue_box_side: Color = Color.WHITE
@export var tissue: Color = Color.WHITE
@export var plaster: Color = Color.WHITE
## Little teddy plushies drawn into the buildings (on watch, napping).
@export var teddy: Color = Color.WHITE
@export var teddy_dark: Color = Color.WHITE
## The Pillow Fort: walls, the two cushion towers, the patchwork roof, the glowing Bedroom door.
@export var fort_wall: Color = Color.WHITE
@export var fort_wall_side: Color = Color.WHITE
@export var fort_towers: Array[Color] = []
@export var fort_roof: Array[Color] = []
@export var door_glow: Color = Color.WHITE
@export var door_glow_dark: Color = Color.WHITE

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

@export_group("Building art")
## The one even ink outline around a building's silhouette (px at game size).
@export_range(0.0, 8.0) var building_outline: float = 2.0
## Stitched seams: how far inside the edge, dash and gap length, thread width (px).
@export var seam_inset: float = 5.0
@export var seam_dash: float = 5.0
@export var seam_gap: float = 4.0
@export var seam_width: float = 1.6
## A ruin's colours: share of the way to grey, and how much darker.
@export_range(0.0, 1.0) var ruin_grey: float = 0.5
@export_range(0.0, 1.0) var ruin_dim: float = 0.06


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
	return [board_colors, rug_patches, quilt_patches, road_tape]


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
