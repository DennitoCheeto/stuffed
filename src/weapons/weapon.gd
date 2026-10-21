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


func setup(weapon_stats: WeaponStats, owner_player: Player) -> void:
	stats = weapon_stats
	player = owner_player
	name = String(stats.id)


## The numbers for the current level.
func current() -> WeaponLevel:
	return stats.at_level(level)


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
	_cooldown_left -= delta * player.attack_speed
	if _cooldown_left > 0.0:
		return
	if attack():
		_cooldown_left = current().cooldown
		fired.emit()
	else:
		_cooldown_left = RETRY_DELAY


## One attack. Returns false if there was nothing to attack (then it tries again soon).
func attack() -> bool:
	return false
