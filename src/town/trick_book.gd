class_name TrickBook
extends RefCounted
## The rules for buying building tricks (spec 06 §2, AC-66): a trick can be bought once its
## building stands at the trick's level, the trick before it in the branch is bought and the
## jars hold its price. Tricks of one branch are bought in order; branches are independent.

enum State {
	BOUGHT,
	CAN_BUY,
	## The building isn't at the trick's level yet.
	NEEDS_LEVEL,
	## The trick before it in the branch isn't bought yet.
	NEEDS_EARLIER,
	## Everything is ready, but the jars don't hold enough.
	MISSING,
}


## Where trick `index` of `building` stands for the town in `save`.
static func state_of(save: TownSave, building: BuildingDef, index: int) -> State:
	var trick: TrickDef = building.tricks[index]
	if save.has_trick(String(trick.id)):
		return State.BOUGHT
	if save.building_level(String(building.id)) < trick.needs_level:
		return State.NEEDS_LEVEL
	if index > 0 and not save.has_trick(String(building.tricks[index - 1].id)):
		return State.NEEDS_EARLIER
	if not save.can_afford(trick.cost()):
		return State.MISSING
	return State.CAN_BUY


## Buys trick `index` of `building`: takes its price once and remembers it. Returns false (and
## changes nothing) unless its state is CAN_BUY.
static func buy(save: TownSave, building: BuildingDef, index: int) -> bool:
	if state_of(save, building, index) != State.CAN_BUY:
		return false
	var trick: TrickDef = building.tricks[index]
	if not save.spend(trick.cost()):
		return false
	save.tricks.append(String(trick.id))
	return true


## The index of the next trick of `building` that could be bought now (-1 = none).
static func buyable(save: TownSave, building: BuildingDef) -> int:
	for index: int in building.tricks.size():
		if state_of(save, building, index) == State.CAN_BUY:
			return index
	return -1


## Every trick of every building on `layout`, branch by branch.
static func all_tricks(layout: TownLayout) -> Array[TrickDef]:
	var result: Array[TrickDef] = []
	for spot: TownSpot in layout.spots:
		result.append_array(spot.building.tricks)
	return result
