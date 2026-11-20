class_name GearEffects
extends RefCounted
## What worn gear does in a run or siege (spec 09 §3, AC-99). Effects read the hero's
## `player.gear` (hidden pieces still work), never the save. Numbers per stitch level live in
## data/gear/<id>.tres. Pieces with a lasting effect get their own node under the hero, named
## after its class (like the hero passives).

const PIN_CUSHION_HAT: StringName = &"pin_cushion_hat"
const LOOKOUT_CAP: StringName = &"lookout_cap"
const PROPELLER_CAP: StringName = &"propeller_cap"
const RAINCOAT: StringName = &"raincoat"
const PATCH_VEST: StringName = &"patch_vest"
const PICNIC_APRON: StringName = &"picnic_apron"


## Puts the worn gear's effects on an armed hero (call once from the hero's `_ready`, before
## its weapons are added).
static func apply(player: Player) -> void:
	var gear: WornGear = player.gear
	player.extra_pierce = roundi(gear.amount_of(PIN_CUSHION_HAT))
	player.bonus_version += 1
	var effects: Array[Node] = []
	if gear.has(LOOKOUT_CAP):
		effects.append(LookoutCap.new())
	if gear.has(PROPELLER_CAP):
		effects.append(PropellerCap.new())
	if gear.has(RAINCOAT):
		effects.append(Raincoat.new())
	if gear.has(PATCH_VEST):
		effects.append(PatchVest.new())
	if gear.has(PICNIC_APRON):
		effects.append(PicnicApron.new())
	for effect: Node in effects:
		effect.name = (effect.get_script() as Script).get_global_name()
		player.add_child(effect)
		effect.call(&"setup", player)


## How far one dash of `player` goes (the Propeller Cap adds a share).
static func dash_distance(player: Player) -> float:
	return player.stats.dash_distance * (1.0 + player.gear.amount_of(PROPELLER_CAP))


## XP buttons closer than this fly to `player` (the Lookout Cap grows it while standing still).
static func pickup_reach(player: Player) -> float:
	return player.pickup_range * player.pickup_factor
