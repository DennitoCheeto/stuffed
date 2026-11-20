class_name BearPawProjectile
extends PawProjectile
## One swipe of Bear Slam: like Paw Swat's, in a bigger honey-cream paw (its evolved look, with a
## glitter trail; the first swipe after the evolution is drawn big).


func _part() -> StringName:
	return ProjectileLook.BEAR_PAW


func launch(from: Weapon, direction: Vector2) -> void:
	super(from, direction)
	dress(from)
