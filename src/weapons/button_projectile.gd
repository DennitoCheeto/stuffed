class_name ButtonProjectile
extends PinProjectile
## One shotgun button: flies straight like a pin (same reach and pierce rules), spinning.

const SPIN_SPEED: float = 12.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.BUTTON)


func advance(delta: float) -> bool:
	var flying: bool = super(delta)
	rotation += SPIN_SPEED * delta
	return flying
