class_name EnemyCloud
extends Projectile
## The stuffing cloud a bloater bursts into: it sits still, hurts any player inside it (a dashing
## player passes through) and fades away. Drawn on the enemy-bullet layer with a bright, dark-edged
## rim exactly at its hit radius, so you always see where it is safe (spec 02 §8).

## How long it takes to puff out to full size.
const GROW_SECONDS: float = 0.15
## It fades out over its last seconds (and still hurts until it is gone).
const FADE_SECONDS: float = 0.4

var damage: float = 0.0
var radius: float = ProjectileLook.HAZARD_RADIUS
## Shown on the end screen as what hit Banane last.
var source: String = ""

var _duration: float = 0.0
var _age: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.HAZARD)


func is_hostile() -> bool:
	return true


## Puts a cloud of `hit_radius` pixels at `at` for `lifetime` seconds.
func launch(
	at: Vector2, hit_radius: float, lifetime: float, hit_damage: float, from_name: String
) -> void:
	position = at
	radius = hit_radius
	_duration = lifetime
	_age = 0.0
	damage = hit_damage
	source = from_name
	modulate = Color.WHITE
	_show_size(0.0)


func advance(delta: float) -> bool:
	_age += delta
	if _age >= _duration:
		return false
	if _age <= GROW_SECONDS + delta:
		_show_size(minf(_age / GROW_SECONDS, 1.0))
	modulate.a = clampf((_duration - _age) / FADE_SECONDS, 0.0, 1.0)
	for player: Player in manager.targets:
		var reach: float = radius + player.stats.hitbox_radius
		if position.distance_squared_to(player.global_position) <= reach * reach:
			player.take_hit(damage, source)
	return true


## Seconds left before it is gone.
func time_left() -> float:
	return maxf(_duration - _age, 0.0)


func _show_size(grown: float) -> void:
	var factor: float = radius / ProjectileLook.HAZARD_RADIUS * lerpf(0.6, 1.0, grown)
	ProjectileLook.apply(self, ProjectileLook.HAZARD, factor)
