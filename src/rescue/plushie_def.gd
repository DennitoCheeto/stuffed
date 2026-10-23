class_name PlushieDef
extends Resource
## One plushie that can be rescued in a run (spec 03 §7) and later lives in town: one of the
## girlfriend's real plushies, drawn in felt from the product owner's photos (PlushieLook).
## One file per plushie in data/town/plushies/.

## Which felt drawing PlushieLook uses.
enum Shape {
	## Pip: a huge round polar bear body with a tiny head and a scarf.
	ROUND_BEAR,
	## Böbö: a big classic teddy bear.
	TEDDY,
	## BamBam: a long tube body with round ears, a bowtie and a heart patch.
	LONG,
	## Robbar: a small chonky seal.
	SEAL,
}

## Saved in the town (TownSave.plushies) and in the run log, e.g. "pip". Never change it
## (TownSave.from_dict renames the old placeholder ids).
@export var id: String = ""
## The name tag, e.g. "Pip".
@export var display_name: String = ""
@export var shape: Shape = Shape.TEDDY
@export var body_color: Color = Color("#d9c7b0")
## Muzzle, belly or face.
@export var accent_color: Color = Color("#f2e6d6")
## Scarf, bowtie or spots.
@export var detail_color: Color = Color("#c0392b")
## Heart patch, inner ears, paw pads or toe dots.
@export var patch_color: Color = Color("#2a2230")
## How big it is next to the others (1 = normal; a smol seal is smaller).
@export var height: float = 1.0
