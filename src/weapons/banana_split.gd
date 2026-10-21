class_name BananaSplit
extends PeelBoomerang
## Evolved Peel Boomerang (+ Quick Feet): thrown like the boomerang, but on the way back every
## peel splits into three that all fly home, hitting again (spec 02 §5).


func _peel_kind() -> GDScript:
	return SplitPeelProjectile
