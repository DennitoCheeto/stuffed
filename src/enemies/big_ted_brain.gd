class_name BigTedBrain
extends BossBrain
## Big Ted's fight (BigTedDef): walk towards the nearest player, then take turns between the
## charge (red line, then he charges along it, then a short daze) and the stomp (he swells up
## inside a warning ring, then fires a ring of stuffing balls).

enum State { WALK, CHARGE_AIM, CHARGE, DAZED, STOMP_WINDUP }
enum Pattern { CHARGE, STOMP }

const CHARGE: StringName = &"charge"
const STOMP: StringName = &"stomp"
## How much he puffs up while aiming a charge (a full puff is the stomp).
const AIM_PUFF: float = 0.3

var state: State = State.WALK
## The pattern he starts next.
var next_pattern: Pattern = Pattern.CHARGE
## Seconds left in the current state (not used while walking).
var state_left: float = 0.0
## Where the current charge goes, fixed when the red line appears.
var charge_direction: Vector2 = Vector2.RIGHT
var charge_end: Vector2 = Vector2.ZERO

var _ted: BigTedDef


func _init(boss_def: BossDef) -> void:
	super(boss_def)
	_ted = boss_def as BigTedDef


func step(zombie: Zombie, target: Player, manager: EnemyManager, delta: float) -> Vector2:
	if zombie.is_stunned():
		return Vector2.ZERO
	if state != State.WALK:
		state_left -= delta
		return _pattern_step(zombie, target, manager, delta)
	pattern_cooldown -= delta
	if pattern_cooldown <= 0.0 and _in_range(zombie, target):
		_start_pattern(zombie, target, manager)
		return Vector2.ZERO
	return super.step(zombie, target, manager, delta)


## One frame of the pattern going on. He stands still, except while charging.
func _pattern_step(zombie: Zombie, target: Player, manager: EnemyManager, delta: float) -> Vector2:
	match state:
		State.CHARGE_AIM:
			telegraph.set_progress(_progress(_ted.charge_windup_seconds))
			if state_left <= 0.0:
				_start_charging(zombie, manager)
		State.CHARGE:
			return _charge_step(zombie, delta)
		State.DAZED:
			if state_left <= 0.0:
				_back_to_walking()
		State.STOMP_WINDUP:
			telegraph.set_progress(_progress(_ted.stomp.windup_seconds))
			if state_left <= 0.0:
				_stomp(zombie, target, manager)
	return Vector2.ZERO


func calm_down() -> void:
	super.calm_down()
	_back_to_walking()


func puff_amount() -> float:
	match state:
		State.STOMP_WINDUP:
			return _progress(_ted.stomp.windup_seconds)
		State.CHARGE_AIM:
			return AIM_PUFF * _progress(_ted.charge_windup_seconds)
	return 0.0


func is_busy() -> bool:
	return state != State.WALK


func _in_range(zombie: Zombie, target: Player) -> bool:
	if target == null:
		return false
	var reach: float = def.pattern_range
	return zombie.position.distance_squared_to(target.global_position) <= reach * reach


## Starts the next pattern aimed at `target`: shows its telegraph, the attack comes after.
func _start_pattern(zombie: Zombie, target: Player, manager: EnemyManager) -> void:
	var pattern: Pattern = next_pattern
	next_pattern = Pattern.STOMP if pattern == Pattern.CHARGE else Pattern.CHARGE
	if pattern == Pattern.CHARGE:
		charge_direction = zombie.position.direction_to(target.global_position)
		var inside: Rect2 = manager.play_rect.grow(-zombie.radius())
		var length: float = minf(
			_ted.charge_distance, _room_ahead(zombie.position, charge_direction, inside)
		)
		charge_end = zombie.position + charge_direction * length
		state = State.CHARGE_AIM
		state_left = _ted.charge_windup_seconds
		telegraph.show_charge(charge_direction * length, zombie.radius() * 2.0)
		manager.boss_telegraphed.emit(zombie, CHARGE)
	else:
		state = State.STOMP_WINDUP
		state_left = _ted.stomp.windup_seconds
		telegraph.show_stomp(_ted.stomp_ring_radius)
		manager.boss_telegraphed.emit(zombie, STOMP)


func _start_charging(zombie: Zombie, manager: EnemyManager) -> void:
	telegraph.clear()
	state = State.CHARGE
	# A safety limit: he stops even if something holds him back.
	state_left = zombie.position.distance_to(charge_end) / _ted.charge_speed + 0.5
	manager.boss_attacked.emit(zombie, CHARGE)


## Charges along the red line and stops exactly at its end.
func _charge_step(zombie: Zombie, delta: float) -> Vector2:
	var left: float = zombie.position.distance_to(charge_end)
	if left < 1.0 or state_left <= 0.0:
		state = State.DAZED
		state_left = _ted.charge_recover_seconds
		return Vector2.ZERO
	return charge_direction * minf(_ted.charge_speed, left / maxf(delta, 0.0001))


func _stomp(zombie: Zombie, target: Player, manager: EnemyManager) -> void:
	telegraph.clear()
	var aim: Vector2 = Vector2.RIGHT
	if target != null:
		aim = zombie.position.direction_to(target.global_position)
	var balls: int = _ted.stomp.balls_in_volley(0)
	var damage: float = _ted.stomp.bullet_damage * manager.damage_scale
	manager.fire_volley(zombie, aim, _ted.stomp, balls, damage)
	manager.boss_attacked.emit(zombie, STOMP)
	_back_to_walking()


func _back_to_walking() -> void:
	state = State.WALK
	pattern_cooldown = def.pattern_gap_seconds
	if telegraph != null:
		telegraph.clear()


## How far the current telegraph is: 0 = just shown, 1 = the attack comes now.
func _progress(windup: float) -> float:
	return clampf(1.0 - state_left / maxf(windup, 0.001), 0.0, 1.0)


## How far one can go from `from` along `direction` before leaving `area`.
static func _room_ahead(from: Vector2, direction: Vector2, area: Rect2) -> float:
	var room: float = INF
	if direction.x > 0.0:
		room = minf(room, (area.end.x - from.x) / direction.x)
	elif direction.x < 0.0:
		room = minf(room, (area.position.x - from.x) / direction.x)
	if direction.y > 0.0:
		room = minf(room, (area.end.y - from.y) / direction.y)
	elif direction.y < 0.0:
		room = minf(room, (area.position.y - from.y) / direction.y)
	return maxf(room, 0.0)
