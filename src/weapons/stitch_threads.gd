class_name StitchThreads
extends Node2D
## Draws the threads of one Sewing Storm's flung needles (stitch-up, spec 10 §3) in one go: all
## segments of all needles in one `draw_multiline`, so the whole storm costs one draw call. Sits on
## the own-shots layer, under the zombies.

var storm: SewingStorm
## Segments drawn in the last frame (for tests): pairs of points.
var segments: PackedVector2Array = []


func _init() -> void:
	name = "StitchThreads"
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


func _process(_delta: float) -> void:
	var was_drawing: bool = not segments.is_empty()
	segments = _collect()
	if was_drawing or not segments.is_empty():
		modulate.a = GameSettings.own_effects
		queue_redraw()


func _collect() -> PackedVector2Array:
	var result: PackedVector2Array = []
	if storm == null:
		return result
	for needle: StormNeedleProjectile in storm.needles():
		var points: PackedVector2Array = needle.thread_points()
		for i: int in range(1, points.size()):
			result.append(points[i - 1])
			result.append(points[i])
	return result


func _draw() -> void:
	if segments.is_empty() or storm.stats.stitch_up == null:
		return
	var stitch: StitchUp = storm.stats.stitch_up
	draw_multiline(segments, stitch.thread_color, stitch.thread_width)
