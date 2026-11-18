class_name StuffingBall
extends PinProjectile
## A plushie's stuffing ball in the night siege (spec 07 §4): a small puff of stuffing (the
## Stuffing Cloud's felt part, drawn small) that flies straight at a zombie like a pin and pops
## on the first one it hits. Soft cream, never enemy danger.

## The cloud part is drawn this share of its size (a ball ~16 px across).
const SIZE: float = 0.2
const SPIN_SPEED: float = 9.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.CLOUD, SIZE)


func advance(delta: float) -> bool:
	var flying: bool = super(delta)
	rotation += SPIN_SPEED * delta
	return flying
