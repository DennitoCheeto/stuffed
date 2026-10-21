class_name Player
extends CharacterBody2D
## A hero controlled by one player: walks, dashes and takes contact damage.

signal health_changed(current: float, maximum: float)
signal dashed(from_position: Vector2, direction: Vector2)
signal died(player: Player)

const GROUP: StringName = &"players"

@export var stats: HeroStats
## 0 = player 1. Decides which input actions this hero listens to.
@export var player_index: int = 0

var health: float = 0.0
var max_health: float = 0.0
## Last non-zero move direction; a dash while standing still goes this way.
var facing: Vector2 = Vector2.RIGHT
## Name of whatever hit the hero last (shown on the end screen later).
var last_hit_by: String = ""

var _input: PlayerInput
var _dash_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_cooldown_left: float = 0.0
var _hurt_invulnerable_left: float = 0.0

@onready var _hitbox: CollisionShape2D = $Hitbox


func _ready() -> void:
	add_to_group(GROUP)
	_input = PlayerInput.new(player_index)
	max_health = stats.max_health
	health = max_health
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = stats.hitbox_radius
	_hitbox.shape = shape


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_hurt_invulnerable_left = maxf(_hurt_invulnerable_left - delta, 0.0)
	if is_dead():
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = _input.move_vector()
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	if not is_dashing() and _input.is_just_pressed("dash"):
		try_dash()
	if is_dashing():
		_move_dash(delta)
	else:
		velocity = direction * stats.move_speed
		move_and_slide()


## Starts a dash in the facing direction. Returns false while the dash is cooling down.
func try_dash() -> bool:
	if not can_dash():
		return false
	_dash_left = stats.dash_distance
	_dash_direction = facing
	_dash_cooldown_left = stats.dash_cooldown
	dashed.emit(global_position, _dash_direction)
	return true


func can_dash() -> bool:
	return not is_dead() and not is_dashing() and _dash_cooldown_left <= 0.0


func is_dashing() -> bool:
	return _dash_left > 0.0


## 0 right after a dash, 1 when the next dash is ready.
func dash_ready_ratio() -> float:
	if stats.dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - _dash_cooldown_left / stats.dash_cooldown


func is_invulnerable() -> bool:
	return is_dashing() or _hurt_invulnerable_left > 0.0


func is_dead() -> bool:
	return health <= 0.0


## Contact damage. Ignored while dashing or right after another hit. Returns true if it hurt.
func take_hit(amount: float, source: String) -> bool:
	if is_dead() or is_invulnerable():
		return false
	health = maxf(health - amount, 0.0)
	last_hit_by = source
	_hurt_invulnerable_left = stats.hurt_invulnerability
	health_changed.emit(health, max_health)
	if is_dead():
		died.emit(self)
	return true


func _move_dash(delta: float) -> void:
	var dash_speed: float = stats.dash_distance / maxf(stats.dash_duration, 0.001)
	var step: float = minf(dash_speed * delta, _dash_left)
	_dash_left -= step
	velocity = _dash_direction * (step / delta)
	move_and_slide()
	if is_on_wall():
		_dash_left = 0.0
	if not is_dashing():
		velocity = Vector2.ZERO
