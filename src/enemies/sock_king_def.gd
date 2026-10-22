class_name SockKingDef
extends BossDef
## The Sock Puppet King, the boss of the Bedroom (spec 02 §9). He arrives at the run goal
## (run_rules.tres; `at_seconds` is not used) and the run goes on until he is beaten. Patterns,
## all shown before they happen:
## (1) sock spiral: he glows, then a slow rotating spiral of stuffing balls;
## (2) summon: marks on the floor, then a ring of runners appears there;
## (3) from half health on, he is angry and adds a lunge: a red circle marks where he will land.
## Tune him in data/bosses/sock_puppet_king.tres, not in code.

@export_group("Sock spiral")
## The balls (`pattern` = arms of the spiral, `fan_step_degrees` = 360 / arms) and how long he
## glows first (`windup_seconds`).
@export var spiral: SpitAttack
## How long the spiral keeps going.
@export var spiral_seconds: float = 3.0
## Volleys per second while it goes.
@export var spiral_volleys_per_second: float = 8.0
## How fast the spiral turns, in degrees per second.
@export var spiral_turn_degrees: float = 70.0

@export_group("Summon")
## Who he calls.
@export var summon_enemy: EnemyStats
@export var summon_count: int = 8
## How far from him the ring of zombies appears, in pixels.
@export var summon_radius: float = 200.0
## How long the marks show before they appear.
@export var summon_windup_seconds: float = 1.0

@export_group("Angry: lunge")
## He gets angry below this share of his health (0.5 = half).
@export var angry_below: float = 0.5
@export var angry_banner: String = "The King is angry!"
## How long the red circle shows where he will land.
@export var lunge_windup_seconds: float = 1.0
## How long the jump takes.
@export var lunge_seconds: float = 0.5
## Players this close to where he lands get hurt.
@export var lunge_radius: float = 110.0
@export var lunge_damage: float = 25.0
## He stands still this long after landing.
@export var lunge_recover_seconds: float = 0.8
## How high he flies, in pixels (only the look).
@export var lunge_height: float = 120.0


func make_brain() -> BossBrain:
	return SockKingBrain.new(self)
