class_name Projectile
extends Sprite2D
## One shot in flight: a player's projectile or an enemy bullet. Shots don't move themselves: the
## ProjectileManager moves all of them in one loop and reuses finished ones (a pool), because
## hundreds of nodes that each run their own physics callback, or that are created and freed for
## every shot, cost a lot. Shots are sprites from the FeltAtlas (no shapes drawn per frame).
## Evolved weapons dress their shots in their own look (`dress`): another felt part, bigger, a
## glitter trail, and a sparkle pop on every hit (`hurt`).

## The weapon that fired it (null for enemy bullets). Its shots vanish if the weapon goes away.
var weapon: Weapon
var manager: ProjectileManager
## The evolved look this shot wears right now (null = its normal look).
var look: ShotLook
## Glitter specks behind an evolved shot (made the first time one is dressed).
var trail: CPUParticles2D

var _look_scale: Vector2 = Vector2.ZERO
var _plain_region: Rect2 = Rect2()
var _plain_offset: Vector2 = Vector2.ZERO


## Enemy bullets are drawn above everything and hurt players instead of zombies.
func is_hostile() -> bool:
	return false


## Called each time the shot is taken from the pool: forget everything from its last flight.
func reset() -> void:
	weapon = null
	rotation = 0.0
	if look != null:
		region_rect = _plain_region
		offset = _plain_offset
		look = null
	if trail != null:
		trail.emitting = false
		trail.restart()
		trail.emitting = false


## Draws the shot `factor` times its normal size (Big Spool).
func size_to(factor: float) -> void:
	if _look_scale == Vector2.ZERO:
		_look_scale = scale
	scale = _look_scale * factor


## Puts on `from`'s evolved look, if it has one. Call it at the end of `launch`.
func dress(from: Weapon) -> void:
	var own: ShotLook = from.stats.shot_look
	if own == null:
		return
	if look == null:
		_plain_region = region_rect
		_plain_offset = offset
	look = own
	FeltAtlas.swap_part(self, own.part)
	scale *= own.size
	_start_trail()


## Hurts `zombie` like `EnemyManager.damage`; an evolved shot also leaves a sparkle pop there.
func hurt(zombie: Zombie, amount: float, push: Vector2) -> void:
	var at: Vector2 = zombie.global_position
	manager.enemies.damage(zombie, amount, push)
	if look != null and look.flash_radius > 0.0:
		var pop: SparkleProjectile = manager.spawn(SparkleProjectile) as SparkleProjectile
		pop.launch(self, at)


## Moves the shot by one physics frame. Returns false when it is done (back to the pool).
func advance(_delta: float) -> bool:
	return false


func _start_trail() -> void:
	if look.trail_amount <= 0:
		return
	if trail == null:
		trail = CPUParticles2D.new()
		trail.local_coords = false
		trail.show_behind_parent = true
		trail.texture = FeltAtlas.part_texture(ProjectileLook.GLITTER)
		trail.spread = 180.0
		trail.gravity = Vector2.ZERO
		trail.initial_velocity_min = 8.0
		trail.initial_velocity_max = 30.0
		trail.angular_velocity_min = -200.0
		trail.angular_velocity_max = 200.0
		trail.color_ramp = _fade()
		add_child(trail)
	# Specks are drawn at their on-screen size whatever the shot's own scale is.
	var speck: float = ProjectileLook.DRAW_SCALE / FeltAtlas.BAKE_SCALE
	trail.scale_amount_min = speck * 0.6
	trail.scale_amount_max = speck * 1.1
	trail.amount = look.trail_amount
	trail.lifetime = look.trail_seconds
	trail.color = look.trail_color
	trail.restart()
	trail.emitting = true


static func _fade() -> Gradient:
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	return fade
