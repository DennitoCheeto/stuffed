class_name SparkleProjectile
extends Projectile
## The hit flash of an evolved weapon's shot: a soft felt star that pops open and fades where a
## zombie was hit. Only a look, it hurts nothing. Size, colour and time come from the ShotLook.

## How big it starts, as a share of its full size.
const START_SIZE: float = 0.5

var _color: Color = Color.WHITE
var _full_scale: Vector2 = Vector2.ONE
var _seconds: float = 0.2
var _age: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.SPARKLE)
	_full_scale = scale


func reset() -> void:
	super()
	_age = 0.0


## Pops open at `at` in the look of `shot`.
func launch(shot: Projectile, at: Vector2) -> void:
	weapon = shot.weapon
	global_position = at
	rotation = randf() * TAU
	_color = shot.look.flash_color
	_seconds = maxf(shot.look.flash_seconds, 0.01)
	var share: float = shot.look.flash_radius / ProjectileLook.SPARKLE_RADIUS
	_full_scale = Vector2.ONE * _unit_scale() * share
	_show(0.0)


## On-screen radius right now.
func radius() -> float:
	return scale.x / _unit_scale() * ProjectileLook.SPARKLE_RADIUS


func advance(delta: float) -> bool:
	_age += delta
	var done: float = _age / _seconds
	_show(minf(done, 1.0))
	return done < 1.0


func _show(done: float) -> void:
	scale = _full_scale * lerpf(START_SIZE, 1.0, sqrt(done))
	modulate = Color(_color, _color.a * (1.0 - done))


## The scale at which a part shows at its on-screen size.
static func _unit_scale() -> float:
	return ProjectileLook.DRAW_SCALE / FeltAtlas.BAKE_SCALE
