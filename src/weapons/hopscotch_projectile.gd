class_name HopscotchProjectile
extends ThimbleProjectile
## One Hopscotch Mortar thimble (spec 11 §4.4): lobbed like a mortar thimble, then on every landing
## (a full blast) it hops onward in the direction it was flying, away from the hero, until it has
## hopped `HopscotchHops.hops` times; the last blast is bigger. Each hop is a fresh shot from the
## pool whose ring already sits on the next landing spot and fills in while it is in the air.

## Landings before this one: 0 = the throw from the hero, 1, 2 ... = the hops.
var hop: int = 0

var _direction: Vector2 = Vector2.RIGHT


func reset() -> void:
	super()
	hop = 0
	_direction = Vector2.RIGHT


func launch(from: Weapon, target: Vector2) -> void:
	hop = 0
	super(from, target)
	var away: Vector2 = from.origin().direction_to(target)
	_direction = away if away != Vector2.ZERO else Vector2.RIGHT


## A hop: from `start` onward along `direction`, landing number `index` (1 = the first hop).
func hop_from(from: Weapon, start: Vector2, direction: Vector2, index: int) -> void:
	hop = index
	var hops: HopscotchHops = from.stats.hopscotch
	var target: Vector2 = _inside(start + direction * hops.hop_distance)
	super.launch(from, target)
	_direction = direction
	_from = start
	_flight_time = hops.hop_seconds
	_place(0.0)


## Hops still to come after this landing.
func hops_left() -> int:
	var hops: HopscotchHops = _hops()
	return maxi(hops.hops - hop, 0) if hops != null else 0


## The way it hops on (away from the hero).
func direction() -> Vector2:
	return _direction


func blast_radius() -> float:
	var radius: float = super()
	var hops: HopscotchHops = _hops()
	if hops != null and hop >= hops.hops:
		radius *= hops.last_blast_scale
	return radius


func _ball_part() -> StringName:
	return ProjectileLook.HOPSCOTCH_THIMBLE


func _place(progress: float) -> void:
	super(progress)
	var look: ShotLook = weapon.stats.shot_look if weapon != null else null
	if look != null:
		_thimble.scale *= look.size


func _land() -> void:
	super()
	if hops_left() <= 0:
		return
	var next: HopscotchProjectile = manager.spawn(get_script()) as HopscotchProjectile
	next.hop_from(weapon, global_position, _direction, hop + 1)


func _hops() -> HopscotchHops:
	return weapon.stats.hopscotch if weapon != null and weapon.stats != null else null


## `at`, kept inside the room's walls.
func _inside(at: Vector2) -> Vector2:
	var walls: Rect2 = manager.play_rect
	if walls.size == Vector2.ZERO:
		return at
	return at.clamp(walls.position, walls.end)
