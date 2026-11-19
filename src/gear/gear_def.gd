class_name GearDef
extends Resource
## One piece of sewn-on gear (spec 09 §3): its slot, its one effect, where its sewing pattern
## comes from and its 3 stitch levels. Tune it in data/gear/<id>.tres, not in code. What a piece
## does in a run is keyed by its `id`.

enum Slot { HEAD, BODY, CHARM }
## Where its pattern comes from (spec 09 §4).
enum Source {
	## Reaching Lv 2 of building `source` (sure, plannable).
	BUILDING,
	## Beating boss `source` the first time (sure). `source` = the boss's file name.
	BOSS,
	## Any elite, at `drop_chance` per kill until the pattern is owned (a surprise).
	ELITE,
}

## Slot names as saved (TownGear.worn / hidden), in `Slot` order.
const SLOT_NAMES: PackedStringArray = ["head", "body", "charm"]

@export var id: StringName = &""
@export var display_name: String = ""
@export var slot: Slot = Slot.HEAD
## What it does, in one short line (on its tile at the sewing table).
@export var text: String = ""
@export var source_kind: Source = Source.BUILDING
## The building id (BUILDING) or boss file name (BOSS); empty for ELITE.
@export var source: StringName = &""
## The building level that gives the pattern (BUILDING).
@export var source_level: int = 2
## Chance per kill that the pattern drops (ELITE).
@export var drop_chance: float = 0.0
## Stitch levels 1-3 in order; level 1 is sewing the piece.
@export var levels: Array[GearLevel] = []
## Its felt colour (calm: never a danger colour, spec 09 §7).
@export var color: Color = Color("#b9a3d6")
## Where the pattern comes from, on its locked tile, for BOSS and ELITE pieces ("Big Ted drops
## this"). BUILDING pieces say "Build the <building> to Lv 2" by themselves.
@export var found_text: String = ""

@export_group("Piece numbers")
## Numbers that don't change with the stitch level (0 = not used by this piece):
## Lookout Cap = seconds standing still, Raincoat = puddle seconds, Wind-up Key = seconds of
## faster firing.
@export var seconds: float = 0.0
## Wind-up Key = seconds between wind-ups.
@export var every: float = 0.0
## Propeller Cap = thump reach, Jingle Bell = shockwave reach (pixels).
@export var radius: float = 0.0
## Picnic Apron = share of max health a snack heals, Lucky Button = XP of a golden button
## (times a normal one).
@export var factor: float = 0.0


## The name of its slot as saved ("head", "body", "charm").
func slot_name() -> String:
	return SLOT_NAMES[slot]


## The highest stitch level.
func max_level() -> int:
	return levels.size()


## Stitch level `level` (1-3), or null when there is none.
func level(at: int) -> GearLevel:
	return levels[at - 1] if at >= 1 and at <= levels.size() else null


## The piece's number at stitch level `at` (0 when it isn't sewn).
func amount(at: int) -> float:
	var stitch: GearLevel = level(at)
	return stitch.amount if stitch != null else 0.0
