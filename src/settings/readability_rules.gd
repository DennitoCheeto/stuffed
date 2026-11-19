class_name ReadabilityRules
extends Resource
## The numbers behind the Readability tab (spec 10 §5), in data/ui/readability.tres (hard rule 8).

## How strong the hero's white hit flash still is with Flashes off (1 = full).
@export_range(0.0, 1.0) var hero_flash_soft: float = 0.45
## Own effects can be turned down to this opacity, never lower (your shots must stay visible).
@export_range(0.0, 1.0) var own_effects_min: float = 0.5
## Slider steps.
@export var shake_step: float = 0.1
@export var own_effects_step: float = 0.05
