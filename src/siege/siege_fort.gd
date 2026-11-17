class_name SiegeFort
extends SiegeTarget
## The pillow fort in the night siege (spec 07 §2, §4): the heart of the town. Zombies walk to it
## when nothing else draws them (see `SiegeTargets`) and knock at it while they touch it. The
## siege is lost when its health is gone (`fell`).

## A zombie leaves its way for a hero closer than this (pixels).
var hero_reach: float = 0.0


func _init(fort_rect: Rect2, health_points: float, reach: float, rate: float) -> void:
	super(fort_rect, health_points, rate)
	hero_reach = reach


## True when `zombie` goes for `hero` (the nearest hero, may be null). A spitter also keeps
## going for a hero it can spit at from where it likes to stand.
func chases(zombie: Zombie, hero: Player) -> bool:
	if hero == null:
		return false
	var reach: float = hero_reach
	var attack: SpitAttack = zombie.attack
	if attack != null:
		reach = maxf(reach, attack.keep_distance + attack.distance_band * 2.0)
	return hero.global_position.distance_squared_to(zombie.position) <= reach * reach
