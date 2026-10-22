class_name TownRuin
extends Node2D
## A wrecked building spot (spec 03 §5): torn, knocked-over pillows and blocks in the building's
## footprint, with a sign. A ruin that can't be rebuilt yet is tangled in zombie yarn and its
## sign says what unlocks it. Rebuilding comes in M3-05.

const PIECE_COLORS: Array[Color] = [Color("#8d8799"), Color("#7b8aa0"), Color("#9a9184")]
const TORN_COLOR: Color = Color("#d9d3c8")
## Zombie yarn: a sickly grey-green (never red/orange, that's enemy danger).
const YARN_COLOR: Color = Color("#8ea283")
const YARN_DARK_COLOR: Color = Color("#6f8466")
const SIGN_POST_COLOR: Color = Color("#8a7660")
const HINT_COLOR: Color = Color("#b9c7b0")
const OPEN_COLOR: Color = Color("#cfe3f0")
const SIGN_WIDTH: float = 340.0

var spot: TownSpot
## False while tangled in yarn (not rebuildable yet).
var unlocked: bool = false
var name_label: Label
var status_label: Label


func _init(town_spot: TownSpot, is_unlocked: bool) -> void:
	spot = town_spot
	unlocked = is_unlocked
	name = String(spot.id)


func _ready() -> void:
	var rect: Rect2 = spot.rect
	name_label = TownArt.label(spot.display_name, 26)
	add_child(name_label)
	TownArt.center_label(name_label, rect.get_center().x, rect.end.y + 14.0, SIGN_WIDTH)
	status_label = TownArt.label(status_text(), 20)
	status_label.add_theme_color_override(&"font_color", OPEN_COLOR if unlocked else HINT_COLOR)
	add_child(status_label)
	TownArt.center_label(status_label, rect.get_center().x, rect.end.y + 48.0, SIGN_WIDTH)


## The sign's second line.
func status_text() -> String:
	return "Ruin: can be rebuilt" if unlocked else spot.unlock_hint()


func _draw() -> void:
	var rect: Rect2 = spot.rect
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(spot.id)
	for i: int in 6:
		var piece_size: Vector2 = Vector2(rng.randf_range(70, 130), rng.randf_range(50, 90))
		var at: Vector2 = Vector2(
			rng.randf_range(rect.position.x, rect.end.x - piece_size.x),
			rng.randf_range(rect.position.y, rect.end.y - piece_size.y)
		)
		draw_set_transform(at + piece_size / 2.0, rng.randf_range(-0.5, 0.5))
		var local: Rect2 = Rect2(-piece_size / 2.0, piece_size)
		TownArt.pillow(self, local, PIECE_COLORS[i % PIECE_COLORS.size()])
		draw_line(local.position + Vector2(10, 12), local.get_center(), TORN_COLOR, 4.0)
	draw_set_transform(Vector2.ZERO)
	_draw_yarn(rect, rng, 4 if unlocked else 12)
	_draw_sign_post(rect)


## Loose yarn scribbles; a locked ruin is wrapped in many more.
func _draw_yarn(rect: Rect2, rng: RandomNumberGenerator, strands: int) -> void:
	for i: int in strands:
		var from: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.position.y)
		var to: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.end.y)
		if i % 2 == 1:
			from = Vector2(rect.position.x, rng.randf_range(rect.position.y, rect.end.y))
			to = Vector2(rect.end.x, rng.randf_range(rect.position.y, rect.end.y))
		var color: Color = YARN_COLOR if i % 3 != 0 else YARN_DARK_COLOR
		var middle: Vector2 = (from + to) / 2.0 + Vector2(rng.randf_range(-40, 40), 0.0)
		draw_polyline(PackedVector2Array([from, middle, to]), color, 5.0, true)


func _draw_sign_post(rect: Rect2) -> void:
	var bottom: Vector2 = Vector2(rect.get_center().x, rect.end.y)
	draw_rect(Rect2(bottom + Vector2(-4, -16), Vector2(8, 26)), SIGN_POST_COLOR)
