class_name FloorPickupDrops
extends RefCounted
## Decides, zombie by zombie, whether a kill drops a floor pickup (spec 02b §4): never before
## the first drop time, never closer together than the minimum gap, never more than the allowed
## number on the floor. The Party Shop (spec 03 §6) makes the gap shorter and can make the first
## drop come early.

var rules: FloorPickupRules
## Run time from which the next drop may come.
var next_drop_at: float = 0.0
## Run time of the last drop (-1 = none yet).
var last_drop_at: float = -1.0
## How much shorter the wait between drops is, as a share (0.15 = 15%, Party Shop).
var gap_cut: float = 0.0

var _rng: RandomNumberGenerator


## `first_at` > 0: the first drop is due at that run time instead of the normal first drop time.
func _init(
	drop_rules: FloorPickupRules,
	rng: RandomNumberGenerator,
	cut: float = 0.0,
	first_at: float = 0.0
) -> void:
	rules = drop_rules
	_rng = rng
	gap_cut = cut
	if first_at > 0.0:
		next_drop_at = first_at
	else:
		next_drop_at = rules.next_drop_time(0.0, _rng, true, gap_cut)


## A zombie died at run time `now` while `on_floor` pickups lie around: the kind it drops, or
## null for nothing.
func roll(now: float, on_floor: int) -> FloorPickupDef:
	if now < next_drop_at or on_floor >= rules.max_on_floor or rules.kinds.is_empty():
		return null
	if _rng.randf() >= rules.drop_chance:
		return null
	last_drop_at = now
	next_drop_at = rules.next_drop_time(now, _rng, false, gap_cut)
	return rules.pick(_rng)
