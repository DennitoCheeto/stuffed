class_name LassoLashProjectile
extends WhipProjectile
## One lash of Lasso Lash: hurts every zombie in its arc at once like a whip lash, in a bigger
## lilac thread with a lasso loop (its evolved look, with a glitter trail; the first lash after
## the evolution is drawn big).


func _part() -> StringName:
	return ProjectileLook.LASSO


func launch(from: Weapon, direction: Vector2) -> void:
	super(from, direction)
	dress(from)
