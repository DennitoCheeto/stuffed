class_name LassoLash
extends ThreadWhip
## Evolved Thread Whip (+ Sharp Scissors, spec 11 §4.5): harder, longer lashes, and every few
## lashes the front one ropes the toughest zombie in its arc, swings it through the crowd and
## flings it towards the cursor (`rope`, a `LassoRope`).

var rope: LassoRope
## Lashes since the last lasso.
var lashes: int = 0


func _ready() -> void:
	rope = LassoRope.new()
	rope.weapon = self
	add_child(rope)


## Lashes like the whip; every `LassoThrow.every_lashes` lashes the front one also ropes (if the
## lasso is free; otherwise the next lash tries again).
func attack() -> bool:
	if not super():
		return false
	lashes += 1
	var lasso: LassoThrow = stats.lasso_throw
	if lasso != null and lashes >= lasso.every_lashes and not rope.is_busy():
		lashes = 0
		rope.rope_in(_aim())
	return true


func _shot_kind() -> GDScript:
	return LassoLashProjectile
