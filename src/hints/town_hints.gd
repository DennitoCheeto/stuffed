class_name TownHints
extends HintBoard
## The town's first-time hints (spec 10 §6): town, can_build, tricks, siege_warning, wardrobe,
## sewing. Main adds it to the town with the save; it only looks at the town (nothing in the
## town calls it). Notes wait while a banner or a menu shows, and follow player 1's keys.

var town: Town
## Buildings standing when the can_build note appeared (it's done once one more level stands).
var _levels_at_note: int = -1


## Adds the hints to `to_town`, remembered in `town_save`.
static func attach(to_town: Town, town_save: TownSave) -> TownHints:
	var hints: TownHints = TownHints.new()
	hints.save = town_save
	hints.town = to_town
	to_town.add_child(hints)
	return hints


## The town's hints (null if it has none, e.g. a town made without Main).
static func of(screen: Node) -> TownHints:
	if screen == null:
		return null
	return screen.get_node_or_null(^"Hints") as TownHints


## A menu or panel is open (the town waits): notes hide and their clock stops.
func _busy() -> bool:
	return (
		not town.can_process()
		or town.tricks.panel.visible
		or town.sewing.table.visible
		or town.wardrobe.picker.visible
	)


func _hidden_now() -> bool:
	return _busy()


func _ticking() -> bool:
	return not _busy() and not town.is_banner_showing()


func _watch() -> void:
	if not town.is_node_ready():
		return
	_watch_tricks()
	_watch_wardrobe()
	_watch_sewing()
	_watch_build()
	if is_showing("siege_warning") and save.siege_nights == 0:
		finish("siege_warning")
	_offer("siege_warning", town.calendar != null and town.calendar.visible)
	_offer("town", true)


func _watch_build() -> void:
	var levels: int = save.total_levels()
	if is_showing("town") and levels > 0:
		finish("town")
	var affordable: bool = false
	for building: TownBuilding in town.buildings.values():
		affordable = affordable or building.shows_can_build()
	if _offer("can_build", affordable):
		_levels_at_note = levels
	if is_showing("can_build") and levels > _levels_at_note:
		finish("can_build")


func _watch_tricks() -> void:
	if is_showing("tricks") and town.tricks.panel.visible:
		finish("tricks")
	var built: bool = false
	for building: TownBuilding in town.buildings.values():
		built = built or (building.level > 0 and not building.building.tricks.is_empty())
	_offer("tricks", built)


func _watch_wardrobe() -> void:
	if is_showing("wardrobe") and town.wardrobe.picker.visible:
		finish("wardrobe")
	_offer("wardrobe", town.wardrobe.visible)


func _watch_sewing() -> void:
	if is_showing("sewing") and town.sewing.table.visible:
		finish("sewing")
	var workshop: TownBuilding = town.buildings.get(GearRules.current().workshop)
	var shown: bool = workshop != null and workshop.unlocked and not workshop.waiting_for_reveal
	_offer("sewing", shown)


## Shows hint `id` when `now` is true, but only while nothing else talks (no banner, no menu,
## the town not settling a build).
func _offer(id: String, now: bool) -> bool:
	if not now or _busy() or town.is_banner_showing() or town.is_settling():
		return false
	return try_show(id)
