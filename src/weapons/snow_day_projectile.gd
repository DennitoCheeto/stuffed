class_name SnowDayProjectile
extends SnowballProjectile
## A Snow Day snowball (spec 10 §3): a bigger icy snowball that slows like Snowball Toss and builds
## a snowman where it lands.


func _ball_part() -> StringName:
	return ProjectileLook.SNOW_DAY_BALL


func _land() -> void:
	super()
	SnowmanProjectile.build_for(weapon, global_position)
