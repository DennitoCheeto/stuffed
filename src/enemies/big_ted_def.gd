class_name BigTedDef
extends BossDef
## Big Ted, the mini-boss (spec 02 §9): a giant zombie teddy. He takes turns between two
## patterns, both shown before they happen:
## (1) charge: a red line shows his path, then he charges along it;
## (2) stomp: he swells up, then a ring of stuffing balls spreads out from his feet.
## Tune him in data/bosses/big_ted.tres, not in code.

@export_group("Charge")
## How long the red line shows his path before he goes.
@export var charge_windup_seconds: float = 1.0
## Pixels per second while charging.
@export var charge_speed: float = 420.0
## How far one charge goes (shorter at the arena's edge).
@export var charge_distance: float = 520.0
## He stands dazed this long after a charge.
@export var charge_recover_seconds: float = 0.8

@export_group("Stomp")
## The stuffing balls of one stomp (`pattern` = balls in the ring, `fan_step_degrees` =
## 360 / balls) and how long he swells up first (`windup_seconds`, the ring shows meanwhile).
@export var stomp: SpitAttack
## Radius of the warning ring on the floor, in pixels.
@export var stomp_ring_radius: float = 150.0


func make_brain() -> BossBrain:
	return BigTedBrain.new(self)
