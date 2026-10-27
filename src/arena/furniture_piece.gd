class_name FurniturePiece
extends Resource
## One hand-placed piece of bedroom furniture: what it is (decides its look), which part of the
## Bedroom it belongs to (spec 05 §4.2) and where it stands.

## New kinds go at the end (the layout file stores them as numbers).
## SCRIBBLES, SCISSORS, SPOOL (a spool with its thread trail across the rect) and TRAIN_TRACK
## are floor decorations you walk over.
enum Kind {
	BED,
	TOY_BOX,
	BLOCK_TOWER,
	RUG,
	CRAYON,
	SHARPENER,
	SCRIBBLES,
	SEWING_BOX,
	PINCUSHION,
	SCISSORS,
	SPOOL,
	TRAIN_TRACK,
}
## The six places of the Bedroom (spec 05 §4.2). Looks only: same spawns and rules everywhere.
enum Zone { RUG, BED_SHADOW, BLOCK_CITY, CRAYON_CORNER, SEWING_CORNER, TRAIN_LOOP }

@export var kind: Kind = Kind.BLOCK_TOWER
@export var zone: Zone = Zone.RUG
## Where it stands on the floor, in arena pixels.
@export var rect: Rect2 = Rect2(0, 0, 200, 200)
## Blocks players, zombies and enemy bullets (a rug doesn't: you walk over it).
@export var blocks: bool = true
