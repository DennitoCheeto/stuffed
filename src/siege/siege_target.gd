class_name SiegeTarget
extends RefCounted
## Something in the town the horde attacks in the night siege (spec 07 §4, §5): the pillow fort
## or a built building. It has a footprint, health, and zombies that touch it knock at it. At 0
## health it falls (the fort: the siege is lost; a building: knocked down, it stops fighting).
## `SiegeTargets` decides which one a zombie walks to.

## Health is gone.
signal fell
signal health_changed(health: float, max_health: float)

## A zombie this close to the walls (beyond its own radius) touches it.
const TOUCH_GAP: float = 8.0

## The footprint (blocks walking, zombies stand around it).
var rect: Rect2
var max_health: float = 1.0
var health: float = 1.0
## Share of a zombie's touch damage it takes per second.
var touch_rate: float = 1.0


func _init(target_rect: Rect2, health_points: float, rate: float) -> void:
	rect = target_rect
	max_health = maxf(health_points, 1.0)
	health = max_health
	touch_rate = rate


func is_fallen() -> bool:
	return health <= 0.0


## True while it has taken damage but still stands (its small health bar shows).
func is_hurt() -> bool:
	return health < max_health and not is_fallen()


## Pixels from `point` to the nearest point of its walls (0 inside).
func distance_to(point: Vector2) -> float:
	return TownLayout.distance_to(rect, point)


## Where `zombie` walks (pixels per second): to the nearest point of its walls.
func walk(zombie: Zombie) -> Vector2:
	if zombie.stun_left > 0.0:
		return Vector2.ZERO
	var goal: Vector2 = zombie.position.clamp(rect.position, rect.end)
	if goal.distance_squared_to(zombie.position) < 1.0:
		return Vector2.ZERO
	return zombie.position.direction_to(goal) * zombie.current_speed()


func is_touched_by(zombie: Zombie) -> bool:
	return distance_to(zombie.position) <= zombie.radius() + TOUCH_GAP


## A zombie touching it knocks at it for `delta` seconds.
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
