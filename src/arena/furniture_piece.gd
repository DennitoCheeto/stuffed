class_name FurniturePiece
extends Resource
## One hand-placed piece of bedroom furniture: what it is (decides its look) and where it stands.

enum Kind { BED, TOY_BOX, BLOCK_TOWER, RUG }

@export var kind: Kind = Kind.BLOCK_TOWER
## Where it stands on the floor, in arena pixels.
@export var rect: Rect2 = Rect2(0, 0, 200, 200)
## Blocks players, zombies and enemy bullets (a rug doesn't: you walk over it).
@export var blocks: bool = true
