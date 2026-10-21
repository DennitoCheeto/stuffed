class_name DamageNumbers
extends Node2D
## Small damage numbers floating up from hit zombies, all drawn by this one node (cheap even with
## hundreds of hits). Quiet colours: the player's own effects stay softer than the enemies.
## Off when the pause menu's "Damage numbers" is off.

const LIFETIME: float = 0.6
const RISE: float = 28.0
const MAX_NUMBERS: int = 80
const FONT_SIZE: int = 18
const COLOR: Color = Color(1.0, 0.97, 0.88, 0.9)
const OUTLINE_COLOR: Color = Color(0.1, 0.09, 0.12, 0.8)

var _positions: PackedVector2Array = []
var _texts: PackedStringArray = []
var _ages: PackedFloat32Array = []


## Shows `amount` at `at` (world position). Does nothing while damage numbers are off.
func show_damage(amount: float, at: Vector2) -> void:
	if not GameSettings.damage_numbers:
		return
	if _ages.size() >= MAX_NUMBERS:
		_remove(0)
	_positions.append(at + Vector2(randf_range(-6.0, 6.0), -20.0))
	_texts.append(str(roundi(amount)))
	_ages.append(0.0)


func count() -> int:
	return _ages.size()


func _process(delta: float) -> void:
	var index: int = 0
	while index < _ages.size():
		_ages[index] += delta
		if _ages[index] >= LIFETIME:
			_remove(index)
		else:
			index += 1
	queue_redraw()


func _remove(index: int) -> void:
	_positions.remove_at(index)
	_texts.remove_at(index)
	_ages.remove_at(index)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for i: int in _ages.size():
		var progress: float = _ages[i] / LIFETIME
		var at: Vector2 = _positions[i] + Vector2(0.0, -RISE * progress)
		var fill: Color = COLOR
		fill.a *= 1.0 - progress * progress
		var edge: Color = OUTLINE_COLOR
		edge.a *= fill.a
		var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
		draw_string_outline(font, at, _texts[i], align, 40.0, FONT_SIZE, 4, edge)
		draw_string(font, at, _texts[i], align, 40.0, FONT_SIZE, fill)
