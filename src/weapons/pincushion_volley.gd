class_name PincushionVolley
extends SewingPinSniper
## Evolved Sewing Pin Sniper (+ Sharp Scissors): a fan of pins that pierce everything (spec 02
## §5); a zombie a pin kills fires new pins from where it fell (chain pins, spec 10 §3).


func _pin_kind() -> GDScript:
	return ChainPinProjectile
