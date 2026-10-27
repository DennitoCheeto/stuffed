class_name BedroomRoom
extends Resource
## How the Bedroom's floor and room look (spec 05 §4.1): honey floorboards, the patchwork rug,
## the top wall with two windows, the sunbeams falling from them and the soft vignette at the
## screen edges. Look numbers only: the room's size and walls stay in the Arena scene.

@export_group("Floorboards")
## Width of one board (boards run from the top wall towards you).
@export var plank_width: float = 96.0
## Board lengths, used in turn (column by column, shifted) so the joints never line up.
@export var plank_lengths: PackedFloat32Array = [640.0, 880.0, 760.0, 1040.0, 700.0, 960.0]
## Wood grain lines along each board.
@export_range(0, 4) var grain_lines: int = 2
## Every this many boards gets a knot.
@export_range(1, 50) var knot_every: int = 7

@export_group("Rug")
## Side of one rug patch (rounded so whole patches fit).
@export var rug_patch: float = 150.0
## The rug's edge band.
@export var rug_border: float = 44.0
## A sewn-on button sits on every this many seam crossings.
@export_range(1, 10) var rug_button_every: int = 2
@export var rug_button_radius: float = 14.0

@export_group("Top wall")
## How much wall shows above the floor (the camera may show it; heroes can't walk there).
@export var top_wall_height: float = 380.0
@export var baseboard_height: float = 40.0
## Where the windows' middles are, across the room (px).
@export var window_centers: PackedFloat32Array = [2500.0, 4300.0]
@export var window_size: Vector2 = Vector2(560.0, 230.0)
## Gap between a window's bottom and the floor's top edge.
@export var window_bottom: float = 90.0

@export_group("Sunbeams")
## How far a beam reaches down into the room (px from the top wall).
@export var sunbeam_length: float = 3000.0
## Sideways shift per px down (light from the top-left: beams lean right).
@export var sunbeam_slant: float = 0.35
## Share of the palette's sunbeam strength.
@export_range(0.0, 1.0) var sunbeam_strength: float = 0.7
## Share of the beam's width that fades out at each side.
@export_range(0.0, 0.5) var sunbeam_soft_edge: float = 0.3

@export_group("Vignette")
## Share of the way from the screen middle to a corner that stays clear.
@export_range(0.0, 1.0) var vignette_clear: float = 0.6
