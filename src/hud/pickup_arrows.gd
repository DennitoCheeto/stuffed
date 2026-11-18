class_name PickupArrows
extends Control
## Small arrows at the screen edge that point to floor pickups (spec 02b §4), the Way Home
## portal (spec 03 §4), a tangled plushie (spec 03 §7) and the Treasure Map box (spec 06 §3)
## when they are out of sight. With the Spyglass trick (spec 06 §3) they also point to elites
## and bosses off screen (bosses get a bigger arrow). In the night siege one points to the pillow
## fort for a moment after it was hit while it is off screen (spec 07 §7).

## An arrow pointed to an elite or boss this frame (Spyglass at work).
signal threat_pointed

## Arrows sit this far inside the screen edge, in pixels.
const MARGIN: float = 44.0
## Arrow length and half width, in pixels.
const LENGTH: float = 22.0
const HALF_WIDTH: float = 13.0
const OUTLINE_COLOR: Color = Color("#1d3a52")
## The arrow nudges towards its pickup this far and back, in pixels.
const NUDGE: float = 4.0
const NUDGE_SPEED: float = 1.5
## Spyglass arrows: a soft pink (never the enemies' danger red/orange, AC-73) ...
const THREAT_COLOR: Color = Color("#f59bff")
## ... and a boss's arrow is this much bigger.
const BOSS_SCALE: float = 1.5
## The fort arrow: the fort bar's teal (the player's side, never a danger colour), a bit bigger.
const FORT_COLOR: Color = FortHealthBar.FILL_COLOR
const FORT_SCALE: float = 1.4

## Where the pickups lie (the run's floor items).
var floor_items: Node2D
## Spyglass: the zombies to point at (null = no Spyglass).
var threats: EnemyManager
## Night siege: the fort to point at while it is under attack (null = not a siege).
var fort: SiegeTarget
## Seconds the fort arrow still shows after the last hit (0 = not under attack).
var fort_alarm: float = 0.0
## Each arrow's tip (screen pixels), the direction it points, its colour (the portal's is soft
## blue) and its size (1 = normal), rebuilt every frame.
var points: PackedVector2Array = []
var directions: PackedVector2Array = []
var colors: PackedColorArray = []
var sizes: PackedFloat32Array = []

var _time: float = 0.0
var _fort_alarm_seconds: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	points.clear()
	directions.clear()
	colors.clear()
	sizes.clear()
	if floor_items == null:
		return
	var view: Rect2 = get_viewport_rect()
	var to_screen: Transform2D = get_viewport().get_canvas_transform()
	for child: Node in floor_items.get_children():
		var color: Color = _arrow_color(child)
		if color.a > 0.0:
			_point_at(to_screen * (child as Node2D).global_position, view, color, 1.0)
	if threats != null:
		_point_at_threats(view, to_screen)
	fort_alarm = maxf(fort_alarm - delta, 0.0)
	if fort != null and fort_alarm > 0.0:
		_point_at_fort(view, to_screen)
	queue_redraw()


## Night siege: point to the fort whenever it is hit, for `seconds` after each hit.
func watch_fort(target: SiegeTarget, seconds: float) -> void:
	fort = target
	_fort_alarm_seconds = seconds
	fort.health_changed.connect(_on_fort_health_changed)


func _on_fort_health_changed(health: float, max_health: float) -> void:
	if health < max_health and not fort.is_fallen():
		fort_alarm = _fort_alarm_seconds


## The fort arrow, only while no part of the fort is on screen.
func _point_at_fort(view: Rect2, to_screen: Transform2D) -> void:
	var on_screen: Rect2 = to_screen * fort.rect
	if not view.intersects(on_screen):
		_point_at(on_screen.get_center(), view, FORT_COLOR, FORT_SCALE)


## Spyglass: an arrow for every living elite and boss off screen.
func _point_at_threats(view: Rect2, to_screen: Transform2D) -> void:
	var pointed: bool = false
	for zombie: Zombie in threats.zombies:
		if zombie.dead or not (zombie.is_elite() or zombie.is_boss()):
			continue
		var grow_by: float = BOSS_SCALE if zombie.is_boss() else 1.0
		if _point_at(to_screen * zombie.global_position, view, THREAT_COLOR, grow_by):
			pointed = true
	if pointed:
		threat_pointed.emit()


## Adds an arrow to `at` (screen pixels) if it is off screen. Returns true if it did.
func _point_at(at: Vector2, view: Rect2, color: Color, grow_by: float) -> bool:
	if view.has_point(at):
		return false
	var direction: Vector2 = view.get_center().direction_to(at)
	points.append(_edge_point(view.grow(-MARGIN), direction))
	directions.append(direction)
	colors.append(color)
	sizes.append(grow_by)
	return true


## The arrow colour for a floor item, or a clear colour if it gets no arrow.
func _arrow_color(item: Node) -> Color:
	if item.is_queued_for_deletion():
		return Color.TRANSPARENT
	var pickup: FloorPickup = item as FloorPickup
	if pickup != null and not pickup.taken:
		return FloorPickupLook.GLOW_COLOR
	var portal: WayHomePortal = item as WayHomePortal
	if portal != null and not portal.used:
		return WayHomePortal.GLOW_COLOR
	var plushie: TangledPlushie = item as TangledPlushie
	if plushie != null and not plushie.used:
		return TangledPlushie.GLOW_COLOR
	var box: GiftBox = item as GiftBox
	if box != null and box.treasure and not box.opened:
		return GiftBoxLook.GLOW_COLOR
	return Color.TRANSPARENT


## Where a line from the middle of `area` in `direction` leaves it.
func _edge_point(area: Rect2, direction: Vector2) -> Vector2:
	var half: Vector2 = area.size / 2.0
	var reach: float = INF
	if absf(direction.x) > 0.001:
		reach = minf(reach, half.x / absf(direction.x))
	if absf(direction.y) > 0.001:
		reach = minf(reach, half.y / absf(direction.y))
	return area.get_center() + direction * reach


func _draw() -> void:
	var nudge: float = NUDGE * (0.5 + 0.5 * sin(_time * TAU * NUDGE_SPEED))
	for i: int in points.size():
		var forward: Vector2 = directions[i]
		var side: Vector2 = forward.orthogonal() * HALF_WIDTH * sizes[i]
		var tip: Vector2 = points[i] + forward * nudge
		var back: Vector2 = tip - forward * LENGTH * sizes[i]
		var shape: PackedVector2Array = [tip, back + side, back - side]
		draw_colored_polygon(shape, colors[i])
		shape.append(tip)
		draw_polyline(shape, OUTLINE_COLOR, 3.0, true)
