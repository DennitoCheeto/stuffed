class_name HopscotchMortar
extends ThimbleMortar
## Evolved Thimble Mortar (+ Big Spool, spec 11 §4.4): harder, bigger, faster lobs, and every
## thimble hops onward twice after landing (`HopscotchProjectile`), so each one clears a short
## line outwards through the crowd.


func _shot_kind() -> GDScript:
	return HopscotchProjectile
