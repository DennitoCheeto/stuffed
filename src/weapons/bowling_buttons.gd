class_name BowlingButtons
extends ButtonShotgun
## Evolved Button Shotgun (+ Quick Hands, spec 11 §4.2): more buttons, harder, more often, and
## zombie bowling: a zombie a button knocks back tumbles and knocks over the zombies it bumps into
## (`lane`).

var lane: BowlingLane


func _ready() -> void:
	lane = BowlingLane.new()
	lane.weapon = self
	add_child(lane)


func _button_kind() -> GDScript:
	return BowlingButtonProjectile
