class_name ShinySparkle
extends Control
## The gold sparkle on a shiny level-up card (Shiny Card trick, spec 06 §3.1): small four-point
## stars along the card's edge that twinkle one after another. It fills its parent and never
## takes the mouse. Gold and dark gold only (never the red/orange of enemy danger, AC-73).

## Where the stars sit, as shares of the card's size (inside the edge, clear of the tags).
const SPOTS: Array[Vector2] = [
	Vector2(0.08, 0.2),
	Vector2(0.93, 0.3),
	Vector2(0.06, 0.62),
	Vector2(0.94, 0.7),
	Vector2(0.5, 0.05),
	Vector2(0.2, 0.93),
	Vector2(0.8, 0.94),
]
## Star size (px from the middle to a tip) and how fast they twinkle (per second).
const STAR_SIZE: float = 18.0
const TWINKLE_SPEED: float = 3.2
const COLORS: Array[Color] = [UiColors.GOLD, UiColors.GOLD_EDGE]

var time: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## How big star `index` is right now (0..1).
func twinkle(index: int) -> float:
	return 0.35 + 0.65 * absf(sin(time * TWINKLE_SPEED + index * 1.3))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	for index: int in SPOTS.size():
		var spot: Vector2 = SPOTS[index]
		var center: Vector2 = Vector2(spot.x * size.x, spot.y * size.y)
		_star(center, STAR_SIZE * twinkle(index), COLORS[index % COLORS.size()])


## A four-point star: long tips up/down/left/right, a narrow waist between them.
func _star(center: Vector2, tip: float, color: Color) -> void:
	var points: PackedVector2Array = []
	for step: int in 8:
		var angle: float = step * PI / 4.0 - PI / 2.0
		var reach: float = tip if step % 2 == 0 else tip * 0.28
		points.append(center + Vector2.from_angle(angle) * reach)
	FeltDraw.fill(self, points, color)
