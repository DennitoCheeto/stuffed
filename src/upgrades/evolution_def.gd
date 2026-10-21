class_name EvolutionDef
extends Resource
## One evolution (spec 02 §5): a weapon at its top level plus its partner item turns into a
## stronger weapon at the next gift box. Tune it in data/upgrade_pool.tres and the evolved
## weapon's data/weapons/*.tres, not in code.

## The weapon that evolves (its id).
@export var weapon: StringName = &""
## The item that must be owned (any level) for it to evolve (its id).
@export var partner: StringName = &""
## What it becomes: a weapon with a single level.
@export var evolved: WeaponStats
## Which felt icon the HUD and the Recipes page show for the evolved weapon.
@export var icon: StringName = &""
## One line on what changes (Recipes page, gift box).
@export var card_text: String = ""


func display_name() -> String:
	return evolved.display_name
