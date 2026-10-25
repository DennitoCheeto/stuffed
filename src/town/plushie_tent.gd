class_name PlushieTent
extends Node2D
## The little felt tent next to the Plush Hospital (spec 03 §7): rescued plushies sit in front
## of it until there is a free bed in the Hospital. Hidden while nobody waits. It doesn't block.

const CLOTH_COLOR: Color = Color("#d8cbe8")
const CLOTH_DARK: Color = Color("#a99cc8")
const DOOR_COLOR: Color = Color("#5c5476")
## A soft mint plus on the cloth (a first-aid tent, never the red of danger).
const PLUS_COLOR: Color = Color("#9fd8c0")
const POLE_COLOR: Color = Color("#8a7660")
const WIDTH: float = 150.0
const HEIGHT: float = 110.0
## Waiting plushies are drawn this much smaller than in town, side by side.
const PLUSHIE_SCALE: float = 0.8
const PLUSHIE_GAP: float = 64.0

var rules: PlushieTownRules
## The plushies waiting in front of the tent, first come first.
var waiting: Array[PlushieDef] = []
var sign_label: Label


func _init(town_rules: PlushieTownRules, at: Vector2) -> void:
	rules = town_rules
	position = at
	name = "PlushieTent"
	visible = false


func _ready() -> void:
	sign_label = TownArt.label(rules.waiting_text, 20)
	add_child(sign_label)
	TownArt.center_label(sign_label, 0.0, 44.0, 320.0)


func show_waiting(plushies: Array[PlushieDef]) -> void:
	waiting = plushies.duplicate()
	visible = not waiting.is_empty()
	queue_redraw()


func _draw() -> void:
	var left: Vector2 = Vector2(-WIDTH / 2.0, 0.0)
	var right: Vector2 = Vector2(WIDTH / 2.0, 0.0)
	var peak: Vector2 = Vector2(0.0, -HEIGHT)
	var shadow: PackedVector2Array = PlushieLook.ellipse(Vector2(0, 4), WIDTH * 0.6, 16.0)
	draw_colored_polygon(shadow, WorldPalette.current().shadow)
	draw_colored_polygon(PackedVector2Array([left, peak, right]), CLOTH_COLOR)
	draw_colored_polygon(PackedVector2Array([peak, right, right + Vector2(-30, 0)]), CLOTH_DARK)
	var door: PackedVector2Array = [Vector2(-26, 0), Vector2(0, -HEIGHT * 0.55), Vector2(26, 0)]
	draw_colored_polygon(door, DOOR_COLOR)
	var plus: Vector2 = Vector2(0.0, -HEIGHT * 0.75)
	draw_rect(Rect2(plus + Vector2(-10, -3), Vector2(20, 6)), PLUS_COLOR)
	draw_rect(Rect2(plus + Vector2(-3, -10), Vector2(6, 20)), PLUS_COLOR)
	draw_line(peak, peak + Vector2(0, -16), POLE_COLOR, 3.0)
	var first_x: float = -PLUSHIE_GAP * (waiting.size() - 1) / 2.0
	for i: int in waiting.size():
		var at: Vector2 = Vector2(first_x + PLUSHIE_GAP * i, 34.0)
		PlushieLook.draw(self, waiting[i], at, rules.size * PLUSHIE_SCALE)
