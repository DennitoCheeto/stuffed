class_name SockKingBrain
extends BossBrain
## The Sock Puppet King's fight (SockKingDef): walk towards the nearest player and take turns
## between the sock spiral and the summon. From half health on he is angry and adds a lunge
## between them.

enum State { WALK, SPIRAL_WINDUP, SPIRAL, SUMMON_WINDUP, LUNGE_AIM, LUNGE, RECOVER }
enum Pattern { SPIRAL, SUMMON, LUNGE }

const SPIRAL: StringName = &"spiral"
const SUMMON: StringName = &"summon"
const LUNGE: StringName = &"lunge"
## His patterns in turn, before and after he gets angry.
const CALM_TURNS: Array[Pattern] = [Pattern.SPIRAL, Pattern.SUMMON]
const ANGRY_TURNS: Array[Pattern] = [Pattern.SPIRAL, Pattern.LUNGE, Pattern.SUMMON, Pattern.LUNGE]

var state: State = State.WALK
## True from half health on.
var angry: bool = false
## Where the summoned zombies appear, fixed when the marks show.
var summon_points: Array[Vector2] = []
## Where the lunge lands, fixed when the red circle shows.
var landing_spot: Vector2 = Vector2.ZERO

var _king: SockKingDef
## Index into the current turn list: the pattern he starts next.
var _turn: int = 0
var _spiral_angle: float = 0.0
var _until_volley: float = 0.0
var _lunge_from: Vector2 = Vector2.ZERO
## His puppet, lifted while he flies.
var _lifted: Node2D


func _init(boss_def: BossDef) -> void:
	super(boss_def)
	_king = boss_def as SockKingDef


## The pattern he starts next.
func next_pattern() -> Pattern:
	var turns: Array[Pattern] = ANGRY_TURNS if angry else CALM_TURNS
	return turns[_turn % turns.size()]


## Makes `pattern` the next one (tests, developer menu).
func set_next_pattern(pattern: Pattern) -> void:
	var turns: Array[Pattern] = ANGRY_TURNS if angry else CALM_TURNS
	_turn = maxi(turns.find(pattern), 0)


func step(zombie: Zombie, target: Player, manager: EnemyManager, delta: float) -> Vector2:
	if not angry and zombie.health <= zombie.max_health * _king.angry_below:
		_get_angry(zombie, manager)
	if zombie.is_stunned() and state != State.LUNGE:
		return Vector2.ZERO
	if state != State.WALK:
		state_left -= delta
		return _pattern_step(zombie, manager, delta)
	pattern_cooldown -= delta
	if pattern_cooldown <= 0.0 and _in_range(zombie, target):
		_start_pattern(zombie, target, manager)
		return Vector2.ZERO
	return super.step(zombie, target, manager, delta)


## One frame of the pattern going on. He stands still, except while he flies.
func _pattern_step(zombie: Zombie, manager: EnemyManager, delta: float) -> Vector2:
	match state:
		State.SPIRAL_WINDUP:
			if state_left <= 0.0:
				state = State.SPIRAL
				state_left = _king.spiral_seconds
				_until_volley = 0.0
				manager.boss_attacked.emit(zombie, SPIRAL)
		State.SPIRAL:
			_spiral_step(zombie, manager, delta)
		State.SUMMON_WINDUP:
			telegraph.set_progress(_progress(_king.summon_windup_seconds))
			if state_left <= 0.0:
				_summon(zombie, manager)
		State.LUNGE_AIM:
			telegraph.set_progress(_progress(_king.lunge_windup_seconds))
			if state_left <= 0.0:
				_take_off(zombie, manager)
		State.LUNGE:
			return _lunge_step(zombie, manager, delta)
		State.RECOVER:
			if state_left <= 0.0:
				_back_to_walking()
	return Vector2.ZERO


func calm_down() -> void:
	super.calm_down()
	_back_to_walking()


func puff_amount() -> float:
	if state == State.SPIRAL_WINDUP:
		return _progress(_king.spiral.windup_seconds)
	return 0.0


func is_busy() -> bool:
	return state != State.WALK


func is_airborne() -> bool:
	return state == State.LUNGE


func _get_angry(zombie: Zombie, manager: EnemyManager) -> void:
	angry = true
	# The lunge comes next, so the change is felt right away.
	_turn = ANGRY_TURNS.find(Pattern.LUNGE)
	manager.boss_angry.emit(zombie)


