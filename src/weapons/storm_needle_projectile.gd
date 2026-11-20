class_name StormNeedleProjectile
extends Projectile
## One needle of the Sewing Storm: circles its player for as long as the weapon exists. When
## flung it swings out to the weapon's area and back within the weapon's duration. Hurts each
## zombie it touches, the same zombie again only after the weapon's hit interval.
## Stitch-up (spec 10 §3): a flung needle trails thread through the zombies it hits; after
## `StitchUp.pull_delay` the thread pulls tight, dragging them towards the hero and hitting them
## again, then whips back to the hero (`SewingStorm` draws all threads).

## Angle around the player, in radians.
var angle: float = 0.0
## Distance from the player right now.
var radius: float = 0.0
## True while it swings outward and back.
var flinging: bool = false
## Zombies this fling's thread passed through (yanked in on the snap).
var stitched: Array[Zombie] = []
## Times the thread snapped (for tests).
var snaps: int = 0

var _fling_time: float = 0.0
## Zombie instance id → seconds until this needle may hurt it again.
var _cooldowns: Dictionary[int, float] = {}
## The thread behind the needle (world points, oldest first).
var _thread: PackedVector2Array = []
## Seconds since the thread started (-1 = no thread is being sewn).
var _stitch_time: float = -1.0
## Seconds left of the snapped thread whipping back to the hero.
var _snap_left: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.NEEDLE)


func reset() -> void:
	super()
	flinging = false
	_fling_time = 0.0
	_cooldowns.clear()
	stitched.clear()
	snaps = 0
	_thread.clear()
	_stitch_time = -1.0
	_snap_left = 0.0


func launch(from: Weapon, start_angle: float) -> void:
	weapon = from
	angle = start_angle
	radius = from.current().reach
	size_to(from.area_scale())
	_place()
	dress(from)


## Swings out to the weapon's area and back (and sews a thread on the way).
func fling() -> void:
	flinging = true
	_fling_time = 0.0
	if weapon.stats.stitch_up != null:
		stitched.clear()
		_thread = PackedVector2Array([global_position])
		_stitch_time = 0.0
		_snap_left = 0.0


## True while a thread trails behind it (not yet snapped).
func is_sewing() -> bool:
	return _stitch_time >= 0.0


## The thread to draw right now: its path while sewing, pulled towards the hero while snapping,
## empty otherwise.
func thread_points() -> PackedVector2Array:
	if is_sewing():
		var points: PackedVector2Array = _thread.duplicate()
		points.append(global_position)
		return points
	if _snap_left <= 0.0:
		return PackedVector2Array()
	var stitch: StitchUp = weapon.stats.stitch_up
	var pulled: float = 1.0 - _snap_left / maxf(stitch.snap_seconds, 0.001)
	var home: Vector2 = weapon.origin()
	var points: PackedVector2Array = []
	for point: Vector2 in _thread:
		points.append(point.lerp(home, pulled))
	return points


func advance(delta: float) -> bool:
	# The storm lasts all run: read the numbers every frame, so new items apply at once.
	var numbers: WeaponLevel = weapon.current()
	radius = numbers.reach
	if flinging:
		_fling_time += delta
		var progress: float = _fling_time / maxf(numbers.duration, 0.01)
		if progress >= 1.0:
			flinging = false
		else:
			radius = lerpf(numbers.reach, maxf(numbers.area, numbers.reach), sin(progress * PI))
	angle = wrapf(angle + numbers.speed / maxf(radius, 1.0) * delta, 0.0, TAU)
	_place()
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var push: Vector2 = Vector2.from_angle(angle) * weapon.stats.knockback
	for zombie: Zombie in manager.enemies.query_circle(global_position, weapon.hit_radius()):
		var id: int = zombie.get_instance_id()
		if _cooldowns.has(id):
			continue
		_cooldowns[id] = weapon.stats.hit_interval
		if is_sewing() and not stitched.has(zombie):
			stitched.append(zombie)
		hurt(zombie, numbers.damage, push)
	_sew(delta)
	return true


## Lays the thread behind the needle and pulls it tight when it's time.
func _sew(delta: float) -> void:
	if _snap_left > 0.0:
		_snap_left -= delta
		if _snap_left <= 0.0:
			_thread.clear()
	if not is_sewing():
		return
	var stitch: StitchUp = weapon.stats.stitch_up
	_stitch_time += delta
	if _thread[_thread.size() - 1].distance_to(global_position) >= stitch.point_gap:
		_thread.append(global_position)
	if _stitch_time >= stitch.pull_delay:
		_snap(stitch)


## The thread pulls tight: every stitched zombie is dragged towards the hero and hit again.
func _snap(stitch: StitchUp) -> void:
	_thread.append(global_position)
	_stitch_time = -1.0
	_snap_left = stitch.snap_seconds
	snaps += 1
	var home: Vector2 = weapon.origin()
	var damage: float = stitch.snap_damage * weapon.damage_scale()
	var yanked: bool = false
	for zombie: Zombie in stitched:
		if not is_instance_valid(zombie) or zombie.dead:
			continue
		hurt(zombie, damage, zombie.global_position.direction_to(home) * stitch.pull)
		yanked = true
	stitched.clear()
	if yanked:
		Sfx.play(weapon.stats.sound, stitch.snap_pitch)


func _place() -> void:
	global_position = weapon.origin() + Vector2.from_angle(angle) * radius
	rotation = angle + PI / 2.0
