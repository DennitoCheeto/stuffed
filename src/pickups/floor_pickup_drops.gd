class_name FloorPickupDrops
extends RefCounted
## Decides, zombie by zombie, whether a kill drops a floor pickup (spec 02b §4): never before
## the first drop time, never closer together than the minimum gap, never more than the allowed
## number on the floor.

var rules: FloorPickupRules
## Run time from which the next drop may come.
var next_drop_at: float = 0.0
## Run time of the last drop (-1 = none yet).
var last_drop_at: float = -1.0

var _rng: RandomNumberGenerator


func _init(drop_rules: FloorPickupRules, rng: RandomNumberGenerator) -> void:
	rules = drop_rules
	_rng = rng
	next_drop_at = rules.next_drop_time(0.0, _rng, true)


## A zombie died at run time `now` while `on_floor` pickups lie around: the kind it drops, or
## null for nothing.
func roll(now: float, on_floor: int) -> FloorPickupDef:
	if now < next_drop_at or on_floor >= rules.max_on_floor or rules.kinds.is_empty():
		return null
	if _rng.randf() >= rules.drop_chance:
		return null
	last_drop_at = now
	next_drop_at = rules.next_drop_time(now, _rng, false)
	return rules.pick(_rng)
