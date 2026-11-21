class_name LowHealthWarning
extends Node
## The low-health warning of one hero (spec 10 §7, AC-115): below `LowHealthRules.threshold` of
## max health a soft heartbeat plays and the hero's heart patch (HUD and the small bar under the
## hero) pulses on every beat. It stops once the hero is healed above the line or falls. Each hero
## has their own (co-op, spec 10 §8). Numbers in `data/ui/low_health.tres`.

signal beat

const RULES: LowHealthRules = preload("res://data/ui/low_health.tres")

## True while the warning runs.
var active: bool = false
## Heartbeats played so far (for tests).
var beats: int = 0

var _player: Player
var _since_beat: float = 0.0


func setup(player: Player) -> void:
	_player = player


func _process(delta: float) -> void:
	if _player != null:
		tick(_player.health, _player.max_health, delta)


## Moves the warning on by `delta` seconds at `health` of `maximum`. The first beat comes at once.
func tick(health: float, maximum: float, delta: float) -> void:
	var low: bool = is_low(health, maximum)
	if low != active:
		active = low
		_since_beat = RULES.beat_seconds
	if not active:
		return
	_since_beat += delta
	if _since_beat >= RULES.beat_seconds:
		_since_beat = 0.0
		beats += 1
		Sfx.play(RULES.sound)
		beat.emit()


## 1 right on a beat, fading to 0 over `pulse_seconds`; 0 while the warning is off.
func pulse() -> float:
	if not active or RULES.pulse_seconds <= 0.0:
		return 0.0
	return clampf(1.0 - _since_beat / RULES.pulse_seconds, 0.0, 1.0)


## How big the heart patch is drawn now (1 = normal size).
func heart_scale() -> float:
	return 1.0 + RULES.pulse_grow * pulse()


## The heart's rose, lighter on a beat.
func heart_color(base: Color) -> Color:
	return base.lightened(RULES.pulse_lighten * pulse())


## True when `health` of `maximum` is low enough for the warning (a fallen hero is not "low").
static func is_low(health: float, maximum: float) -> bool:
	return maximum > 0.0 and health > 0.0 and health < maximum * RULES.threshold


## The warning of `player`, or null (town heroes carry none).
static func of(player: Player) -> LowHealthWarning:
	if player == null:
		return null
	return player.get_node_or_null(^"LowHealthWarning") as LowHealthWarning
