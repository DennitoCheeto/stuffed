class_name TownFort
extends Node2D
## The fort in the middle of the Pillow Fort: pillow walls, two cushion towers, a blanket roof and
## the Bedroom door (walk up and press E to start a run). Its body blocks walking. The fort grows
## with the town (spec 03 §5): a new piece after every few rebuilds/upgrades.

const WALL_COLOR: Color = Color("#e6dcc8")
const WALL_SHADE_COLOR: Color = Color("#cfc3ad")
const TOWER_COLOR: Color = Color("#8fb0cf")
const ROOF_COLOR: Color = Color("#6f8fb8")
const ROOF_FOLD_COLOR: Color = Color("#5f7ea6")
const DOOR_COLOR: Color = Color("#2a2336")
const DOOR_FRAME_COLOR: Color = Color("#c9b89a")
const KNOB_COLOR: Color = Color("#e3bd55")
## The pieces the fort gets as the town grows, in order.
const PIECES: PackedStringArray = [
	"flag", "string_lights", "second_tower", "bunting", "window_boxes", "big_banner"
]
const FLAG_COLOR: Color = Color("#a9dccf")
const POLE_COLOR: Color = Color("#8a7660")
const LIGHT_COLORS: Array[Color] = [Color("#f6e7b0"), Color("#cdb8ec"), Color("#a9dccf")]
const BUNTING_COLORS: Array[Color] = [Color("#cdb8ec"), Color("#f6e7b0"), Color("#8fb0cf")]
const FLOWER_COLORS: Array[Color] = [Color("#cdb8ec"), Color("#f6e7b0"), Color("#e7b3cf")]
const BOX_COLOR: Color = Color("#9a8a74")

var layout: TownLayout
## How many of PIECES the fort shows.
var pieces: int = 0:
	set(value):
		pieces = clampi(value, 0, PIECES.size())
		queue_redraw()


func _init(town_layout: TownLayout) -> void:
	layout = town_layout


func _draw() -> void:
	var fort: Rect2 = layout.fort_rect
	var wall_top: Vector2 = fort.position + Vector2(0, fort.size.y * 0.3)
	var wall: Rect2 = Rect2(wall_top, fort.size * Vector2(1, 0.7))
	TownArt.pillow(self, wall, WALL_COLOR)
	var cushion: Vector2 = Vector2(fort.size.x / 2.0 - 30.0, 70.0)
	TownArt.pillow(self, Rect2(wall_top + Vector2(20, 20), cushion), WALL_SHADE_COLOR, false)
	var right_cushion: Vector2 = wall_top + Vector2(fort.size.x / 2.0 + 10.0, 20.0)
	TownArt.pillow(self, Rect2(right_cushion, cushion), WALL_SHADE_COLOR, false)
	_draw_roof(fort)
	var tower_size: Vector2 = Vector2(90, fort.size.y * 0.95)
	var tower_y: float = fort.position.y + fort.size.y * 0.05
	TownArt.pillow(self, Rect2(Vector2(fort.position.x - 30, tower_y), tower_size), TOWER_COLOR)
	var right_x: float = fort.end.x - tower_size.x + 30
	TownArt.pillow(self, Rect2(Vector2(right_x, tower_y), tower_size), TOWER_COLOR)
	_draw_door(layout.door_rect)
	for i: int in pieces:
		_draw_piece(PIECES[i], fort)


func _draw_roof(fort: Rect2) -> void:
	var top: float = fort.position.y - 40.0
	var eave: float = fort.position.y + fort.size.y * 0.36
	var roof: PackedVector2Array = [Vector2(fort.position.x + 20, eave)]
	roof.append(Vector2(fort.get_center().x, top))
	roof.append(Vector2(fort.end.x - 20, eave))
	draw_colored_polygon(roof, ROOF_COLOR)
	for i: int in range(1, 4):
		var x: float = fort.position.x + fort.size.x * i / 4.0
		draw_line(Vector2(fort.get_center().x, top + 20), Vector2(x, eave), ROOF_FOLD_COLOR, 6.0)


