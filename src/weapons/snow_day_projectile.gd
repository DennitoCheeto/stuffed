class_name SnowDayProjectile
extends SnowballProjectile
## A Snow Day snowball (spec 10 §3): a bigger icy snowball (its evolved look's part and size) that
## slows like Snowball Toss and builds a snowman where it lands. The ring on the floor stays the
## mortar's: only the flying ball wears the look.


func _ball_part() -> StringName:
	return ProjectileLook.SNOW_DAY_BALL


func _place(progress: float) -> void:
	super(progress)
	var look: ShotLook = weapon.stats.shot_look
	if look != null:
		_thimble.scale *= look.size


func _land() -> void:
	super()
	SnowmanProjectile.build_for(weapon, global_position)
