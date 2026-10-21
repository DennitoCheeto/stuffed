class_name YarnProjectile
extends Projectile
## One bouncy yarn ball. Flies straight; when it hits a zombie it bounces on towards the nearest
## other zombie within the weapon's reach (or back off the one it hit if none is near). It also
## bounces off the arena's walls. Done after `pierce + 1` hits or when its duration runs out.

const SPIN_SPEED: float = 9.0

## Zombies hit so far.
var hits: int = 0
## Times it bounced off a wall.
var wall_bounces: int = 0

var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _time_left: float = 0.0
## The zombie it bounced off last: it can't hit that one again straight away.
var _last_hit: int = 0
## Zombies it already hit: it bounces on to fresh ones first.
var _already_hit: Dictionary[int, bool] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.YARN)


func reset() -> void:
	super()
	hits = 0
	wall_bounces = 0
	_last_hit = 0
	_already_hit.clear()


func launch(from: Weapon, direction: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_direction = direction
	_time_left = _numbers.duration
	global_position = from.player.global_position
	size_to(from.area_scale())


## How many zombies one ball may hit.
func max_hits() -> int:
	return _numbers.pierce + 1


func direction() -> Vector2:
	return _direction


func advance(delta: float) -> bool:
	_time_left -= delta
	if _time_left <= 0.0:
		return false
	global_position += _direction * _numbers.speed * delta
	_bounce_off_walls()
	rotation += SPIN_SPEED * delta
	for zombie: Zombie in manager.enemies.query_circle(global_position, weapon.hit_radius()):
		var id: int = zombie.get_instance_id()
		if id == _last_hit:
			continue
		_last_hit = id
		_already_hit[id] = true
		hits += 1
		manager.enemies.damage(zombie, _numbers.damage, _direction * weapon.stats.knockback)
		if hits >= max_hits():
			return false
		_direction = _next_direction(zombie)
		break
	return true


## Towards the nearest zombie in reach it hasn't hit yet (else any other one), or straight back
## off `bounced_off` if there is none.
func _next_direction(bounced_off: Zombie) -> Vector2:
	var best: Zombie = null
	var best_score: float = INF
	for zombie: Zombie in manager.enemies.query_circle(global_position, _numbers.reach):
		if zombie == bounced_off:
			continue
		var score: float = zombie.position.distance_squared_to(global_position)
		if _already_hit.has(zombie.get_instance_id()):
			score += _numbers.reach * _numbers.reach * 4.0
		if score < best_score:
			best = zombie
			best_score = score
	if best != null:
		return global_position.direction_to(best.position)
	var away: Vector2 = bounced_off.position.direction_to(global_position)
	return away if away != Vector2.ZERO else -_direction


func _bounce_off_walls() -> void:
	var walls: Rect2 = manager.play_rect
	if walls.size == Vector2.ZERO:
		return
	var inside: Vector2 = global_position.clamp(walls.position, walls.end)
	if inside.x != global_position.x:
		_direction.x = -_direction.x
		wall_bounces += 1
	if inside.y != global_position.y:
		_direction.y = -_direction.y
		wall_bounces += 1
	global_position = inside
