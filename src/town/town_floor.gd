class_name TownFloor
extends Node2D
## The Pillow Fort's ground: a sunny quilt with a soft plaid, pillow walls around it and a few
## cozy props (cushions, block piles, lamps). Drawn once; nothing here blocks except walls.
## All colours come from the world palette (spec 05 §2.1); the ground has the felt grain.

const PLAID_STEP: float = 240.0
const WALL_PILLOW: float = 220.0

var layout: TownLayout
var palette: WorldPalette = WorldPalette.current()


func _init(town_layout: TownLayout) -> void:
	layout = town_layout
	z_index = -10
	material = palette.grain_material()


func _draw() -> void:
	var floor_rect: Rect2 = layout.play_rect()
	draw_rect(floor_rect, palette.quilt_patches[0])
	_draw_plaid(floor_rect)
	for point: Vector2 in layout.lamps:
		draw_circle(point, 260.0, palette.lamp_glow)
	for i: int in layout.cushions.size():
		var cushion: Rect2 = Rect2(layout.cushions[i] - Vector2(70, 50), Vector2(140, 100))
		TownArt.pillow(self, cushion, WorldPalette.pick(palette.cushions, i))
	for i: int in layout.block_piles.size():
		_draw_blocks(layout.block_piles[i], i)
	for point: Vector2 in layout.lamps:
		_draw_lamp(point)
	_draw_walls()


## Bands of the other quilt colours, crossing; a stitched seam runs along each band.
func _draw_plaid(floor_rect: Rect2) -> void:
	var index: int = 1
	var x: float = PLAID_STEP / 2.0
	while x < floor_rect.size.x:
		var band: Color = WorldPalette.pick(palette.quilt_patches, index)
		draw_rect(Rect2(x, 0.0, 60.0, floor_rect.size.y), Color(band, palette.pattern_alpha))
		draw_dashed_line(
			Vector2(x + 30.0, 0.0), Vector2(x + 30.0, floor_rect.size.y), palette.quilt_seam, 2.0
		)
		x += PLAID_STEP
		index += 1
	var y: float = PLAID_STEP / 2.0
	while y < floor_rect.size.y:
		var band: Color = WorldPalette.pick(palette.quilt_patches, index)
		draw_rect(Rect2(0.0, y, floor_rect.size.x, 60.0), Color(band, palette.pattern_alpha))
		draw_dashed_line(
			Vector2(0.0, y + 30.0), Vector2(floor_rect.size.x, y + 30.0), palette.quilt_seam, 2.0
		)
		y += PLAID_STEP
		index += 1


func _draw_blocks(at: Vector2, seed_index: int) -> void:
	for i: int in 3:
		var color: Color = WorldPalette.pick(palette.prop_blocks, i + seed_index)
		var corner: Vector2 = at + Vector2(-70.0 + 50.0 * i, 0.0 if i != 1 else -40.0)
		TownArt.pillow(self, Rect2(corner, Vector2(56, 56)), color)


func _draw_lamp(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-5, -40), Vector2(10, 70)), palette.lamp_pole)
	var shade: PackedVector2Array = [Vector2(-40, -40), Vector2(40, -40), Vector2(24, -90)]
	shade.append(Vector2(-24, -90))
	for i: int in shade.size():
		shade[i] += at
	FeltDraw.fill(self, shade, palette.lamp_shade)
	shade.append(shade[0])
	draw_polyline(shade, palette.ink, 2.0, true)


## Big pillows all around the quilt (the walls are separate physics bodies).
func _draw_walls() -> void:
	var outer: Rect2 = layout.outer_rect()
	var t: float = layout.wall_thickness
	var index: int = 0
	var x: float = outer.position.x
	while x < outer.end.x:
		var width: float = minf(WALL_PILLOW, outer.end.x - x)
		var color: Color = WorldPalette.pick(palette.pillow_walls, index)
		TownArt.pillow(self, Rect2(x, outer.position.y, width, t), color, false)
		TownArt.pillow(self, Rect2(x, layout.size.y, width, t), color, false)
		x += WALL_PILLOW
		index += 1
	var y: float = 0.0
	while y < layout.size.y:
		var height: float = minf(WALL_PILLOW, layout.size.y - y)
		var color: Color = WorldPalette.pick(palette.pillow_walls, index)
		TownArt.pillow(self, Rect2(-t, y, t, height), color, false)
		TownArt.pillow(self, Rect2(layout.size.x, y, t, height), color, false)
		y += WALL_PILLOW
		index += 1
