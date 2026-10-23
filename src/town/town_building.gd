class_name TownBuilding
extends Node2D
## One building spot in the Pillow Fort (spec 03 §5, §6, §11). At level 0 it's a wrecked ruin:
## torn, knocked-over pillows in the building's footprint. A ruin that can't be rebuilt yet is
## tangled in zombie yarn and its sign says what unlocks it. Rebuilt (level 1-3) it's a cozy
## felt building that gets bigger and fancier per level. The sign below shows the name, the price
## of the next level (grey when the jars don't hold enough) and what it does.

const PIECE_COLORS: Array[Color] = [Color("#8d8799"), Color("#7b8aa0"), Color("#9a9184")]
const TORN_COLOR: Color = Color("#d9d3c8")
## Zombie yarn: a sickly grey-green (never red/orange, that's enemy danger).
const YARN_COLOR: Color = Color("#8ea283")
const YARN_DARK_COLOR: Color = Color("#6f8466")
const SIGN_POST_COLOR: Color = Color("#8a7660")
const HINT_COLOR: Color = Color("#b9c7b0")
const OPEN_COLOR: Color = Color("#cfe3f0")
## A price the jars can't pay yet.
const SHORT_TINT: Color = Color(0.55, 0.55, 0.6, 0.75)
const SIGN_WIDTH: float = 360.0
## Loose yarn on every ruin; a locked one has this many more strands wrapped round it.
const LOOSE_STRANDS: int = 4
const TANGLE_STRANDS: int = 8
## The rebuild moment: the ruin shakes (matches the "rebuild" sound's rustle), then pops up.
const SHAKE_SECONDS: float = 0.32
const SHAKE_PIXELS: float = 6.0
const POP_SECONDS: float = 0.4
## How long the yarn takes to fall off when the ruin becomes rebuildable.
const YARN_FALL_SECONDS: float = 0.9
const YARN_FALL_PIXELS: float = 70.0

var spot: TownSpot
var building: BuildingDef
## The building's level (0 = ruin). Changes the moment it's paid for.
var level: int = 0
## The level the drawing shows: it catches up with `level` when the ruin pops up.
var shown_level: int = 0
## False while tangled in yarn (not rebuildable yet).
var unlocked: bool = false
var name_label: Label
var status_label: Label
## The next level's price, one counter per material.
var cost_row: HBoxContainer
var cost_counters: Dictionary[String, JarCounter] = {}

var _shake_left: float = 0.0
## 0..1 while popping up, 1 when still.
var _pop: float = 1.0
var _pop_from: float = 1.0
## 0..1 while the yarn falls off, 1 when done.
var _yarn_fall: float = 1.0


func _init(town_spot: TownSpot, start_level: int, is_unlocked: bool) -> void:
	spot = town_spot
	building = spot.building
	level = start_level
	shown_level = start_level
	unlocked = is_unlocked or start_level > 0
	name = String(spot.id)


func _ready() -> void:
	var rect: Rect2 = spot.rect
	name_label = TownArt.label("", 26)
	add_child(name_label)
	TownArt.center_label(name_label, rect.get_center().x, rect.end.y + 14.0, SIGN_WIDTH)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.position = Vector2(rect.get_center().x - SIGN_WIDTH / 2.0, rect.end.y + 50.0)
	center.size = Vector2(SIGN_WIDTH, 30.0)
	add_child(center)
	cost_row = HBoxContainer.new()
	cost_row.add_theme_constant_override(&"separation", 18)
	center.add_child(cost_row)
	status_label = TownArt.label("", 20)
	add_child(status_label)
	TownArt.center_label(status_label, rect.get_center().x, rect.end.y + 84.0, SIGN_WIDTH)


## Updates the sign for the town's jars right now.
func refresh(save: TownSave) -> void:
	var title: String = building.display_name
	if level > 0:
		title += "   Lv %d" % level
	name_label.text = title
	status_label.text = status_text()
	status_label.add_theme_color_override(&"font_color", OPEN_COLOR if unlocked else HINT_COLOR)
	for counter: JarCounter in cost_counters.values():
		counter.queue_free()
	cost_counters.clear()
	var next: BuildingLevel = building.next(level)
	cost_row.visible = unlocked and next != null
	if next == null:
		return
	var cost: Dictionary[String, int] = next.cost()
	for material: String in cost:
		var counter: JarCounter = JarCounter.new(material, 20, 26.0)
		counter.show_amount(cost[material])
		if save.material(material) < cost[material]:
			counter.modulate = SHORT_TINT
		cost_row.add_child(counter)
		cost_counters[material] = counter


