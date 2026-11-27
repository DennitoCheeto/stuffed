class_name HopscotchHops
extends Resource
## Hopscotch Mortar's hops (spec 11 §4.4): after landing, each thimble hops onward in the direction
## it was flying (away from the hero), every landing a full blast, the last one bigger. Tune it in
## data/weapons/hopscotch_mortar.tres.

## Hops after the first landing.
@export var hops: int = 2
## Pixels per hop.
@export var hop_distance: float = 110.0
## Seconds one hop is in the air (the ring on the floor shows where it comes down).
@export var hop_seconds: float = 0.35
## The last landing's blast is this many times bigger.
@export var last_blast_scale: float = 1.3
