class_name RunHints
extends HintBoard
## The run's first-time hints (spec 10 §6): move, xp, level_up, gift_box, floor_pickup,
## evolution_ready, boss, way_home. Main adds it to the run with the town save; it only looks at
## the run (nothing in the run calls it). Hints follow player 1 (until M7's co-op joining).

## The player has walked this far (px) from where the move note appeared: done.
const WALKED: float = 80.0

var run: Run
var _start: Vector2 = Vector2.INF


## Adds the hints to `to_run`, remembered in `town`.
static func attach(to_run: Run, town: TownSave) -> RunHints:
	var hints: RunHints = RunHints.new()
	hints.save = town
	hints.run = to_run
	to_run.add_child(hints)
	return hints


## The run's hints (null if it has none, e.g. a run started without Main).
static func of(screen: Node) -> RunHints:
	if screen == null:
		return null
	return screen.get_node_or_null(^"Hints") as RunHints


func _ticking() -> bool:
	# Notes wait while the run is frozen (the level-up note stays as long as the cards show).
	return not run.is_frozen()


## Other notes hide while the run is frozen (gift box, pause); the level-up note is for the cards.
func _hidden_now() -> bool:
	return run.is_frozen() and showing() != "level_up"


func _watch() -> void:
	if not run.is_node_ready() or run.over:
		return
	var player: Player = _first_player()
	if player == null:
		return
	_watch_move(player)
	_watch_level_up()
	_offer("xp", not run.pickups.buttons.is_empty())
	if is_showing("xp") and (player.progress.xp > 0 or player.progress.level > 1):
		finish("xp")
	_watch_gift_box()
	_watch_floor_pickup()
	_watch_evolution(player)
	_watch_boss()
	_watch_way_home()


func _watch_move(player: Player) -> void:
	if _offer("move", true):
		_start = player.global_position
	if not is_showing("move"):
		return
	if _start == Vector2.INF:
		_start = player.global_position
	if player.is_dashing() or player.global_position.distance_to(_start) >= WALKED:
		finish("move")


func _watch_level_up() -> void:
	var open: bool = run.level_up_screen.is_open()
	if open:
		# The cards come first: an older note steps aside (it shows again next run).
		if note != null and showing() != "level_up" and not done:
			_leave()
		try_show("level_up")
	elif is_showing("level_up"):
		finish("level_up")


func _watch_gift_box() -> void:
	var boxes: int = _count(GiftBox)
	_offer("gift_box", boxes > 0)
	if is_showing("gift_box") and (run.gift_boxes_opened > 0 or boxes == 0):
		finish("gift_box")


func _watch_floor_pickup() -> void:
	_offer("floor_pickup", not run.floor_pickups().is_empty())
	if is_showing("floor_pickup") and not run.floor_pickup_log.is_empty():
		finish("floor_pickup")


func _watch_evolution(player: Player) -> void:
	_offer("evolution_ready", run.upgrade_pool.ready_evolution(player.upgrade_levels()) != null)
	if is_showing("evolution_ready") and not run.evolution_log.is_empty():
		finish("evolution_ready")


func _watch_boss() -> void:
	var bosses: int = run.enemies.bosses().size()
	_offer("boss", bosses > 0)
	if is_showing("boss") and bosses == 0:
		finish("boss")


func _watch_way_home() -> void:
	var portal: WayHomePortal = run.way_home
	var open: bool = is_instance_valid(portal) and not portal.used
	_offer("way_home", open)
	if is_showing("way_home") and (not open or portal.occupied):
		finish("way_home")


func _first_player() -> Player:
	for player: Player in Players.all(get_tree()):
		if player.player_index == 0:
			return player
	return null


func _count(kind: Variant) -> int:
	var found: int = 0
	for item: Node in run.floor_items.get_children():
		if is_instance_of(item, kind) and not item.is_queued_for_deletion():
			found += 1
	return found


## Shows hint `id` when `now` is true, but never over a frozen run (the cards, a gift box, the
## pause menu): it waits for play to go on.
func _offer(id: String, now: bool) -> bool:
	return now and not run.is_frozen() and try_show(id)
