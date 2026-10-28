class_name TownTricks
extends RefCounted
## The town's side of building tricks (spec 06): the Tricks panel (T at a built building), the
## "New: <Building> tricks!" toast and buying. The rules themselves are in TrickBook; this pays
## through the town's save and saves at once.

var town: Town
## The Tricks panel of the building a player opened it at.
var panel: TricksPanel = TricksPanel.new()
## "New: Snack Bar tricks!" when a building reaches level 1.
var toast: TricksToast = TricksToast.new()

## The physics frame the panel last closed (the T that closed it must not open it again).
var _closed_at: int = -10


func _init(owner_town: Town) -> void:
	town = owner_town
	panel.buy_requested.connect(_on_buy_requested)
	panel.closed.connect(_on_closed)


## Adds the panel to the town and the toast to its HUD (from Town._ready).
func attach(hud: CanvasLayer) -> void:
	town.add_child(panel)
	hud.add_child(toast)


## True when T at `building` opens its Tricks panel: built, with a branch of tricks.
static func has_tricks(building: TownBuilding) -> bool:
	return building.level > 0 and not building.building.tricks.is_empty()


## Opens the Tricks panel of `building` for player `by`; the town waits until it closes.
func open(building: TownBuilding, by: int = 0) -> bool:
	if not has_tricks(building) or panel.is_open():
		return false
	if Engine.get_physics_frames() <= _closed_at + 1:
		return false
	town.process_mode = Node.PROCESS_MODE_DISABLED
	town.card.hide_card.call_deferred()
	panel.open(building, town.save, by)
	return true


## Buys trick `index` of `building`'s branch (AC-66): pays once, remembers it and saves at once.
## Returns false (a "nope") if it can't be bought yet.
func try_buy(building: TownBuilding, index: int) -> bool:
	if building.is_busy() or not TrickBook.buy(town.save, building.building, index):
		Sfx.play(&"nope")
		return false
	town.refresh()
	town.changed.emit()
	return true


## A building just reached `level`: at level 1 its trick branch opens (with a toast).
func on_built(building: TownBuilding, level: int) -> void:
	if level != 1 or building.building.tricks.is_empty():
		return
	toast.show_for(building.building.display_name, town.unlock_toast.time_left())


func _on_buy_requested(index: int) -> void:
	var building: TownBuilding = panel.building
	if building == null or not try_buy(building, index):
		return
	panel.refresh(town.save)
	panel.play_bought(index)


func _on_closed() -> void:
	_closed_at = Engine.get_physics_frames()
	town.process_mode = Node.PROCESS_MODE_INHERIT
