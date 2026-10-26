class_name BuildingLooks
extends RefCounted
## Which town buildings are drawn with the art kit (`BuildingSketch`, spec 05 §2.2), and their
## looks for ruin (0) and levels 1-3. Each look is built once and kept, so redrawing a building
## (the build moment, the pop) only replays the finished shapes.

## Buildings drawn with the kit.
const KIT_BUILDINGS: Array[StringName] = [
	&"lucky_jar", &"toy_box_armory", &"watchtower", &"snack_bar", &"party_shop", &"plush_hospital"
]

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
		&"watchtower":
			return WatchtowerLook.build(level, building.art_scale)
		&"snack_bar":
			return SnackBarLook.build(level, building.art_scale)
		&"party_shop":
			return PartyShopLook.build(level, building.art_scale)
		&"plush_hospital":
			return HospitalLook.build(level, building.art_scale)
	return null
