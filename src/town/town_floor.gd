class_name TownFloor
extends Node2D
## The Pillow Fort's ground: a big soft blanket with a plaid pattern, pillow walls around it and
## a few cozy props (cushions, block piles, lamps). Drawn once; nothing here blocks except walls.

const BLANKET_COLOR: Color = Color("#34405a")
const PLAID_COLOR: Color = Color(0.55, 0.65, 0.85, 0.08)
const PLAID_STITCH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.05)
const WALL_COLORS: Array[Color] = [Color("#7d7598"), Color("#6c86a0"), Color("#8a80a8")]
const CUSHION_COLORS: Array[Color] = [Color("#a99cc8"), Color("#8fb0cf"), Color("#c9bfa6")]
const BLOCK_COLORS: Array[Color] = [Color("#6f8fb8"), Color("#c9b98a"), Color("#7fa58a")]
const LAMP_GLOW_COLOR: Color = Color(1.0, 0.95, 0.75, 0.07)
const LAMP_SHADE_COLOR: Color = Color("#e8dcb8")
const LAMP_POLE_COLOR: Color = Color("#8a7f70")
const PLAID_STEP: float = 240.0
const WALL_PILLOW: float = 220.0

var layout: TownLayout


func _init(town_layout: TownLayout) -> void:
	layout = town_layout
	z_index = -10


func _draw() -> void:
	var floor_rect: Rect2 = layout.play_rect()
	draw_rect(floor_rect, BLANKET_COLOR)
	_draw_plaid(floor_rect)
	for point: Vector2 in layout.lamps:
		draw_circle(point, 260.0, LAMP_GLOW_COLOR)
	for i: int in layout.cushions.size():
		var cushion: Rect2 = Rect2(layout.cushions[i] - Vector2(70, 50), Vector2(140, 100))
		TownArt.pillow(self, cushion, CUSHION_COLORS[i % CUSHION_COLORS.size()])
	for i: int in layout.block_piles.size():
		_draw_blocks(layout.block_piles[i], i)
	for point: Vector2 in layout.lamps:
		_draw_lamp(point)
	_draw_walls()


func _draw_plaid(floor_rect: Rect2) -> void:
	var x: float = PLAID_STEP / 2.0
	while x < floor_rect.size.x:
		draw_rect(Rect2(x, 0.0, 60.0, floor_rect.size.y), PLAID_COLOR)
		draw_dashed_line(
			Vector2(x + 30.0, 0.0), Vector2(x + 30.0, floor_rect.size.y), PLAID_STITCH_COLOR, 2.0
		)
		x += PLAID_STEP
	var y: float = PLAID_STEP / 2.0
	while y < floor_rect.size.y:
		draw_rect(Rect2(0.0, y, floor_rect.size.x, 60.0), PLAID_COLOR)
		draw_dashed_line(
			Vector2(0.0, y + 30.0), Vector2(floor_rect.size.x, y + 30.0), PLAID_STITCH_COLOR, 2.0
		)
		y += PLAID_STEP


func _draw_blocks(at: Vector2, seed_index: int) -> void:
	for i: int in 3:
		var color: Color = BLOCK_COLORS[(i + seed_index) % BLOCK_COLORS.size()]
		var corner: Vector2 = at + Vector2(-70.0 + 50.0 * i, 0.0 if i != 1 else -40.0)
		TownArt.pillow(self, Rect2(corner, Vector2(56, 56)), color)


func _draw_lamp(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-5, -40), Vector2(10, 70)), LAMP_POLE_COLOR)
	var shade: PackedVector2Array = [Vector2(-40, -40), Vector2(40, -40), Vector2(24, -90)]
	shade.append(Vector2(-24, -90))
	for i: int in shade.size():
		shade[i] += at
	draw_colored_polygon(shade, LAMP_SHADE_COLOR)


## Big pillows all around the blanket (the walls are separate physics bodies).
func _draw_walls() -> void:
	var outer: Rect2 = layout.outer_rect()
	var t: float = layout.wall_thickness
	var index: int = 0
	var x: float = outer.position.x
	while x < outer.end.x:
		var width: float = minf(WALL_PILLOW, outer.end.x - x)
		var color: Color = WALL_COLORS[index % WALL_COLORS.size()]
		TownArt.pillow(self, Rect2(x, outer.position.y, width, t), color, false)
		TownArt.pillow(self, Rect2(x, layout.size.y, width, t), color, false)
		x += WALL_PILLOW
		index += 1
	var y: float = 0.0
	while y < layout.size.y:
		var height: float = minf(WALL_PILLOW, layout.size.y - y)
		var color: Color = WALL_COLORS[index % WALL_COLORS.size()]
		TownArt.pillow(self, Rect2(-t, y, t, height), color, false)
		TownArt.pillow(self, Rect2(layout.size.x, y, t, height), color, false)
		y += WALL_PILLOW
		index += 1
