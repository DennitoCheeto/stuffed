class_name ScrapbookPicture
extends Control
## The felt picture of one Scrapbook entry: its card icon, zombie puppet, floor pickup or
## plushie, fitted into the box. Entries not seen yet are a dark silhouette with a "?".

## Unseen entries: the picture multiplied by this (almost black, the shape still shows).
const SILHOUETTE: Color = Color(0.16, 0.14, 0.2, 1.0)
const MARK_COLOR: Color = Color("#d8d2e4")
## Share of the box the picture fills.
const FILL: float = 0.86

var entry: ScrapbookEntry
var seen: bool = false
## Holds the drawing (darkened for unseen entries, so the "?" stays bright).
var art: Control
## The "?" over an unseen entry.
var mark: Label

## Zombie puppets and pickups are sprites, fitted by this scale around this point.
var _holder: Node2D
var _puppet: ZombiePuppet
var _fit_scale: float = 1.0
var _fit_center: Vector2 = Vector2.ZERO
var _time: float = 0.0


func _init(box: float) -> void:
	custom_minimum_size = Vector2(box, box)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)


## Shows `what` (null = empty), in felt if `is_seen`, else as a silhouette.
func show_entry(what: ScrapbookEntry, is_seen: bool) -> void:
	entry = what
	seen = is_seen
	if art != null:
		remove_child(art)
		art.queue_free()
	if mark != null:
		remove_child(mark)
		mark.queue_free()
	art = Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_holder = null
	_puppet = null
	if entry == null:
		return
	_build_art()
	art.modulate = Color.WHITE if seen else SILHOUETTE
	if not seen:
		mark = TownArt.label("?", roundi(custom_minimum_size.y * 0.45))
		mark.add_theme_color_override(&"font_color", MARK_COLOR)
		mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)
	_place()


func is_silhouette() -> bool:
	return not seen


## Seen zombies sway a little, like they idle in the run.
func _process(delta: float) -> void:
	if _puppet == null or not seen or not is_visible_in_tree():
		return
	_time += delta
	_puppet.animate(_time, false, 1.0, false)


func _build_art() -> void:
	match entry.picture:
		ScrapbookEntry.Picture.ICON:
			var icon: UpgradeIcon = UpgradeIcon.new()
			icon.icon = entry.icon
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.add_child(icon)
		ScrapbookEntry.Picture.ZOMBIE:
			_holder = Node2D.new()
			art.add_child(_holder)
			_puppet = ZombiePuppet.new()
			_puppet.build(ZombieLook.for_look(entry.look), 0.0, entry.size)
			if entry.elite:
				_puppet.add_elite_marks()
			_puppet.animate(0.0, false, 1.0, false)
			_holder.add_child(_puppet)
			_fit()
		ScrapbookEntry.Picture.PICKUP:
			_holder = Node2D.new()
			art.add_child(_holder)
			var sprite: Sprite2D = FeltAtlas.make_sprite(FloorPickupLook.key(entry.pickup))
			_holder.add_child(sprite)
			_fit()
		ScrapbookEntry.Picture.PLUSHIE:
			art.draw.connect(_draw_plushie)
			art.queue_redraw()


func _draw_plushie() -> void:
	var box: Vector2 = custom_minimum_size
	var who: PlushieDef = entry.plushie
	# A plushie is about 3.2 units tall (times its height) and stands on its feet.
	var unit: float = box.y * FILL / 3.6 / maxf(who.height, 0.8)
	var feet: Vector2 = Vector2(art.size.x / 2.0, (art.size.y + box.y * FILL) / 2.0)
	PlushieLook.draw(art, who, feet, unit)


## Scales the sprites under `_holder` so all of them fit the box (any zombie or pickup size).
func _fit() -> void:
	var bounds: Rect2 = Rect2()
	var first: bool = true
	for sprite: Sprite2D in _sprites(_holder):
		if not sprite.visible:
			continue
		var rect: Rect2 = _to_holder(sprite) * sprite.get_rect()
		bounds = rect if first else bounds.merge(rect)
		first = false
	if first:
		return
	var longest: float = maxf(bounds.size.x, bounds.size.y)
	_fit_scale = custom_minimum_size.x * FILL / maxf(longest, 1.0)
	_fit_center = bounds.get_center()


func _place() -> void:
	if _holder == null:
		return
	_holder.scale = Vector2.ONE * _fit_scale
	var box: Vector2 = size if size.x > 0.0 else custom_minimum_size
	_holder.position = box / 2.0 - _fit_center * _fit_scale


func _sprites(node: Node) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child: Node in node.get_children():
		if child is Sprite2D:
			result.append(child as Sprite2D)
		result.append_array(_sprites(child))
	return result


## Where `node` sits inside `_holder` (its transforms multiplied up to the holder).
func _to_holder(node: Node2D) -> Transform2D:
	var result: Transform2D = Transform2D.IDENTITY
	var at: Node = node
	while at != _holder and at is Node2D:
		result = (at as Node2D).transform * result
		at = at.get_parent()
	return result
