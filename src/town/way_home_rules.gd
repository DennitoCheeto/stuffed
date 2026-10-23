class_name WayHomeRules
extends Resource
## The Way Home portal that opens after Big Ted (spec 03 §4).
## Tune it in data/town/way_home_rules.tres, not in code.

## Standing in the portal this long (seconds) takes everybody home.
@export var fill_seconds: float = 2.0
## A player whose middle is this close to the portal's middle stands in it (pixels).
@export var stand_radius: float = 48.0
## The portal opens this far from the nearest player, towards the middle of the room (pixels).
@export var open_distance: float = 260.0
## It keeps at least this far from the walls (pixels).
@export var wall_margin: float = 90.0
## The banner when it opens, and how long it stays up.
@export var banner: String = "The way home is open!"
@export var banner_subtitle: String = "Stand in the portal to go home with everything"
@export var banner_seconds: float = 2.5
## Played when it opens (and, a little higher, when it takes everybody home).
@export var sound: StringName = &"way_home"
