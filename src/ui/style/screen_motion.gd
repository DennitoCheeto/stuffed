class_name ScreenMotion
extends Node
## Opens and closes a menu screen with juice (spec 04 §3): panels drop in one after the other
## with a little overshoot and settle at their tilt; closing slides them down quickly.
## Never blocks input: any key or click during the motion jumps it to the end at once (the
## press itself still reaches the buttons).

## Long enough to finish any motion in one step.
const FINISH_STEP: float = 60.0

var _tween: Tween


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Drops `parts` in, one after the other, with the "ui_open" whoosh. `turn` false = straight
## down, no extra tilt (level-up cards are read while they land).
func open(parts: Array[Wobbly], turn: bool = true) -> void:
	finish()
	Sfx.play(&"ui_open")
	var style: UiStyle = UiFeel.STYLE
	if UiFeel.reduced() or not is_inside_tree():
		for part: Wobbly in parts:
			part.rest()
		return
	_tween = create_tween().set_parallel()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for index: int in parts.size():
		var part: Wobbly = parts[index]
		part.lift = style.open_drop
		part.spin = style.open_spin if turn else 0.0
		part.fade = 0.0
		var delay: float = index * style.open_stagger
		var drop: PropertyTweener = _tween.tween_property(part, "lift", 0.0, style.open_seconds)
		drop.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var settle: PropertyTweener = _tween.tween_property(part, "spin", 0.0, style.open_seconds)
		settle.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(part, "fade", 1.0, style.open_seconds * 0.4).set_delay(delay)


## Flies `parts` out from somewhere else to their places (#342: gift cards out of the box), with
## the "ui_open" whoosh: each starts `offsets[i]` px away at `grow_from` size, then flies home
## and grows with a small overshoot over `seconds`, one `stagger` after the other.
func flow_out(
	parts: Array[Wobbly], offsets: Array[Vector2], seconds: float, stagger: float, grow_from: float
) -> void:
	finish()
	Sfx.play(&"ui_open")
	if UiFeel.reduced() or not is_inside_tree():
		for part: Wobbly in parts:
			part.rest()
		return
	_tween = create_tween().set_parallel()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for index: int in parts.size():
		var part: Wobbly = parts[index]
		part.drift = offsets[index]
		part.grow = grow_from
		part.fade = 0.0
		var delay: float = index * stagger
		var fly: PropertyTweener = _tween.tween_property(part, "drift", Vector2.ZERO, seconds)
		fly.set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var grow: PropertyTweener = _tween.tween_property(part, "grow", 1.0, seconds)
		grow.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(part, "fade", 1.0, seconds * 0.3).set_delay(delay)


## Slides `parts` down and fades them out quickly, then calls `done`.
func close(parts: Array[Wobbly], done: Callable = Callable()) -> void:
	finish()
	var style: UiStyle = UiFeel.STYLE
	if UiFeel.reduced() or not is_inside_tree():
		_closed(done)
		return
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for part: Wobbly in parts:
		_tween.tween_property(part, "lift", -style.close_drop, style.close_seconds)
		_tween.tween_property(part, "fade", 0.0, style.close_seconds)
	_tween.chain().tween_callback(_closed.bind(done))


func is_moving() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## Jumps the current motion to its end.
func finish() -> void:
	if is_moving():
		_tween.custom_step(FINISH_STEP)
	_tween = null


func _input(event: InputEvent) -> void:
	if not is_moving() or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		finish()


func _closed(done: Callable) -> void:
	if done.is_valid():
		done.call()
