class_name ZipperSeam
extends Node2D
## Where Unzipper's two halves meet again (spec 11 §4.6). The halves tell it every zombie they
## sweep over (`sweep`); when they snap shut (`zip_shut`) each of those still standing takes the
## zip-shut hit, once. Draws a short flash along the middle line (one line, above the floor).
## The halves find it by node name, so they never refer to the weapon's class (script cycles leak
## resources).

const NAME: StringName = &"ZipperSeam"

## The weapon whose seam this is (its numbers and its tally row).
var weapon: Weapon
## Zip-shuts so far, and zombies they hit (for tests).
var shuts: int = 0
var shut_hits: int = 0

## Zombie instance id → zombie, swept since the beam opened.
var _swept: Dictionary[int, Zombie] = {}
var _flash_from: Vector2 = Vector2.ZERO
var _flash_to: Vector2 = Vector2.ZERO
var _flash_left: float = 0.0


func _init() -> void:
	name = NAME
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


## A new beam opens: forget the last one's zombies.
func begin() -> void:
	_swept.clear()


func sweep(zombie: Zombie) -> void:
	_swept[zombie.get_instance_id()] = zombie


## Zombies swept so far (still standing).
func swept() -> Array[Zombie]:
	var result: Array[Zombie] = []
	for zombie: Zombie in _swept.values():
		if is_instance_valid(zombie) and not zombie.dead:
			result.append(zombie)
	return result


## The halves met along `from` → `to`: every swept zombie takes the zip-shut hit.
func zip_shut(from: Vector2, to: Vector2) -> void:
	var sweep_rules: ZipperSweep = _sweep_rules()
	var manager: EnemyManager = weapon.enemies() if weapon != null else null
	if sweep_rules == null or manager == null:
		return
	shuts += 1
	Sfx.play(sweep_rules.shut_sound)
	var damage: float = sweep_rules.shut_damage * weapon.damage_scale()
	for zombie: Zombie in swept():
		shut_hits += 1
		var push: Vector2 = Vector2.ZERO
		if not zombie.is_boss():
			push = from.direction_to(zombie.position) * sweep_rules.shut_push
		manager.damage(zombie, damage, push, weapon)
	_swept.clear()
	_flash_from = from
	_flash_to = to
	_flash_left = sweep_rules.seam_seconds


func _sweep_rules() -> ZipperSweep:
	return weapon.stats.zipper_sweep if weapon != null and weapon.stats != null else null


func _process(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	modulate.a = GameSettings.own_effects
	queue_redraw()


func _draw() -> void:
	var sweep_rules: ZipperSweep = _sweep_rules()
	if sweep_rules == null or _flash_left <= 0.0:
		return
	var color: Color = sweep_rules.seam_color
	color.a *= _flash_left / maxf(sweep_rules.seam_seconds, 0.001)
	draw_line(_flash_from, _flash_to, color, sweep_rules.seam_width)
