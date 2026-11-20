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
## The hero holding it; null for a turret (a building fires it in the siege, spec 07 §4).
var player: Player
## Turrets only: it fires only while a zombie is this close to it (pixels; 0 = hero weapon).
var mount_range: float = 0.0
## Turrets only: its row in the weapon tally (`WeaponTally.ARMORY` ...).
var tally_source: StringName = &""
## The next attack is drawn this much bigger (the first one after an evolution, spec 10 §3).
var attack_boost: float = 1.0

var _cooldown_left: float = FIRST_ATTACK_DELAY
var _current: WeaponLevel
var _current_key: Vector2i = Vector2i(-1, -1)
## Seconds until this weapon may play its sound again (`WeaponStats.sound_gap`).
var _sound_wait: float = 0.0


func setup(weapon_stats: WeaponStats, owner_player: Player) -> void:
	stats = weapon_stats
	player = owner_player
	name = String(stats.id)


## Makes it a turret: a building fires it on its own at zombies within `reach` (no hero).
func mount(weapon_stats: WeaponStats, weapon_level: int, reach: float, source: StringName) -> void:
	setup(weapon_stats, null)
	level = clampi(weapon_level, 1, weapon_stats.max_level())
	mount_range = reach
	tally_source = source


func is_turret() -> bool:
	return player == null and mount_range > 0.0


## Where its shots start and come back to: the hero, or the turret itself.
func origin() -> Vector2:
	return player.global_position if player != null else global_position


## Where aimed shots go: the hero's cursor, or a turret's nearest zombie in range.
func aim_point() -> Vector2:
	if player != null:
		return player.aim_point()
	var manager: EnemyManager = enemies()
	var target: Zombie = manager.nearest(origin(), mount_range) if manager != null else null
	return target.position if target != null else origin() + Vector2.RIGHT


## The way it fires when there is nothing to aim at.
func facing() -> Vector2:
	return player.facing if player != null else Vector2.RIGHT


## The holder's damage bonus (Sharp Scissors); 1 for a turret.
func damage_scale() -> float:
	return player.damage_multiplier if player != null else 1.0


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
	if player == null and not is_turret():
		return
	if player != null and player.is_dead():
		return
	_sound_wait -= delta
	_cooldown_left -= delta * (player.attack_speed if player != null else 1.0)
	if _cooldown_left > 0.0:
		return
	if is_turret() and not _zombie_in_range():
		_cooldown_left = RETRY_DELAY
		return
	if attack():
		attack_boost = 1.0
		_cooldown_left = current().cooldown
		if stats.sound != &"" and _sound_wait <= 0.0:
			Sfx.play(stats.sound, stats.sound_pitch)
			_sound_wait = stats.sound_gap
		fired.emit()
	else:
		_cooldown_left = RETRY_DELAY


## Draws the next attack `factor` times bigger (it eases back to normal size).
func boost_next_attack(factor: float) -> void:
	attack_boost = factor


## One attack. Returns false if there was nothing to attack (then it tries again soon).
func attack() -> bool:
	return false


func _zombie_in_range() -> bool:
	var manager: EnemyManager = enemies()
	return manager != null and manager.nearest(origin(), mount_range) != null


func _with_bonuses(base: WeaponLevel) -> WeaponLevel:
	var numbers: WeaponLevel = base.duplicate() as WeaponLevel
	if player == null:
		return numbers
	numbers.damage *= player.damage_multiplier
	numbers.reach *= player.range_multiplier
	numbers.duration *= player.range_multiplier
	numbers.area *= player.area_multiplier
	return numbers
