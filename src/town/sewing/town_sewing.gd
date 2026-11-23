class_name TownSewing
extends RefCounted
## The town's side of the sewing table (spec 09 §6): E at a built Sewing Workshop opens it for
## that player; sewing, stitching, wearing and taking off go through GearBook and save at once.
## The Workshop's own upgrade is a button on the table: it closes the table so the build moment
## plays in the town.

var town: Town
var table: SewingTable = SewingTable.new()

## The physics frame the table last closed (the key that closed it must not open it again).
var _closed_at: int = -10


func _init(owner_town: Town) -> void:
	town = owner_town
	table.act_requested.connect(_on_act_requested)
	table.take_off_requested.connect(_on_take_off_requested)
	table.upgrade_requested.connect(_on_upgrade_requested)
	table.closed.connect(_on_closed)


## Adds the table to the town (from Town._ready, after the buildings): the Workshop's tag
## says "Can sew!" instead of "New trick!".
func attach() -> void:
	town.add_child(table)
	var workshop: TownBuilding = _workshop()
	if workshop != null:
		workshop.new_trick_tag.label.text = GearRules.current().can_sew_tag


## The Workshop floats "Can sew!" while the jars can pay for sewing or stitching a piece (from
## Town.refresh, after the buildings refreshed).
func refresh_tag() -> void:
	var workshop: TownBuilding = _workshop()
	if workshop != null:
		var ready: bool = workshop.level > 0 and not workshop.damaged
		workshop.trick_ready = ready and GearBook.can_sew_any(town.save)


func _workshop() -> TownBuilding:
	return town.buildings.get(GearRules.current().workshop) as TownBuilding


## True when E at `building` opens the sewing table: the Workshop, built and not damaged.
static func opens_table(building: TownBuilding) -> bool:
	var rules: GearRules = GearRules.current()
	return building.spot.id == rules.workshop and building.level > 0 and not building.damaged


## Opens the sewing table for player `by`; the town waits until it closes.
func open(building: TownBuilding, by: int = 0) -> bool:
	if not opens_table(building) or table.is_open():
		return false
	if Engine.get_physics_frames() <= _closed_at + 1:
		return false
	town.process_mode = Node.PROCESS_MODE_DISABLED
	town.card.hide_card.call_deferred()
	table.open(building, town.save, by, _hero_of(by), _building_names())
	return true


## Does `piece`'s main action for player `by` (AC-98): sewing pays once; everything saves at
## once. Returns false (a "nope") if it can't be done right now.
func act(piece: GearDef, by: int = 0) -> bool:
	var action: GearBook.Action = GearBook.action_for(town.save, piece, by)
	if not GearBook.act(town.save, piece, by):
		Sfx.play(&"ui_nope")
		return false
	if action == GearBook.Action.WEAR or action == GearBook.Action.TAKE_OFF:
		Sfx.play(&"page")
	town.refresh()
	town.changed.emit()
	return true


## Player `by` takes off what they wear in `slot` (free), saved at once.
func take_off(slot: GearDef.Slot, by: int = 0) -> bool:
	if not GearBook.take_off(town.save, by, slot):
		Sfx.play(&"ui_nope")
		return false
	Sfx.play(&"page")
	town.refresh()
	town.changed.emit()
	return true


## Every hero in town wears what the save says (after sewing, wearing or the dev menu).
func dress_players() -> void:
	if not town.is_inside_tree():
		return
	for player: Player in Players.all(town.get_tree()):
		player.wear_gear(WornGear.of(town.save, player.player_index))


## The hero player `by` plays in town (player 1 if that player isn't here).
func _hero_of(by: int) -> HeroStats:
	var players: Array[Player] = Players.all(town.get_tree())
	for player: Player in players:
		if player.player_index == by:
			return player.stats
	return players[0].stats


func _building_names() -> Dictionary[String, String]:
	var names: Dictionary[String, String] = {}
	for spot: TownSpot in town.layout.spots:
		names[String(spot.id)] = spot.building.display_name
	return names


func _on_act_requested(piece: GearDef) -> void:
	var action: GearBook.Action = GearBook.action_for(town.save, piece, table.opener)
	if not act(piece, table.opener):
		return
	table.refresh()
	if action == GearBook.Action.SEW or action == GearBook.Action.STITCH:
		table.play_sewn(piece)


func _on_take_off_requested(slot: GearDef.Slot) -> void:
	if take_off(slot, table.opener):
		table.refresh()


func _on_upgrade_requested() -> void:
	var building: TownBuilding = table.building
	table.close()
	if building != null and not town.try_build(building):
		Sfx.play(&"ui_nope")


func _on_closed() -> void:
	_closed_at = Engine.get_physics_frames()
	town.process_mode = Node.PROCESS_MODE_INHERIT
