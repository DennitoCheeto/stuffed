class_name TownFort
extends Node2D
## The fort in the middle of the Pillow Fort: pillow walls, two cushion towers, a blanket roof and
## the Bedroom door (walk up and press E to start a run). Its body blocks walking.

const WALL_COLOR: Color = Color("#e6dcc8")
const WALL_SHADE_COLOR: Color = Color("#cfc3ad")
const TOWER_COLOR: Color = Color("#8fb0cf")
const ROOF_COLOR: Color = Color("#6f8fb8")
const ROOF_FOLD_COLOR: Color = Color("#5f7ea6")
const DOOR_COLOR: Color = Color("#2a2336")
const DOOR_FRAME_COLOR: Color = Color("#c9b89a")
const KNOB_COLOR: Color = Color("#e3bd55")

var layout: TownLayout


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