## The sign's last line: what unlocks it, what it does, or what it does now.
func status_text() -> String:
	if not unlocked:
		return spot.unlock_hint()
	if level == 0:
		return building.summary
	return building.effect_at(level)


## True when the price on the sign is shown grey (the jars hold too little of `material`).
func is_short_of(material: String) -> bool:
	return cost_counters.has(material) and cost_counters[material].modulate == SHORT_TINT


## The rebuild/upgrade moment for the level that was just paid for.
func play_build(new_level: int) -> void:
	var was_ruin: bool = level == 0
	level = new_level
	unlocked = true
	if was_ruin:
		_shake_left = SHAKE_SECONDS
		Sfx.play(&"rebuild")
	else:
		_pop_up(0.9, 0.55)
		Sfx.play(&"upgrade")


## The yarn falls off: the ruin can be rebuilt now ("New building!").
func reveal() -> void:
	unlocked = true
	_yarn_fall = 0.0
	queue_redraw()


## True while the rebuild moment or the yarn falling is still playing.
func is_busy() -> bool:
	return _shake_left > 0.0 or _pop < 1.0


func is_yarn_falling() -> bool:
	return _yarn_fall < 1.0


func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		if _shake_left <= 0.0:
			_shake_left = 0.0
			_pop_up(0.55, 1.0)
		queue_redraw()
	elif _pop < 1.0:
		_pop = minf(_pop + delta / POP_SECONDS, 1.0)
		queue_redraw()
	if _yarn_fall < 1.0:
		_yarn_fall = minf(_yarn_fall + delta / YARN_FALL_SECONDS, 1.0)
		queue_redraw()


## Shows the new level, growing from `from` times its size, with a puff of `puff_size`.
func _pop_up(from: float, puff_size: float) -> void:
	shown_level = level
	_pop_from = from
	_pop = 0.0
	add_child(TownPuff.new(spot.rect, puff_size))
	queue_redraw()


## The building's size while popping up: a bit too big, then settling (an "ease out back").
func pop_scale() -> float:
	var t: float = _pop - 1.0
	var settle: float = 1.0 + 2.70158 * t * t * t + 1.70158 * t * t
	return lerpf(_pop_from, 1.0, settle)


func _draw() -> void:
	var shake: Vector2 = Vector2.ZERO
	if _shake_left > 0.0:
		shake = Vector2(sin(_shake_left * 90.0), cos(_shake_left * 70.0)) * SHAKE_PIXELS
	draw_set_transform(shake)
	if shown_level > 0:
		BuildingArt.draw(self, building, spot.rect, shown_level, pop_scale())
	else:
		_draw_ruin(spot.rect)
	draw_set_transform(Vector2.ZERO)
	_draw_sign_post(spot.rect)


func _draw_ruin(rect: Rect2) -> void:
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
	_draw_yarn(rect, rng, 0, LOOSE_STRANDS, Vector2.ZERO, 1.0)
	if not unlocked or is_yarn_falling():
		var fall: float = _yarn_fall if unlocked else 0.0
		var drop: Vector2 = Vector2(0.0, YARN_FALL_PIXELS * fall * fall)
		_draw_yarn(rect, rng, LOOSE_STRANDS, TANGLE_STRANDS, drop, 1.0 - fall)


## Yarn scribbles across the ruin, moved by `drop` and faded to `alpha` (falling off).
func _draw_yarn(
	rect: Rect2, rng: RandomNumberGenerator, first: int, strands: int, drop: Vector2, alpha: float
) -> void:
	for i: int in range(first, first + strands):
		var from: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.position.y)
		var to: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.end.y)
		if i % 2 == 1:
			from = Vector2(rect.position.x, rng.randf_range(rect.position.y, rect.end.y))
			to = Vector2(rect.end.x, rng.randf_range(rect.position.y, rect.end.y))
		var color: Color = YARN_COLOR if i % 3 != 0 else YARN_DARK_COLOR
		var middle: Vector2 = (from + to) / 2.0 + Vector2(rng.randf_range(-40, 40), 0.0)
		var line: PackedVector2Array = [from + drop, middle + drop, to + drop]
		draw_polyline(line, Color(color, alpha), 5.0, true)


func _draw_sign_post(rect: Rect2) -> void:
	var bottom: Vector2 = Vector2(rect.get_center().x, rect.end.y)
	draw_rect(Rect2(bottom + Vector2(-4, -16), Vector2(8, 26)), SIGN_POST_COLOR)
