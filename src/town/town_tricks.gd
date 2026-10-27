class_name TownTricks
extends RefCounted
## The town's side of building tricks (spec 06): buying them at a building. The rules themselves
## are in TrickBook; this pays through the town's save and saves at once.

var town: Town


func _init(owner_town: Town) -> void:
	town = owner_town


## Buys trick `index` of `building`'s branch (AC-66): pays once, remembers it and saves at once.
## Returns false (a "nope") if it can't be bought yet.
func try_buy(building: TownBuilding, index: int) -> bool:
	if building.is_busy() or not TrickBook.buy(town.save, building.building, index):
		Sfx.play(&"nope")
		return false
	town.refresh()
	town.changed.emit()
	return true