func _draw_door(door: Rect2) -> void:
	var frame: Rect2 = door.grow(10.0)
	frame.size.y -= 10.0
	TownArt.pillow(self, frame, DOOR_FRAME_COLOR, false)
	var opening: StyleBoxFlat = StyleBoxFlat.new()
	opening.bg_color = DOOR_COLOR
	opening.corner_radius_top_left = roundi(door.size.x / 2.0)
	opening.corner_radius_top_right = roundi(door.size.x / 2.0)
	draw_style_box(opening, door)
	draw_circle(door.position + Vector2(door.size.x * 0.75, door.size.y * 0.6), 6.0, KNOB_COLOR)


## How many pieces the fort has after `total_levels` rebuilds/upgrades (one per `every`).
static func pieces_for(total_levels: int, every: int) -> int:
	return clampi(floori(float(total_levels) / maxi(every, 1)), 0, PIECES.size())


func has_piece(piece: String) -> bool:
	var index: int = PIECES.find(piece)
	return index >= 0 and index < pieces


func _draw_piece(piece: String, fort: Rect2) -> void:
	var left_tower: Vector2 = Vector2(fort.position.x + 15.0, fort.position.y + fort.size.y * 0.05)
	var right_tower: Vector2 = Vector2(fort.end.x - 15.0, left_tower.y)
	match piece:
		"flag":
			_draw_flag(Vector2(fort.get_center().x, fort.position.y - 40.0), 60.0, FLAG_COLOR)
		"string_lights":
			_draw_garland(fort, fort.position.y + fort.size.y * 0.36 + 6.0, LIGHT_COLORS, false)
		"second_tower":
			var turret: Rect2 = Rect2(left_tower + Vector2(-40.0, -70.0), Vector2(80.0, 80.0))
			TownArt.pillow(self, turret, TOWER_COLOR.lightened(0.15))
			var cap: PackedVector2Array = [
				turret.position + Vector2(-8, 10),
				turret.position + Vector2(40, -40),
				turret.position + Vector2(88, 10)
			]
			draw_colored_polygon(cap, ROOF_COLOR)
		"bunting":
			_draw_garland(fort, fort.position.y + fort.size.y * 0.55, BUNTING_COLORS, true)
		"window_boxes":
			for x: float in [fort.position.x + 60.0, fort.end.x - 130.0]:
				var box: Rect2 = Rect2(Vector2(x, fort.end.y - 60.0), Vector2(70.0, 18.0))
				draw_rect(box, BOX_COLOR)
				for k: int in 4:
					var at: Vector2 = box.position + Vector2(10.0 + k * 17.0, -4.0)
					draw_circle(at, 8.0, FLOWER_COLORS[k % FLOWER_COLORS.size()])
		_:
			_draw_flag(right_tower + Vector2(0.0, -10.0), 80.0, BUNTING_COLORS[0])


func _draw_flag(base: Vector2, height: float, color: Color) -> void:
	var top: Vector2 = base - Vector2(0.0, height)
	draw_line(base, top, POLE_COLOR, 5.0)
	var cloth: PackedVector2Array = [top, top + Vector2(50.0, 14.0), top + Vector2(0.0, 30.0)]
	draw_colored_polygon(cloth, color)
	draw_circle(top, 5.0, KNOB_COLOR)


## A sagging string across the fort's front with lights (dots) or little felt pennants.
func _draw_garland(fort: Rect2, y: float, colors: Array[Color], pennants: bool) -> void:
	var points: PackedVector2Array = []
	for i: int in 13:
		var t: float = i / 12.0
		var x: float = lerpf(fort.position.x - 10.0, fort.end.x + 10.0, t)
		points.append(Vector2(x, y + 18.0 * sin(t * PI)))
	draw_polyline(points, POLE_COLOR, 2.0, true)
	for i: int in points.size():
		var color: Color = colors[i % colors.size()]
		if pennants:
			var at: Vector2 = points[i]
			var flag: PackedVector2Array = [
				at + Vector2(-9, 0), at + Vector2(9, 0), at + Vector2(0, 20)
			]
			draw_colored_polygon(flag, color)
		else:
			draw_circle(points[i] + Vector2(0, 5), 6.0, color)
