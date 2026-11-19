class_name GearLevel
extends Resource
## One stitch level of a piece of gear (spec 09 §3, §5): what sewing (Lv 1) or stitching it to
## this level costs at the Sewing Workshop, and the piece's number at this level.

@export var coins: int = 0
@export var stuffing: int = 0
@export var thread: int = 0
## The piece's number at this level (its meaning is per piece: Pin Cushion Hat = extra pierce,
## Lookout Cap = pickup range factor, Propeller Cap = extra dash share, Raincoat = slow share,
## Patch Vest / Picnic Apron = seconds between patches / snacks, Jingle Bell = kills per ring,
## Lucky Button = golden button chance, Wind-up Key = extra fire rate share).
@export var amount: float = 0.0
## What the piece does at this level, in a few words ("+1 pierce").
@export var effect: String = ""


## Material id -> amount, only the materials this level needs.
func cost() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for pair: Array in [["coins", coins], ["stuffing", stuffing], ["thread", thread]]:
		if int(pair[1]) > 0:
			result[str(pair[0])] = int(pair[1])
	return result
