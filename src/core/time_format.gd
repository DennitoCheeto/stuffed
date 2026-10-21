class_name TimeFormat
extends RefCounted
## Turns seconds into the clock text shown in the game.


## 0 -> "0:00", 192.7 -> "3:12", 3725 -> "62:05".
static func clock(seconds: float) -> String:
	var whole: int = maxi(floori(seconds), 0)
	return "%d:%02d" % [whole / 60, whole % 60]


## The run timer at the top of the screen: "3:12 / 5:00".
static func run_timer(elapsed: float, goal: float) -> String:
	return "%s / %s" % [clock(elapsed), clock(goal)]
