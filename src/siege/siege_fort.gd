class_name SiegeFort
extends RefCounted
## The pillow fort in the night siege (spec 07 §2, §4): the heart of the town. Zombies walk to it
## when no hero is close and knock at it while they touch it. The siege is lost when its health
## is gone. The EnemyManager asks it where zombies go (`chases`, `walk`, `touch`).

## The fort fell: the siege is lost.
signal fell
signal health_changed(health: float, max_health: float)

## A zombie this close to the fort's walls (beyond its own radius) touches it.
const TOUCH_GAP: float = 8.0

## The fort's footprint (blocks walking, zombies stand around it).
var rect: Rect2
var max_health: float = 1.0
var health: float = 1.0
## A zombie leaves the way to the fort for a hero closer than this (pixels).
var hero_reach: float = 0.0
## Share of a zombie's touch damage the fort takes per second.
var touch_rate: float = 1.0


func _init(fort_rect: Rect2, health_points: float, reach: float, rate: float) -> void:
	rect = fort_rect
	max_health = maxf(health_points, 1.0)
	health = max_health
	hero_reach = reach
	touch_rate = rate


func is_fallen() -> bool:
	return health <= 0.0


## True when `zombie` goes for `hero` (the nearest hero, may be null) instead of the fort. A
## spitter also keeps going for a hero it can spit at from where it likes to stand.
func chases(zombie: Zombie, hero: Player) -> bool:
	if hero == null:
		return false
	var reach: float = hero_reach
	var attack: SpitAttack = zombie.attack
	if attack != null:
		reach = maxf(reach, attack.keep_distance + attack.distance_band * 2.0)
	return hero.global_position.distance_squared_to(zombie.position) <= reach * reach


## Where `zombie` walks (pixels per second): to the nearest point of the fort's walls.
func walk(zombie: Zombie) -> Vector2:
	if zombie.stun_left > 0.0:
		return Vector2.ZERO
	var goal: Vector2 = zombie.position.clamp(rect.position, rect.end)
	if goal.distance_squared_to(zombie.position) < 1.0:
		return Vector2.ZERO
	return zombie.position.direction_to(goal) * zombie.current_speed()


func is_touched_by(zombie: Zombie) -> bool:
	return TownLayout.distance_to(rect, zombie.position) <= zombie.radius() + TOUCH_GAP


## A zombie touching the fort knocks at it for `delta` seconds.
func touch(zombie: Zombie, delta: float) -> void:
	if not is_fallen() and is_touched_by(zombie):
		hurt(zombie.contact_damage * touch_rate * delta)


func hurt(amount: float) -> void:
	if is_fallen() or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if is_fallen():
		fell.emit()


func share() -> float:
	return health / max_health
