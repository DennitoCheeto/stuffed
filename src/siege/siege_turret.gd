class_name SiegeTurret
extends Node2D
## A building that fires on its own in the night siege (spec 07 §4, AC-78): the Toy Box Armory
## (the hero's starting weapon at Lv 1 / 3 / 5) and the Watchtower (strong pins at the toughest
## zombie). It holds one real `Weapon` with no hero (`Weapon.mount`): shots go through the
## run's ProjectileManager and count in the weapon tally under the building's own row. It stops
## for good when its building is knocked down. Numbers: `BuildingLevel.siege_weapon_level` /
## `siege_range`, `BuildingDef.siege_weapon`.

var building: SiegeBuilding
var weapon: Weapon


## Mounts `stats` at `level` on `target`, firing from `at` (world position).
func setup(
	target: SiegeBuilding, stats: WeaponStats, level: int, reach: float, at: Vector2
) -> void:
	building = target
	position = at
	name = "Turret_%s" % building.id
	weapon = stats.behaviour.new() as Weapon
	weapon.mount(stats, level, reach, building.id)
	add_child(weapon)
	building.fell.connect(stop)


## True while it still fires (its building stands and the siege goes on).
func is_firing() -> bool:
	return weapon.process_mode != Node.PROCESS_MODE_DISABLED


func stop() -> void:
	weapon.process_mode = Node.PROCESS_MODE_DISABLED
