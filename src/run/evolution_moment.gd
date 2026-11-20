class_name EvolutionMoment
extends Node
## What happens in the run right after an evolution (spec 10 §3, AC-106): once the gift box screen
## is closed, time slows for a moment, a ring pulses from the hero, the first attack is drawn big
## and the evolution plays its own sting. Only the first time per evolution kind per run;
## Reduced motion skips the slow motion. A child of the run (it waits while the run is frozen).

const RULES: EvolutionMomentRules = preload("res://data/ui/evolution_moment.tres")

## One entry per moment played: weapon id, player index, run time, slowed (for tests and the log).
var moments: Array[Dictionary] = []
## True while the slow motion is on.
var slowed: bool = false

var _run: Run
## Evolved weapons waiting for the gift box screen to close.
var _waiting: Array[Weapon] = []
var _seen: Array[StringName] = []
var _speed_before: float = 1.0


func _enter_tree() -> void:
	_run = get_parent() as Run


## A hero's weapon just evolved into `weapon`.
func evolved(weapon: Weapon) -> void:
	_waiting.append(weapon)


func has_played(weapon_id: StringName) -> bool:
	return _seen.has(weapon_id)


func _process(_delta: float) -> void:
	if _waiting.is_empty() or _run == null:
		return
	if _run.is_frozen() or _run.gift_screen.is_open():
		return
	var due: Array[Weapon] = _waiting.duplicate()
	_waiting.clear()
	for weapon: Weapon in due:
		if is_instance_valid(weapon) and weapon.player != null:
			_play(weapon)


func _play(weapon: Weapon) -> void:
	var id: StringName = weapon.stats.id
	if _seen.has(id):
		return
	_seen.append(id)
	if weapon.stats.sting != &"":
		Sfx.play(weapon.stats.sting)
	weapon.boost_next_attack(RULES.big_attack_scale)
	weapon.player.add_child(EvolutionPulse.new(RULES))
	var slow: bool = not GameSettings.reduced_motion
	if slow:
		_slow_down()
	var entry: Dictionary = {
		"weapon": String(id),
		"player": weapon.player.player_index,
		"time": _run.elapsed,
		"slowed": slow,
	}
	moments.append(entry)


func _slow_down() -> void:
	if not slowed:
		_speed_before = Engine.time_scale
	slowed = true
	Engine.time_scale = _speed_before * RULES.slow_scale
	var timer: SceneTreeTimer = get_tree().create_timer(RULES.slow_seconds, true, false, true)
	timer.timeout.connect(_speed_up)


func _speed_up() -> void:
	if not slowed:
		return
	slowed = false
	Engine.time_scale = _speed_before


func _exit_tree() -> void:
	if slowed:
		slowed = false
		Engine.time_scale = _speed_before
