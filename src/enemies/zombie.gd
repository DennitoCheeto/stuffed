class_name Zombie
extends Node2D
## One zombie plushie: its health, how it reacts to hits and how it looks. The EnemyManager moves
## all zombies together (that is much faster than each zombie moving itself).

const KNOCKBACK_DECAY: float = 8.0

var stats: EnemyStats
var health: float = 0.0
var max_health: float = 0.0
var contact_damage: float = 0.0
var move_speed: float = 0.0
## Extra push from hits, fades out quickly.
var knockback: Vector2 = Vector2.ZERO
## Direction it is walking (zero when standing).
var heading: Vector2 = Vector2.ZERO
## Seconds it can't move (banana peel).
var stun_left: float = 0.0
var dead: bool = false
var puppet: ZombiePuppet

var _time: float = 0.0
var _since_hit: float = INF
var _stars: StunStars


## `phase` (0..1) keeps zombies from shambling in perfect sync.
func setup(enemy_stats: EnemyStats, health_scale: float, damage_scale: float, phase: float) -> void:
	stats = enemy_stats
	max_health = stats.max_health * health_scale
	health = max_health
	contact_damage = stats.contact_damage * damage_scale
	move_speed = stats.move_speed
	puppet = ZombiePuppet.new()
	add_child(puppet)
	puppet.build(ZombieLook.for_look(stats.look), phase)


## Takes damage and a push. Returns true if this hit killed it.
func take_damage(amount: float, push: Vector2) -> bool:
	if dead:
		return false
	health -= amount
	knockback += push * stats.knockback_taken
	_since_hit = 0.0
	if health <= 0.0:
		dead = true
	return dead


func radius() -> float:
	return stats.radius


## Can't move for `seconds` (slipped on a banana peel): it spins and sees stars.
func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)
	if _stars == null:
		_stars = StunStars.new()
		_stars.position = Vector2(0.0, -48.0)
		add_child(_stars)
	_stars.visible = true


func is_stunned() -> bool:
	return stun_left > 0.0


## Advances its timers and animation by one frame.
func tick(delta: float) -> void:
	_time += delta
	_since_hit += delta
	stun_left = maxf(stun_left - delta, 0.0)
	knockback = knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	puppet.animate(_time, heading != Vector2.ZERO, _since_hit, heading.x < 0.0)
	if _stars != null:
		_stars.visible = is_stunned()
		puppet.spin(stun_left)
