class_name HeroMarker
extends Node2D
## A soft coloured ring on the floor under a hero's feet (#172, vision §6): your hero is always
## easy to find, even on light floors and in big crowds. Each player has their own colour
## (co-op), never the red/orange of danger. Drawn once, under zombies and shots.

## Where the feet touch the floor, relative to the hero's middle.
const FEET: Vector2 = Vector2(0.0, 20.0)
const RADIUS: Vector2 = Vector2(34.0, 13.0)
const WIDTH: float = 4.0
## A thin dark edge around the coloured line, so it reads on every floor colour.
const EDGE_WIDTH: float = 7.0
const EDGE_COLOR: Color = Color(0.11, 0.1, 0.14, 0.55)
const FILL_ALPHA: float = 0.3
const POINTS: int = 40

var color: Color = UiColors.PLAYER_MARKERS[0]


func _ready() -> void:
	z_index = -1
	var player: Player = get_parent() as Player
	var index: int = player.player_index if player != null else 0
	color = UiColors.PLAYER_MARKERS[posmod(index, UiColors.PLAYER_MARKERS.size())]
	queue_redraw()


func _draw() -> void:
	var ring: PackedVector2Array = []
	for i: int in POINTS + 1:
		var angle: float = TAU * i / POINTS
		ring.append(FEET + Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y))
	FeltDraw.fill(self, ring.slice(0, POINTS), Color(color, FILL_ALPHA))
	draw_polyline(ring, EDGE_COLOR, EDGE_WIDTH, true)
	draw_polyline(ring, color, WIDTH, true)
