class_name SiegeWaves
extends RefCounted
## The clock of one night siege (spec 07 §2, §5): wave 1 spawns for `wave_seconds`, a short
## breather, wave 2, ... After the last wave nothing new comes. Also says when a wave's elites and
## its boss are due. Pure logic: the siege asks it every frame and spawns what it says.

var rules: SiegeRules
## The wave going on (0 = the first; -1 = not started yet).
var wave: int = -1
## Seconds into the current wave (or into the breather after it).
var wave_time: float = 0.0
## True during the breather after a wave.
var resting: bool = false
## True once the last wave has brought everything it brings.
var finished: bool = false

## Elites of the current wave already handed out.
var _elites_given: int = 0
var _boss_given: bool = false


func _init(siege_rules: SiegeRules) -> void:
	rules = siege_rules


func count() -> int:
	return rules.wave_list.size()


## The wave going on (null before the first one).
func current() -> SiegeWave:
	if wave < 0 or wave >= count():
		return null
	return rules.wave_list[wave]


## Moves the clock on by `delta` seconds. Returns the index of a wave that starts now (-1 = none).
func tick(delta: float) -> int:
	if finished:
		return -1
	if wave < 0:
		return _start(0)
	wave_time += delta
	if resting:
		return _start(wave + 1) if wave_time >= rules.breather_seconds else -1
	if wave_time >= rules.wave_seconds:
		if wave + 1 >= count():
			finished = true
		else:
			resting = true
			wave_time = 0.0
	return -1


## True while the current wave brings new zombies.
func spawning() -> bool:
	return wave >= 0 and not resting and not finished


## Zombies per second right now (0 during a breather).
func rate() -> float:
	return current().rate if spawning() else 0.0


## How many of the current wave's elites are due now (each one is handed out once).
func take_elites() -> int:
	var wave_now: SiegeWave = current()
	if not spawning() or wave_now == null:
		return 0
	var due: int = 0
	while _elites_given < wave_now.elites:
		if wave_now.elite_at(_elites_given, rules.wave_seconds) > wave_time:
			break
		_elites_given += 1
		due += 1
	return due


## The current wave's boss when he is due (once), else null.
func take_boss() -> BossDef:
	var wave_now: SiegeWave = current()
	if not spawning() or wave_now == null or wave_now.boss == null or _boss_given:
		return null
	if wave_time < wave_now.boss_at:
		return null
	_boss_given = true
	return wave_now.boss


## How many waves were held off so far: every wave that stopped coming (a won siege held them
## all, `won`). A wave that is still coming, or whose zombies are still around, isn't held yet.
func held(won: bool) -> int:
	if won:
		return count()
	if wave < 0:
		return 0
	if resting:
		return wave + 1
	return wave


## Developer menu: the next wave starts right away (after the last one, the waves are over).
## Returns the index of the wave that started (-1 = none).
func next_wave() -> int:
	if finished:
		return -1
	if wave + 1 >= count():
		finished = true
		return -1
	return _start(wave + 1)


func _start(index: int) -> int:
	wave = index
	wave_time = 0.0
	resting = false
	_elites_given = 0
	_boss_given = false
	return index
