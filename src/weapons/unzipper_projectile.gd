class_name UnzipperProjectile
extends BeamProjectile
## One half of Unzipper's beam (spec 11 §4.6): a zipper beam towards the cursor that swings
## `side` (-1 or 1) away from the middle, up to `ZipperSweep.open_degrees` over most of the beam's
## time, then snaps back. It hurts like a Zipper Ray beam and tells the weapon's `ZipperSeam`
## every zombie it sweeps over; the right half (`side` 1) zips the seam shut at the end.

## -1 = the half opening to the left of the aim, 1 = to the right.
var side: float = 1.0

var _length: float = 0.0


func reset() -> void:
	super()
	side = 1.0
	_length = 0.0


## Fires the `towards` half (-1 or 1) of `from`'s beam.
func open(from: Weapon, towards: float) -> void:
	side = towards
	_length = from.current().duration
	launch(from)
	# Bigger = a thicker zipper; the length stays the beam's reach (undone before `dress`, so the
	# big first attack after the evolution eases back to the right length too).
	var own: ShotLook = from.stats.shot_look
	if own != null and own.size > 0.0:
		scale.x /= own.size
	dress(from)


## How far this half has swung off the middle right now, in radians (0 at the start and end).
func spread_angle() -> float:
	var sweep_rules: ZipperSweep = weapon.stats.zipper_sweep if weapon != null else null
	if sweep_rules == null or _length <= 0.0:
		return 0.0
	var share: float = clampf(1.0 - time_left() / _length, 0.0, 1.0)
	var open: float = clampf(sweep_rules.open_share, 0.01, 0.99)
	var amount: float
	if share < open:
		amount = ease(share / open, 0.5)
	else:
		amount = 1.0 - (share - open) / (1.0 - open)
	return deg_to_rad(sweep_rules.open_degrees) * clampf(amount, 0.0, 1.0)


func advance(delta: float) -> bool:
	if super(delta):
		return true
	if side > 0.0:
		var seam: ZipperSeam = _seam()
		if seam != null:
			var middle: Vector2 = weapon.origin().direction_to(weapon.aim_point())
			if middle == Vector2.ZERO:
				middle = weapon.facing()
			seam.zip_shut(weapon.origin(), weapon.origin() + middle * weapon.current().reach)
	return false


func _touched(zombie: Zombie) -> void:
	var seam: ZipperSeam = _seam()
	if seam != null:
		seam.sweep(zombie)


func _aim() -> void:
	super()
	rotation += side * spread_angle()


func _seam() -> ZipperSeam:
	if weapon == null or not is_instance_valid(weapon):
		return null
	return weapon.get_node_or_null(NodePath(ZipperSeam.NAME)) as ZipperSeam
