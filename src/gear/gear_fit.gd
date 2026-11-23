class_name GearFit
extends RefCounted
## How a piece of gear is laid out in a picture (#331): a cap over a head box (its bottom edge is
## the brow), a body piece round a body oval, a charm on a string. `tile` fills a square tile;
## gear is not drawn on the heroes. Numbers are canvas units.

## Caps, hats: the box the cap covers. Its bottom edge is the brow (just above the eyes), its top
## the top of the head; the cap is a dome over that box, a little wider than the head.
var head: Rect2 = Rect2(-14.0, -76.0, 28.0, 12.0)
## Vests, coats, aprons: the oval of the body the piece wraps around.
var body: Rect2 = Rect2(-20.0, -50.0, 40.0, 46.0)
## The neck opening at the top of a body piece: half its width and how deep it reaches down
## from the top of the piece (deep on Robbar, whose face sits low on the front).
var opening: Vector2 = Vector2(6.0, 8.0)
## Which part of the `body` oval a vest covers, as shares of its height (top, bottom).
var band: Vector2 = Vector2(0.1, 0.8)
## Where a charm hangs on its string (its middle).
var charm: Vector2 = Vector2(4.0, -30.0)
## How big a charm is (pixels across).
var charm_size: float = 9.0
## Where the wind-up key goes into the back (it sticks out up and back from there).
var key: Vector2 = Vector2(-14.0, -34.0)


## A fit for a square tile of `side` around `middle` (the sewing table, Scrapbook): every slot
## fills the tile on its own.
static func tile(middle: Vector2, side: float) -> GearFit:
	var fit: GearFit = GearFit.new()
	fit.head = Rect2(middle + Vector2(-0.42, -0.14) * side, Vector2(0.84, 0.42) * side)
	fit.body = Rect2(middle + Vector2(-0.42, -0.58) * side, Vector2(0.84, 1.08) * side)
	fit.opening = Vector2(0.11, 0.24) * side
	fit.band = Vector2(0.12, 0.96)
	fit.charm = middle + Vector2(0.0, 0.08) * side
	fit.charm_size = side * 0.55
	fit.key = middle + Vector2(0.28, 0.3) * side
	return fit


## The top and bottom of a body piece (y), from `band`; `longer` adds that share of the height.
func band_y(longer: float = 0.0) -> Vector2:
	var bottom: float = minf(band.y + longer, 1.0)
	return Vector2(body.position.y + body.size.y * band.x, body.position.y + body.size.y * bottom)
