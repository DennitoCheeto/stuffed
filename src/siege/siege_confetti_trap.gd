class_name SiegeConfettiTrap
extends SiegeRing
## The Party Shop in the night siege (spec 07 §4, AC-78): every `seconds` a confetti pop hurts
## every zombie inside its ring. When nothing is in reach it waits, loaded, and pops as soon as a
## zombie steps in. The ring brightens as the next pop loads. Its damage counts in the weapon
## tally under the Party Shop's own row. Numbers: `BuildingLevel.siege_trap_seconds` /
## `siege_trap_damage` / `siege_range`, look and sound in `SiegeRules`.

## Emitted on each pop with how many zombies it hit.
signal popped(hits: int)

## How much the ring glows while loading (the rest comes in the moment of the pop).
const LOAD_GLOW: float = 0.5

var seconds: float = 8.0
var damage: float = 0.0
## Pops so far (for tests).
var pops: int = 0

var _enemies: EnemyManager
var _effects: Node
var _rules: SiegeRules
var _left: float = 0.0
var _flash: float = 0.0


func setup(
	target: SiegeBuilding, data: BuildingLevel, at: Vector2, rules: SiegeRules, run: Run
) -> void:
	place(target, data.siege_range, at, rules.trap_ring_color)
	seconds = data.siege_trap_seconds
	damage = data.siege_trap_damage
	_rules = rules
	_enemies = run.enemies
	_effects = run.effects
	_left = seconds
	name = "ConfettiTrap_%s" % target.id


## Seconds until the trap is loaded again (0 = loaded, waiting for a zombie).
func time_left() -> float:
	return _left


func _work(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	_flash = maxf(_flash - delta / maxf(_rules.trap_confetti_seconds, 0.01), 0.0)
	if _left <= 0.0:
		var inside: Array[Zombie] = _enemies.query_circle(position, radius)
		if not inside.is_empty():
			_pop(inside)
	var loading: float = 1.0 - _left / maxf(seconds, 0.01)
	glow = maxf(loading * LOAD_GLOW, _flash)


func _pop(inside: Array[Zombie]) -> void:
	_left = seconds
	_flash = 1.0
	pops += 1
	for zombie: Zombie in inside:
		_enemies.damage_from(WeaponTally.PARTY_SHOP, zombie, damage)
	var view: Rect2 = Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var confetti: ConfettiBlast = ConfettiBlast.new(
		position, view, _rules.trap_confetti_seconds, pops
	)
	_effects.add_child(confetti)
	Sfx.play(_rules.trap_sound, _rules.trap_pitch)
	popped.emit(inside.size())
