class_name BuildingHealthBar
extends Node2D
## A small health bar over a building in the night siege (spec 07 §4): it shows only while the
## building is hurt and still standing. A dark felt backing with a soft teal fill (the player's
## side, never a danger colour) that turns gold when the building is nearly down. Drawn plain
## (two rects on one shared layer), so all bars together cost about one draw call.

const SIZE: Vector2 = Vector2(120.0, 14.0)
## Floats this far above the top of the building's drawing.
const GAP: float = 16.0
const BORDER: float = 3.0
## Below this share the fill turns gold (a warning).
const LOW_SHARE: float = 0.3
const BACK_COLOR: Color = UiColors.HUD_FELT
const FILL_COLOR: Color = UiColors.STICKER_TEAL
const LOW_COLOR: Color = UiColors.GOLD
## Above the town and the zombies, under the enemy bullets (danger stays on top). All bars share
## this layer, so they are drawn together in one batch (spec 07 §11).
const Z: int = ProjectileManager.HOSTILE_Z - 1

var target: SiegeTarget


## A bar for `siege_target` with its middle bottom at `at` (town pixels).
func _init(siege_target: SiegeTarget, at: Vector2) -> void:
	name = "HealthBar"
	target = siege_target
	position = at - Vector2(0.0, GAP + SIZE.y / 2.0)
	z_index = Z
	visible = false
	target.health_changed.connect(_on_health_changed)


func fill_color() -> Color:
	return LOW_COLOR if target.share() < LOW_SHARE else FILL_COLOR


func _on_health_changed(_health: float, _max_health: float) -> void:
	visible = target.is_hurt()
	queue_redraw()


func _draw() -> void:
	var back: Rect2 = Rect2(-SIZE / 2.0, SIZE)
	draw_rect(back, BACK_COLOR)
	var inner: Rect2 = back.grow(-BORDER)
	inner.size.x *= clampf(target.share(), 0.0, 1.0)
	if inner.size.x >= 1.0:
		draw_rect(inner, fill_color())
