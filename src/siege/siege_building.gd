class_name SiegeBuilding
extends SiegeTarget
## A built town building in the night siege (spec 07 §4, AC-77): it has health (more per level,
## `BuildingLevel.siege_health`), zombies passing close by turn to attack it (`pull`), and at 0
## health it is knocked down for the rest of the siege. A bait building (the Lucky Jar,
## `BuildingLevel.siege_bait`) draws zombies from further away, even away from a hero.

var id: StringName
var level: int = 1
## True for bait: zombies within `pull` go for it before anything else.
var bait: bool = false


func _init(spot: TownSpot, building_level: int, rules: SiegeRules) -> void:
	var data: BuildingLevel = spot.building.levels[building_level - 1]
	super(spot.rect, data.siege_health, rules.building_touch_rate)
	id = spot.id
	level = building_level
	bait = data.siege_bait > 0.0
	pull = data.siege_bait if bait else rules.building_reach
