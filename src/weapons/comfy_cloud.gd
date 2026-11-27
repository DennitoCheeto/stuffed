class_name ComfyCloud
extends StuffingCloud
## Evolved Stuffing Cloud (+ Extra Stuffing, spec 11 §4.3): a bigger, harder cloud that leaves a
## trail of fluff puffs while its hero walks (`trail`). The puffs hurt on the cloud's beat, and
## every zombie the cloud or a puff pops mends the cloud's own hero a little.

var trail: FluffTrail


func _ready() -> void:
	trail = FluffTrail.new()
	trail.weapon = self
	add_child(trail)


func attack() -> bool:
	var puffed: bool = super()
	if puffed:
		trail.hurt_all()
	return puffed
