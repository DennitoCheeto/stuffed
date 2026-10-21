class_name EliteRules
extends Resource
## What makes a zombie an elite (spec 02 §8): bigger, a gold patch and a crown of stitches, much
## more health, and one telegraphed attack. Every elite drops a gift box.
## Tune it in data/elite_rules.tres, not in code.

## Shown on the end screen as what hit Banane, e.g. "Elite Shambler".
@export var name_prefix: String = "Elite "
## Health compared to the normal zombie of its type.
@export var health_multiplier: float = 12.0
## Drawn and touching this much bigger.
@export var size: float = 1.6
@export var contact_damage_multiplier: float = 1.5
@export var move_speed_multiplier: float = 0.9
## Knockback compared to the normal zombie (0.25 = a quarter as far).
@export var knockback_multiplier: float = 0.25
## Which XP button it drops (on top of the gift box).
@export var xp_button: EnemyStats.XpSize = EnemyStats.XpSize.BIG
## Its one pattern: after a visible wind-up, a ring of stuffing balls.
@export var attack: SpitAttack
