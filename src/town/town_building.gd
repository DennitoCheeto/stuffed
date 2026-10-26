class_name TownBuilding
extends Node2D
## One building spot in the Pillow Fort (spec 03 §5, §6, §11). At level 0 it's a wrecked ruin.
## Each building is drawn with the art kit (`BuildingLooks`, spec 05 §2.2): its own object broken
## or tipped over at level 0, growing with every level. A ruin that can't be rebuilt yet is
## tangled in zombie yarn. Less text, more town (spec 05 §3.3): names and effects only show on
## the info card when a player walks up. An open ruin keeps a small price tag (jar icons, grey
## when the jars don't hold enough) and a golden "Can build!" tag floats over any building whose
## next level the jars can pay right now.

## Zombie yarn: a sickly grey-green (never red/orange, that's enemy danger).
const YARN_COLOR: Color = Color("#8ea283")
const YARN_DARK_COLOR: Color = Color("#6f8466")
## A price the jars can't pay yet.
const SHORT_TINT: Color = Color(0.55, 0.55, 0.6, 0.75)
## The price tag hangs this far below a ruin's spot.
const TAG_GAP: float = 14.0
## The "Can build!" tag floats this far above the top of the drawing and bobs up and down.
const CAN_BUILD_GAP: float = 26.0
const CAN_BUILD_BOB_PIXELS: float = 5.0
const CAN_BUILD_BOB_SPEED: float = 3.2
const CAN_BUILD_TEXT: String = "Can build!"
const CAN_BUILD_FONT_SIZE: int = 22
## How many yarn strands wrap a locked ruin.
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
## The small tag under an open ruin with the next level's price.
var price_tag: PanelContainer = PanelContainer.new()
## The next level's price, one counter per material.
var cost_row: HBoxContainer = HBoxContainer.new()
var cost_counters: Dictionary[String, JarCounter] = {}
## Floats over the building while the jars can pay for its next level.
var can_build_tag: FabricTag = FabricTag.new(
	CAN_BUILD_TEXT, UiColors.GOLD, UiColors.GOLD_INK, CAN_BUILD_FONT_SIZE
)
## True when the jars could pay for the next level at the last refresh.
var affordable: bool = false
## True while the info card shows this building (the card says it all, the tag steps aside).
var card_shown: bool = false

var _shake_left: float = 0.0
## 0..1 while popping up, 1 when still.
var _pop: float = 1.0
var _pop_from: float = 1.0
## 0..1 while the yarn falls off, 1 when done.
var _yarn_fall: float = 1.0
var _bob_time: float = 0.0
## The top of the drawing (above its bottom middle) for the level in `_top_level`, cached.
var _look_top: float = 0.0
var _top_level: int = -1


func _init(town_spot: TownSpot, start_level: int, is_unlocked: bool) -> void:
	spot = town_spot
	building = spot.building
	level = start_level
	shown_level = start_level
	unlocked = is_unlocked or start_level > 0
	name = String(spot.id)


func _ready() -> void:
	material = WorldPalette.current().grain_material()
	var box: StyleBoxFelt = StyleBoxFelt.new(UiColors.TAG, UiColors.TAG.darkened(0.28))
	box.radius = 8.0
	box.stitch_inset = 3.0
	box.stitch_width = 1.5
	box.stitch_dash = 4.0
	box.stitch_gap = 3.0
	box.pad(12, 4)
	price_tag.add_theme_stylebox_override(&"panel", box)
	price_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_tag.visible = false
	add_child(price_tag)
	cost_row.add_theme_constant_override(&"separation", 14)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_tag.add_child(cost_row)
	can_build_tag.visible = false
	add_child(can_build_tag)


