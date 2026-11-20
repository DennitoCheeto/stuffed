class_name ChainPinProjectile
extends PinProjectile
## A Pincushion Volley pin (chain pins, spec 10 §3): when it kills a zombie, new pins fly out from
## where the zombie fell. Those are generation 1 and never chain again.

## 0 = fired by the weapon, 1 = fired from a fallen zombie.
var generation: int = 0
## Kills of this pin that may still start chains (`ChainPins.chains_per_pin`).
var chains_left: int = 0


func reset() -> void:
	super()
	generation = 0
	chains_left = 0


func launch(from: Weapon, direction: Vector2) -> void:
	super(from, direction)
	var chain: ChainPins = from.stats.chain_pins
	chains_left = chain.chains_per_pin if chain != null else 0


## A chained pin from `at` (where a zombie fell), shorter and softer than a volley pin.
func launch_chain(from: Weapon, at: Vector2, direction: Vector2) -> void:
	launch(from, direction)
	var chain: ChainPins = from.stats.chain_pins
	generation = 1
	chains_left = 0
	global_position = at
	reach *= chain.reach_share
	damage *= chain.damage_share


func hurt(zombie: Zombie, amount: float, push: Vector2) -> void:
	var at: Vector2 = zombie.global_position
	super(zombie, amount, push)
	if zombie.dead and chains_left > 0:
		chains_left -= 1
		_chain_from(at)


func _chain_from(at: Vector2) -> void:
	var chain: ChainPins = weapon.stats.chain_pins
	var heading: Vector2 = Vector2.from_angle(rotation)
	var spread: float = deg_to_rad(chain.spread_degrees)
	for i: int in chain.count:
		var offset: float = (i - (chain.count - 1) / 2.0) * spread
		var pin: ChainPinProjectile = manager.spawn(ChainPinProjectile) as ChainPinProjectile
		pin.launch_chain(weapon, at, heading.rotated(offset))