func _start_pattern(zombie: Zombie, target: Player, manager: EnemyManager) -> void:
	var pattern: Pattern = next_pattern()
	_turn += 1
	match pattern:
		Pattern.SPIRAL:
			state = State.SPIRAL_WINDUP
			state_left = _king.spiral.windup_seconds
			_spiral_angle = zombie.position.angle_to_point(target.global_position)
			manager.boss_telegraphed.emit(zombie, SPIRAL)
		Pattern.SUMMON:
			state = State.SUMMON_WINDUP
			state_left = _king.summon_windup_seconds
			summon_points = _ring_points(zombie, manager)
			var offsets: Array[Vector2] = []
			for point: Vector2 in summon_points:
				offsets.append(point - zombie.position)
			telegraph.show_marks(offsets, _king.summon_enemy.radius * 1.5)
			manager.boss_telegraphed.emit(zombie, SUMMON)
		Pattern.LUNGE:
			state = State.LUNGE_AIM
			state_left = _king.lunge_windup_seconds
			var inside: Rect2 = manager.play_rect.grow(-zombie.radius())
			landing_spot = target.global_position.clamp(inside.position, inside.end)
			telegraph.show_landing(landing_spot - zombie.position, _king.lunge_radius)
			manager.boss_telegraphed.emit(zombie, LUNGE)


## One volley of the spiral when it is due; the spiral turns all the time.
func _spiral_step(zombie: Zombie, manager: EnemyManager, delta: float) -> void:
	_spiral_angle += deg_to_rad(_king.spiral_turn_degrees) * delta
	_until_volley -= delta
	if _until_volley <= 0.0:
		_until_volley += 1.0 / maxf(_king.spiral_volleys_per_second, 0.1)
		var attack: SpitAttack = _king.spiral
		var damage: float = attack.bullet_damage * manager.damage_scale
		var aim: Vector2 = Vector2.from_angle(_spiral_angle)
		manager.fire_volley(zombie, aim, attack, attack.balls_in_volley(0), damage)
	if state_left <= 0.0:
		_back_to_walking()


## Where the summoned zombies appear: a ring around him, inside the arena.
func _ring_points(zombie: Zombie, manager: EnemyManager) -> Array[Vector2]:
	var inside: Rect2 = manager.play_rect.grow(-_king.summon_enemy.radius)
	var points: Array[Vector2] = []
	for i: int in _king.summon_count:
		var direction: Vector2 = Vector2.from_angle(TAU * i / _king.summon_count)
		var point: Vector2 = zombie.position + direction * _king.summon_radius
		points.append(point.clamp(inside.position, inside.end))
	return points


func _summon(zombie: Zombie, manager: EnemyManager) -> void:
	for point: Vector2 in summon_points:
		manager.spawn(_king.summon_enemy, point)
	manager.boss_attacked.emit(zombie, SUMMON)
	_back_to_walking()


func _take_off(zombie: Zombie, manager: EnemyManager) -> void:
	telegraph.clear()
	state = State.LUNGE
	state_left = _king.lunge_seconds
	_lunge_from = zombie.position
	_lifted = zombie.puppet
	manager.boss_attacked.emit(zombie, LUNGE)


## Flies to the landing spot in an arc and lands exactly on it.
func _lunge_step(zombie: Zombie, manager: EnemyManager, delta: float) -> Vector2:
	var flown: float = clampf(1.0 - state_left / maxf(_king.lunge_seconds, 0.001), 0.0, 1.0)
	_lifted.position.y = -sin(PI * flown) * _king.lunge_height
	var left: float = zombie.position.distance_to(landing_spot)
	if state_left <= 0.0 or left < 1.0:
		zombie.position = landing_spot
		_land(zombie, manager)
		return Vector2.ZERO
	var speed: float = _lunge_from.distance_to(landing_spot) / maxf(_king.lunge_seconds, 0.001)
	return zombie.position.direction_to(landing_spot) * minf(speed, left / maxf(delta, 0.0001))


func _land(zombie: Zombie, manager: EnemyManager) -> void:
	_lifted.position = Vector2.ZERO
	_lifted = null
	var damage: float = _king.lunge_damage * manager.damage_scale
	manager.hurt_players_near(landing_spot, _king.lunge_radius, damage, zombie.display_name)
	manager.boss_landed.emit(zombie)
	state = State.RECOVER
	state_left = _king.lunge_recover_seconds


func _back_to_walking() -> void:
	state = State.WALK
	pattern_cooldown = def.pattern_gap_seconds
	if telegraph != null:
		telegraph.clear()
	if _lifted != null and is_instance_valid(_lifted):
		_lifted.position = Vector2.ZERO
	_lifted = null
