class_name EvolutionReveal
extends Control
## The sewing reveal on the gift box screen (spec 10 §3, AC-106): the weapon's icon and the item's
## icon slide together, a needle sews them up, they puff into the evolved weapon's icon and an
## "EVOLVED!" stamp slams on (about 1.5 s; the gift box screen skips it on any key).

enum Stage { APPROACH, STITCH, MERGE, STAMP, DONE }

## Where each stage ends, as a share of the reveal.
const APPROACH_END: float = 0.25
const STITCH_END: float = 0.62
const MERGE_END: float = 0.78
const ICON_SIZE: Vector2 = Vector2(150, 150)
const EVOLVED_SIZE: Vector2 = Vector2(190, 190)
const NEEDLE_COLOR: Color = Color("#d9d6e3")
const NEEDLE_EYE: Color = Color("#8d879c")
const STAMP_TILT: float = -8.0
const STAMP_START_SCALE: float = 2.2

var rules: EvolutionMomentRules
## Seconds since the reveal started.
var time: float = 0.0
var weapon_icon: UpgradeIcon = UpgradeIcon.new()
var item_icon: UpgradeIcon = UpgradeIcon.new()
var evolved_icon: UpgradeIcon = UpgradeIcon.new()
var stamp: Label


func _init(moment_rules: EvolutionMomentRules) -> void:
	rules = moment_rules
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(800, 360)
	for icon: UpgradeIcon in [weapon_icon, item_icon, evolved_icon]:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
	weapon_icon.size = ICON_SIZE
	item_icon.size = ICON_SIZE
	evolved_icon.size = EVOLVED_SIZE
	stamp = UiFonts.label(rules.stamp_text, 72, UiColors.STICKER_PINK, UiFonts.heading(800))
	stamp.add_theme_color_override(&"font_outline_color", UiColors.STICKER_PINK_INK)
	stamp.add_theme_constant_override(&"outline_size", 14)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp)


## Starts the reveal: `from` = the weapon's icon, `item` = the item's, `into` = the evolved one.
func start(from: StringName, item: StringName, into: StringName) -> void:
	weapon_icon.icon = from
	item_icon.icon = item
	evolved_icon.icon = into
	time = 0.0
	_layout()


func duration() -> float:
	return maxf(rules.reveal_seconds, 0.001)


func share() -> float:
	return clampf(time / duration(), 0.0, 1.0)


func is_done() -> bool:
	return time >= duration()


## Jumps to the end (evolved icon + stamp).
func finish() -> void:
	time = duration()
	_layout()


func stage() -> Stage:
	var s: float = share()
	if s >= 1.0:
		return Stage.DONE
	if s < APPROACH_END:
		return Stage.APPROACH
	if s < STITCH_END:
		return Stage.STITCH
	if s < MERGE_END:
		return Stage.MERGE
	return Stage.STAMP


func shows_stamp() -> bool:
	return stamp.visible and stamp.modulate.a > 0.5


func advance(delta: float) -> void:
	time += delta
	_layout()


func _layout() -> void:
	var middle: Vector2 = size / 2.0
	var s: float = share()
	var slide: float = _ease(clampf(s / APPROACH_END, 0.0, 1.0))
	var gap: float = lerpf(rules.icon_start_x, rules.icon_meet_x, slide)
	var merge: float = clampf((s - STITCH_END) / (MERGE_END - STITCH_END), 0.0, 1.0)
	var parts_scale: float = 1.0 - merge
	for pair: Array in [[weapon_icon, -1.0], [item_icon, 1.0]]:
		var icon: UpgradeIcon = pair[0]
		var side: float = pair[1]
		icon.pivot_offset = ICON_SIZE / 2.0
		icon.scale = Vector2.ONE * maxf(parts_scale, 0.001)
		icon.position = middle + Vector2(side * gap * (1.0 - merge), 0) - ICON_SIZE / 2.0
		icon.visible = parts_scale > 0.0
	var pop: float = 0.0 if merge <= 0.0 else _overshoot(merge)
	evolved_icon.pivot_offset = EVOLVED_SIZE / 2.0
	evolved_icon.scale = Vector2.ONE * maxf(pop, 0.001)
	evolved_icon.position = middle - EVOLVED_SIZE / 2.0
	evolved_icon.visible = merge > 0.0
	var slam: float = clampf((s - MERGE_END) / (1.0 - MERGE_END), 0.0, 1.0)
	stamp.visible = slam > 0.0
	stamp.size = Vector2(size.x, 100)
	stamp.position = Vector2(0, middle.y + EVOLVED_SIZE.y / 2.0 - 30.0)
	stamp.pivot_offset = stamp.size / 2.0
	stamp.rotation_degrees = STAMP_TILT
	stamp.scale = Vector2.ONE * lerpf(STAMP_START_SCALE, 1.0, _ease(slam))
	stamp.modulate.a = minf(slam * 3.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var s: float = share()
	if s < APPROACH_END or s >= MERGE_END:
		return
	var middle: Vector2 = size / 2.0
	var sew: float = clampf((s - APPROACH_END) / (STITCH_END - APPROACH_END), 0.0, 1.0)
	var count: int = maxi(rules.stitches, 1)
	var top: float = -ICON_SIZE.y * 0.35
	var height: float = ICON_SIZE.y * 0.7
	var reach: float = rules.icon_meet_x
	var points: PackedVector2Array = []
	var steps: float = sew * count * 2.0
	for i: int in int(steps) + 1:
		var y: float = top + height * minf(i / (count * 2.0), 1.0)
		points.append(middle + Vector2(reach if i % 2 == 0 else -reach, y))
	var needle_y: float = top + height * minf(steps / (count * 2.0), 1.0)
	# The needle runs from one side to the other on every stitch.
	var side: float = 1.0 if int(steps) % 2 == 0 else -1.0
	var needle_x: float = side * reach * (1.0 - 2.0 * fposmod(steps, 1.0))
	var needle: Vector2 = middle + Vector2(needle_x, needle_y)
	points.append(needle)
	if points.size() >= 2:
		draw_polyline(points, UiColors.STICKER_PINK, 5.0, true)
	var tip: Vector2 = needle + Vector2(-26, 26)
	draw_line(needle + Vector2(16, -16), tip, NEEDLE_COLOR, 6.0, true)
	draw_circle(needle + Vector2(13, -13), 3.0, NEEDLE_EYE)


static func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


## 0 → a bit past 1 → 1 (a little pop).
static func _overshoot(x: float) -> float:
	var c: float = 1.70158
	var t: float = x - 1.0
	return 1.0 + (c + 1.0) * t * t * t + c * t * t
