class_name ChainPins
extends Resource
## Pincushion Volley's chain pins (spec 10 §3): a zombie killed by a volley pin fires new pins
## from where it fell. Chained pins never chain again (one generation), so it can't run forever.
## Tune it in data/weapons/pincushion_volley.tres.

## New pins fired from a zombie a pin killed.
@export var count: int = 2
## Angle between them, spread around the killing pin's direction, in degrees.
@export var spread_degrees: float = 70.0
## Their damage and reach as a share of the volley's.
@export var damage_share: float = 0.6
@export var reach_share: float = 0.45
## At most this many kills of one volley pin start chains (keeps big crowds cheap).
@export var chains_per_pin: int = 3
