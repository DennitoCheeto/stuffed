class_name CloudProjectile
extends Projectile
## The Stuffing Cloud's look: a soft, see-through cloud that follows its player, sized to the
## weapon's area, swelling a little with each puff. It deals no damage itself (the weapon does).

const TURN_SPEED: float = 0.4
## How much bigger the cloud gets on a puff, and how fast it settles again.
const PUFF_SWELL: float = 0.1
const PUFF_SETTLE: float = 6.0
## Quiet: the player's own effects stay softer than enemy danger (vision §6.1).
const OPACITY: float = 0.4

var _base_scale: Vector2 = Vector2.ONE
var _swell: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.CLOUD)
	_base_scale = scale
	modulate.a = OPACITY


func reset() -> void:
	super()
	_swell = 0.0


func launch(from: Weapon) -> void:
	weapon = from
	_follow()


func puff() -> void:
	_swell = PUFF_SWELL


func advance(delta: float) -> bool:
	_swell = move_toward(_swell, 0.0, PUFF_SWELL * PUFF_SETTLE * delta)
	rotation += TURN_SPEED * delta
	_follow()
	return true


## On-screen radius of the cloud right now (without the puff swell).
func radius() -> float:
	return weapon.current().area


func _follow() -> void:
	global_position = weapon.player.global_position
	var factor: float = radius() / ProjectileLook.CLOUD_RADIUS
	scale = _base_scale * factor * (1.0 + _swell)
