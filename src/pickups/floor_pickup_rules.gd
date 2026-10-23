class_name FloorPickupRules
extends Resource
## When zombies drop floor pickups and which kind (spec 02b §4).
## Tune it in data/floor_pickup_rules.tres, not in code.

## Every kind that can drop, with its odds.
@export var kinds: Array[FloorPickupDef] = []
## Nothing drops before this run time (seconds).
@export var first_drop_after: float = 30.0
## After a drop, the next one can't come sooner than this (seconds) ...
@export var min_gap: float = 45.0
## ... plus a random extra of up to this many seconds (so about one per minute on average).
@export var gap_spread: float = 30.0
## Once a drop is due, each killed zombie drops it with this chance (0.25 = one in four).
@export var drop_chance: float = 0.25
## While this many lie on the floor, nothing new drops.
@export var max_on_floor: int = 2
## A player this close (plus their hitbox) grabs it.
@export var touch_radius: float = 22.0
## How long the name banner stays up.
@export var banner_seconds: float = 1.8
## Snow Globe: how long the horde stays frozen (seconds).
@export var freeze_seconds: float = 5.0
## Snow Globe: in the last this-many seconds the ice cracks and the zombies shake.
@export var freeze_crack_seconds: float = 1.0
## Snow Globe: bosses aren't frozen, they move at this share of their speed (0.5 = half).
@export var freeze_boss_speed: float = 0.5
## Party Popper: elites on screen lose this share of their full health (0.4 = 40 %).
@export var popper_elite_share: float = 0.4
## Party Popper: bosses on screen lose this share of their full health (a small hit).
@export var popper_boss_share: float = 0.05
## Party Popper: how long the confetti flies (seconds; looks only).
@export var popper_seconds: float = 1.4


## The kind with this id, or null.
func find(id: StringName) -> FloorPickupDef:
	for kind: FloorPickupDef in kinds:
		if kind.id == id:
			return kind
	return null


## A random kind, following the weights.
func pick(rng: RandomNumberGenerator) -> FloorPickupDef:
	var total: float = 0.0
	for kind: FloorPickupDef in kinds:
		total += kind.weight
	var roll_at: float = rng.randf() * total
	for kind: FloorPickupDef in kinds:
		roll_at -= kind.weight
		if roll_at < 0.0:
			return kind
	return kinds[kinds.size() - 1]


## Run time when the next drop may come, after one at `last_drop` (or the run start). The wait
## between drops gets `gap_cut` shorter (0.15 = 15%, Party Shop).
func next_drop_time(
	last_drop: float, rng: RandomNumberGenerator, first: bool, gap_cut: float = 0.0
) -> float:
	var keep: float = clampf(1.0 - gap_cut, 0.0, 1.0)
	var earliest: float = first_drop_after if first else last_drop + min_gap * keep
	return earliest + rng.randf() * gap_spread * keep
