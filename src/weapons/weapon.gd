class_name Weapon
extends Node2D
## A weapon that belongs to one player and attacks on its own (no buttons). Subclasses decide
## what an attack is. Its shots live in the run's ProjectileManager, not under the weapon.

signal fired

## Seconds after the run starts (or the weapon is picked) before the first attack.
const FIRST_ATTACK_DELAY: float = 0.4
## When there is nothing to attack, look again after this many seconds.
const RETRY_DELAY: float = 0.1

var stats: WeaponStats
var level: int = 1
var player: Player

var _cooldown_left: float = FIRST_ATTACK_DELAY
var _current: WeaponLevel
var _current_key: Vector2i = Vector2i(-1, -1)
## Seconds until this weapon may play its sound again (`WeaponStats.sound_gap`).
var _sound_wait: float = 0.0


func setup(weapon_stats: WeaponStats, owner_player: Player) -> void:
	stats = weapon_stats
	player = owner_player
	name = String(stats.id)


## The numbers for the current level, with the owner's items applied (Sharp Scissors, Long
## Thread, Big Spool). Use these, not `stats`, for anything an item can change.
func current() -> WeaponLevel:
	var key: Vector2i = Vector2i(level, player.bonus_version if player != null else 0)
	if _current == null or key != _current_key:
		_current = _with_bonuses(stats.at_level(level))
		_current_key = key
	return _current


## Radius of one shot's hit area (Big Spool makes it bigger).
func hit_radius() -> float:
	return stats.hit_radius * area_scale()


## How much bigger areas and shots are than their data (1 = as in the data).
func area_scale() -> float:
	return player.area_multiplier if player != null else 1.0


func is_maxed() -> bool:
	return level >= stats.max_level()


func level_up() -> void:
	level = mini(level + 1, stats.max_level())


func enemies() -> EnemyManager:
	return get_tree().get_first_node_in_group(EnemyManager.GROUP) as EnemyManager


func projectiles() -> ProjectileManager:
	return get_tree().get_first_node_in_group(ProjectileManager.GROUP) as ProjectileManager


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead():
		return
	_sound_wait -= delta
	_cooldown_left -= delta * player.attack_speed
	if _cooldown_left > 0.0:
		return
	if attack():
		_cooldown_left = current().cooldown
		if stats.sound != &"" and _sound_wait <= 0.0:
			Sfx.play(stats.sound, stats.sound_pitch)
			_sound_wait = stats.sound_gap
		fired.emit()
	else:
		_cooldown_left = RETRY_DELAY


## One attack. Returns false if there was nothing to attack (then it tries again soon).
func attack() -> bool:
	return false


func _with_bonuses(base: WeaponLevel) -> WeaponLevel:
	var numbers: WeaponLevel = base.duplicate() as WeaponLevel
	if player == null:
		return numbers
	numbers.damage *= player.damage_multiplier
	numbers.reach *= player.range_multiplier
	numbers.duration *= player.range_multiplier
	numbers.area *= player.area_multiplier
	return numbers
