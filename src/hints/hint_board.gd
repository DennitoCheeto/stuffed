class_name HintBoard
extends CanvasLayer
## Shows the first-time hint notes of one screen (spec 10 §6), one at a time, above the HUD and
## the level-up cards but under the pause menu. A note never covers a hero (it moves to the other
## edge of the screen), never pauses anything, and goes away when the player does the thing
## (`finish`) or after `HintRules.show_seconds` (then it shows once more next time).
## Subclasses watch their screen and call `try_show` / `finish` (RunHints; town hints in M6-11).

const RULES: HintRules = preload("res://data/ui/hints.tres")
## Above the HUD and the level-up / goal screens (20), under the pause menu (30).
const LAYER: int = 25

## Where seen hints are remembered (the town save; null = nothing shows).
var save: TownSave
## The note showing now (null = none).
var note: HintNote
## Ids of the hints shown on this screen, in order (log field `hints`).
var shown: PackedStringArray = []
## Seconds the current note has shown (only while `_ticking()`).
var showing_for: float = 0.0
## True once the player did what the current note asks; it goes after `done_seconds`.
var done: bool = false
var _done_for: float = 0.0
var _leaving: bool = false


func _init() -> void:
	name = "Hints"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS


## Shows hint `id` if it is due, no other note is showing and it hasn't shown on this screen
## yet (a note that went away by itself comes back next time, not right away). True if it showed.
func try_show(id: String) -> bool:
	if save == null or note != null or shown.has(id) or not HintBook.is_due(save, id):
		return false
	var hint: HintDef = RULES.find(id)
	if hint == null:
		return false
	note = HintNote.new(hint, RULES.font_size, RULES.tilt_degrees)
	note.fade = 0.0
	add_child(note)
	shown.append(id)
	showing_for = 0.0
	done = false
	_done_for = 0.0
	_leaving = false
	_place()
	return true


## The player did what hint `id` asks: it is seen for good, and its note goes away soon.
func finish(id: String) -> void:
	if save == null or not is_showing(id) or done:
		return
	HintBook.mark_done(save, id)
	done = true


func is_showing(id: String) -> bool:
	return note != null and note.hint.id == id and not _leaving


## The id of the note showing now ("" = none).
func showing() -> String:
	return note.hint.id if note != null else ""


## Where the note is on the screen (empty rect if none).
func note_rect() -> Rect2:
	if note == null:
		return Rect2()
	return Rect2(note.position, note.size)


## The screen area each hero takes (with `hero_margin` around it); notes stay out of them.
func hero_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for player: Player in Players.all(get_tree()):
		var at: Vector2 = player.get_global_transform_with_canvas().origin
		var margin: float = RULES.hero_margin
		# The hero's feet are at its position; the body reaches about one margin up.
		rects.append(Rect2(at - Vector2(margin, margin * 2.0), Vector2(margin * 2.0, margin * 3.0)))
	return rects


func _process(delta: float) -> void:
	if note == null:
		_watch()
		return
	if not GameSettings.hints and not _leaving:
		_leave()
	note.visible = not _hidden_now()
	_place()
	_fade(delta)
	if _leaving:
		return
	if done:
		_done_for += delta
		if _done_for >= RULES.done_seconds:
			_leave()
		return
	if _ticking():
		showing_for += delta
		if showing_for >= RULES.show_seconds:
			HintBook.timed_out(save, note.hint.id)
			_leave()
	_watch()


## Subclasses look at their screen here: `try_show` new hints, `finish` the current one.
func _watch() -> void:
	pass


## True while the current note should hide for a moment (it comes back as it was).
func _hidden_now() -> bool:
	return false


## True while the current note's clock runs (a run's notes wait while the run is frozen).
func _ticking() -> bool:
	return true


## The note goes away (without counting as seen or timed out).
func _leave() -> void:
	_leaving = true


func _fade(delta: float) -> void:
	var step: float = delta / maxf(RULES.fade_seconds, 0.01)
	if _leaving:
		note.fade = maxf(note.fade - step, 0.0)
		if note.fade <= 0.0:
			remove_child(note)
			note.queue_free()
			note = null
	else:
		note.fade = minf(note.fade + step, 1.0)


## Puts the note at its edge of the screen, or at the other edge if a hero is in the way.
func _place() -> void:
	if note == null:
		return
	note.size = note.get_combined_minimum_size()
	var side: float = 1.0 if (shown.size() - 1) % 2 == 0 else -1.0
	note.tilt = side * RULES.tilt_degrees * minf(1.0, RULES.tilt_width / maxf(note.size.x, 1.0))
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var x: float = (screen.x - note.size.x) / 2.0
	var margin: float = note.hint.margin if note.hint.margin >= 0.0 else RULES.edge_margin
	var top: Rect2 = Rect2(Vector2(x, margin), note.size)
	var bottom_y: float = screen.y - margin - note.size.y
	var bottom: Rect2 = Rect2(Vector2(x, bottom_y), note.size)
	var first: Rect2 = top if note.hint.place == HintDef.Place.TOP else bottom
	var other: Rect2 = bottom if note.hint.place == HintDef.Place.TOP else top
	note.position = (other if _covers_hero(first) and not _covers_hero(other) else first).position


func _covers_hero(rect: Rect2) -> bool:
	for hero: Rect2 in hero_rects():
		if hero.intersects(rect):
			return true
	return false
