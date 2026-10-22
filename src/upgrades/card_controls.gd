class_name CardControls
extends RefCounted
## One player's control over bad luck on the level-up screen for one run: rerolls, skips,
## banishes left, and the cards they banished. The starting counts come from the upgrade pool.

var rerolls_left: int = 0
var skips_left: int = 0
var banishes_left: int = 0
## Upgrade ids that are never offered again this run.
var banished: Array[StringName] = []
## How many were used this run (for the run log; a developer-menu refill doesn't reset them).
var rerolls_used: int = 0
var skips_used: int = 0
var banishes_used: int = 0

var _pool: UpgradePool


func _init(pool: UpgradePool) -> void:
	_pool = pool
	refill()


## Back to the starting counts from the pool (developer menu). Banished cards stay banished.
func refill() -> void:
	rerolls_left = _pool.rerolls_per_run
	skips_left = _pool.skips_per_run
	banishes_left = _pool.banishes_per_run


## The starting counts for a run (the most dots on the level-up buttons).
func max_rerolls() -> int:
	return _pool.rerolls_per_run


func max_skips() -> int:
	return _pool.skips_per_run


func max_banishes() -> int:
	return _pool.banishes_per_run


## Uses one reroll. False (and nothing used) when none are left.
func use_reroll() -> bool:
	if rerolls_left <= 0:
		return false
	rerolls_left -= 1
	rerolls_used += 1
	return true


## Uses one skip. False (and nothing used) when none are left.
func use_skip() -> bool:
	if skips_left <= 0:
		return false
	skips_left -= 1
	skips_used += 1
	return true


## Banishes upgrade `id` for the rest of the run. False (and nothing used) when no banishes are
## left or it is already banished.
func banish(id: StringName) -> bool:
	if banishes_left <= 0 or banished.has(id):
		return false
	banishes_left -= 1
	banishes_used += 1
	banished.append(id)
	return true
