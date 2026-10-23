class_name EnemyStats
extends Resource
## Balance numbers for one zombie type. Tune them in data/enemies/*.tres, not in code.

enum Look { SHAMBLER, RUNNER, FROG, PIG, ELEPHANT, SOCK_KING }
enum XpSize { SMALL, MEDIUM, BIG }

@export var display_name: String = "Zombie"
## What the Scrapbook says about it (spec 03 §8).
@export_multiline var scrapbook_text: String = ""
## Which felt puppet is drawn.
@export var look: Look = Look.SHAMBLER
@export var max_health: float = 10.0
## Pixels per second.
@export var move_speed: float = 45.0
## Damage when it touches a hero.
@export var contact_damage: float = 5.0
## Which XP button it drops when killed.
@export var xp_button: XpSize = XpSize.SMALL
## Body radius in pixels, for crowding and touching.
@export var radius: float = 16.0
## 1 = normal knockback, 0 = can't be pushed.
@export var knockback_taken: float = 1.0
## Ranged attack (the spitter); none = it only hurts by touching.
@export var attack: SpitAttack
## Cloud it bursts into when killed (the bloater); none = it just pops.
@export var death_cloud: DeathCloud