## Updates the price tag and the "Can build!" tag for the town's jars right now.
func refresh(save: TownSave) -> void:
	for counter: JarCounter in cost_counters.values():
		cost_row.remove_child(counter)
		counter.queue_free()
	cost_counters.clear()
	var next: BuildingLevel = building.next(level)
	affordable = unlocked and next != null and save.can_afford(next.cost())
	price_tag.visible = unlocked and level == 0 and next != null
	_update_can_build()
	if not price_tag.visible:
		return
	var cost: Dictionary[String, int] = next.cost()
	for material: String in cost:
		var counter: JarCounter = JarCounter.new(material, 20, 26.0).on_felt()
		counter.show_amount(cost[material])
		if save.material(material) < cost[material]:
			counter.modulate = SHORT_TINT
		cost_row.add_child(counter)
		cost_counters[material] = counter
	price_tag.reset_size()
	var rect: Rect2 = spot.rect
	var left: float = rect.get_center().x - price_tag.size.x / 2.0
	price_tag.position = Vector2(left, rect.end.y + TAG_GAP)


## True while the golden "Can build!" tag floats over the building.
func shows_can_build() -> bool:
	return can_build_tag.visible


## Every piece of text the building shows on its own (without a player next to it).
func shown_texts() -> PackedStringArray:
	var result: PackedStringArray = []
	for label: Label in find_children("*", "Label", true, false):
		if label.is_visible_in_tree() and not label.text.is_empty():
			result.append(label.text)
	return result


## The art-kit look the building shows right now.
func shown_look() -> BuildingSketch:
	return BuildingLooks.sketch(building, shown_level)


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
	_update_can_build()
	if can_build_tag.visible:
		_bob_time += delta
		_place_can_build()
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


## The tag shows while the jars can pay, but not during the build moment or under the card.
func _update_can_build() -> void:
	var wanted: bool = affordable and not is_busy() and not card_shown
	if wanted and not can_build_tag.visible:
		can_build_tag.reset_size()
		_place_can_build()
	can_build_tag.visible = wanted


## Over the top of the drawing, bobbing gently.
func _place_can_build() -> void:
	if _top_level != shown_level:
		_top_level = shown_level
		_look_top = shown_look().bounds().position.y
	var bottom: Vector2 = Vector2(spot.rect.get_center().x, spot.rect.end.y)
	var top: float = bottom.y + _look_top - CAN_BUILD_GAP
	var bob: float = sin(_bob_time * CAN_BUILD_BOB_SPEED) * CAN_BUILD_BOB_PIXELS
	var tag_size: Vector2 = can_build_tag.size
	can_build_tag.position = Vector2(bottom.x - tag_size.x / 2.0, top - tag_size.y + bob)


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
	var bottom: Vector2 = Vector2(spot.rect.get_center().x, spot.rect.end.y)
	draw_set_transform(bottom + shake, 0.0, Vector2.ONE * pop_scale())
	shown_look().draw(self)
	draw_set_transform(shake)
	if shown_level == 0:
		_draw_ruin_yarn(spot.rect)
	draw_set_transform(Vector2.ZERO)


## The zombie-yarn tangle while the ruin is locked (falling off when it unlocks).
func _draw_ruin_yarn(rect: Rect2) -> void:
	if unlocked and not is_yarn_falling():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(spot.id) + 1
	var fall: float = _yarn_fall if unlocked else 0.0
	var drop: Vector2 = Vector2(0.0, YARN_FALL_PIXELS * fall * fall)
	var alpha: float = 1.0 - fall
	for i: int in TANGLE_STRANDS:
		var from: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.position.y)
		var to: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rect.end.y)
		if i % 2 == 1:
			from = Vector2(rect.position.x, rng.randf_range(rect.position.y, rect.end.y))
			to = Vector2(rect.end.x, rng.randf_range(rect.position.y, rect.end.y))
		var color: Color = YARN_COLOR if i % 3 != 0 else YARN_DARK_COLOR
		var middle: Vector2 = (from + to) / 2.0 + Vector2(rng.randf_range(-40, 40), 0.0)
		var line: PackedVector2Array = [from + drop, middle + drop, to + drop]
		draw_polyline(line, Color(color, alpha), 5.0, true)
