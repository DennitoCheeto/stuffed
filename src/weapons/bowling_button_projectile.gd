class_name BowlingButtonProjectile
extends ButtonProjectile
## One Bowling Buttons button (spec 11 §4.2): flies like a shotgun button; a zombie it hits and
## doesn't pop starts tumbling in the lane. It finds the lane by node name, so it never refers to
## the weapon's class (script cycles leak resources).


func hurt(zombie: Zombie, amount: float, push: Vector2) -> void:
	super(zombie, amount, push)
	if zombie.dead or weapon == null:
		return
	var lane: BowlingLane = weapon.get_node_or_null(NodePath(BowlingLane.NAME)) as BowlingLane
	if lane != null:
		lane.tumble(zombie, push)
