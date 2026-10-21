class_name BombProjectile
extends CannonProjectile
## A Yarn Bomb ball: bursts like a Yarn Cannon ball, then leaves sticky yarn where it burst.


func _burst() -> void:
	super()
	var yarn: StickyYarnProjectile = manager.spawn(StickyYarnProjectile) as StickyYarnProjectile
	yarn.launch(weapon, global_position)
