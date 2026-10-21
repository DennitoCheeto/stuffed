class_name EnemyBullet
extends Projectile
## A zombie's stuffing ball: bright with a dark outline, the most readable thing on screen. Flies
## straight, hurts the first player it touches and is gone. A dashing player passes through it.
## It also vanishes at the end of its life or at the arena's edge.

var damage: float = 0.0
## Hit radius in pixels (the sprite is sized to match).
var radius: float = ProjectileLook.BULLET_RADIUS
## Shown on the end screen as what hit Banane last.
var source: String = ""
var velocity: Vector2 = Vector2.ZERO

var _life_left: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.BULLET)


func is_hostile() -> bool:
	return true


## Fires the bullet from `at` with `bullet_velocity` (pixels per second) for `lifetime` seconds.
func launch(
	at: Vector2,
	bullet_velocity: Vector2,
	hit_damage: float,
	hit_radius: float,
	lifetime: float,
	from_name: String
) -> void:
	position = at
	velocity = bullet_velocity
	damage = hit_damage
	radius = hit_radius
	_life_left = lifetime
	source = from_name
	ProjectileLook.apply(self, ProjectileLook.BULLET, radius / ProjectileLook.BULLET_RADIUS)


func advance(delta: float) -> bool:
	_life_left -= delta
	position += velocity * delta
	if _life_left <= 0.0 or not manager.play_rect.has_point(position):
		return false
	for player: Player in manager.targets:
		var reach: float = radius + player.stats.hitbox_radius
		if position.distance_squared_to(player.global_position) > reach * reach:
			continue
		if player.is_dashing():
			continue
		player.take_hit(damage, source)
		return false
	return true
