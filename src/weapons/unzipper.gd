class_name Unzipper
extends ZipperRay
## Evolved Zipper Ray (+ Long Thread, spec 11 §4.6): a harder, longer, longer-lasting beam that
## splits into two halves (`UnzipperProjectile`) sweeping apart to both sides like a zipper
## opening, then snapping shut; every zombie they swept over takes the zip-shut hit (`seam`).

var seam: ZipperSeam


func _ready() -> void:
	seam = ZipperSeam.new()
	seam.weapon = self
	add_child(seam)


## Never fires while the last beam is still out.
func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null or enemies() == null or not shots.fired_by(self).is_empty():
		return false
	seam.begin()
	for side: float in [-1.0, 1.0]:
		var half: UnzipperProjectile = shots.spawn(UnzipperProjectile) as UnzipperProjectile
		half.open(self, side)
	return true
