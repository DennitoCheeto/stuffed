class_name BuildingLooks
extends RefCounted
## Which town buildings are drawn with the art kit (`BuildingSketch`, spec 05 §2.2), and their
## looks for ruin (0) and levels 1-3. Each look is built once and kept, so redrawing a building
## (the build moment, the pop) only replays the finished shapes. Buildings without a kit look
## yet are still drawn by `BuildingArt` (they move over in M3.6-03).

## Buildings drawn with the kit.
const KIT_BUILDINGS: Array[StringName] = [&"lucky_jar", &"toy_box_armory"]

static var _kept: Dictionary[String, BuildingSketch] = {}


static func has_look(building: BuildingDef) -> bool:
	return KIT_BUILDINGS.has(building.id)


## The look of `building` at `level` (0 = ruin), or null when it has no kit look yet.
static func sketch(building: BuildingDef, level: int) -> BuildingSketch:
	if not has_look(building):
		return null
	var key: String = "%s/%d/%s" % [building.id, level, building.art_scale]
	if not _kept.has(key):
		_kept[key] = _build(building, level)
	return _kept[key]


static func _build(building: BuildingDef, level: int) -> BuildingSketch:
	match building.id:
		&"lucky_jar":
			return LuckyJarLook.build(level, building.art_scale)
		&"toy_box_armory":
			return ArmoryLook.build(level, building.art_scale)
	return null
