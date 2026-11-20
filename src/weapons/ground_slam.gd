class_name GroundSlam
extends Resource
## Bear Slam's ground slam (spec 10 §3): every few swats Böbö slams the floor, a ring that knocks
## the zombies in it down (a short stun) and hurts them all. Tune it in data/weapons/bear_slam.tres.

## Every this many-th attack is a slam (the swipe still happens too).
@export var every: int = 4
## Radius of the ring (grows with Big Spool), its damage and the stun.
@export var radius: float = 140.0
@export var damage: float = 40.0
@export var stun: float = 0.6
## Push away from Böbö, in pixels per second (like knockback).
@export var push: float = 160.0
## The ring: seconds it takes to spread out and fade, its colour (soft, never a danger colour).
@export var ring_seconds: float = 0.35
@export var ring_color: Color = Color(0.95, 0.89, 0.74, 0.8)
