class_name UnhurtClock
extends RefCounted
## How long each hero went without taking damage (for the "Untouchable!" run title).

## The longest finished stretch so far, in seconds.
var longest: float = 0.0
## Player index -> run time of their last hit (or when they joined).
var _since: Dictionary[int, float] = {}


func start(player: int, now: float) -> void:
	_since[player] = now


func hurt(player: int, now: float) -> void:
	longest = maxf(longest, now - _since.get(player, now))
	_since[player] = now


## The longest stretch at run time `now`, counting the running stretch of the heroes in `standing`.
func longest_at(now: float, standing: Array[int]) -> float:
	var best: float = longest
	for player: int in standing:
		best = maxf(best, now - _since.get(player, now))
	return best
