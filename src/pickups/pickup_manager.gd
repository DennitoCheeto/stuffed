class_name PickupManager
extends Node2D
## Owns the XP buttons of a run: drops them where zombies die, lets them fly to the nearest
## player once that player is within pickup range, and hands the XP over on contact.

## A player collected a button. `chain` counts pickups in quick succession (for rising "plip"s).
signal collected(player: Player, value: int, chain: int)

## More buttons than this on the floor: new XP is added to the oldest button instead.
const MAX_BUTTONS: int = 400
## Pickups closer together than this (seconds) continue a chain.
const CHAIN_WINDOW: float = 0.5
const COLLECT_DISTANCE: float = 12.0

@export var rules: XpRules

var buttons: Array[XpButton] = []

var _time: float = 0.0
var _last_pickup_time: float = -INF
var _chain: int = 0


## Drops a button of `size` at `at`.
func drop(size: EnemyStats.XpSize, at: Vector2) -> XpButton:
	var value: int = rules.button_value(size)
	if buttons.size() >= MAX_BUTTONS:
		var oldest: XpButton = buttons[0]
		oldest.value += value
		return oldest
	var button: XpButton = XpButton.new()
	button.setup(size, value)
	button.position = at
	add_child(button)
	buttons.append(button)
	return button


func _physics_process(delta: float) -> void:
	_time += delta
	var players: Array[Player] = []
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			players.append(player)
	if players.is_empty():
		return
	for button: XpButton in buttons.duplicate():
		if button.target == null or button.target.is_dead():
			button.target = _player_in_range(button.position, players)
			button.speed = rules.attract_start_speed
		if button.target != null:
			_fly(button, delta)


func _player_in_range(point: Vector2, players: Array[Player]) -> Player:
	var best: Player = null
	var best_distance: float = INF
	for player: Player in players:
		var distance: float = player.global_position.distance_to(point)
		if distance <= player.pickup_range and distance < best_distance:
			best = player
			best_distance = distance
	return best


func _fly(button: XpButton, delta: float) -> void:
	var goal: Vector2 = button.target.global_position
	button.speed = minf(button.speed + rules.attract_acceleration * delta, rules.attract_max_speed)
	var step: float = button.speed * delta
	if button.position.distance_to(goal) <= step + COLLECT_DISTANCE:
		_collect(button)
		return
	button.position += button.position.direction_to(goal) * step


func _collect(button: XpButton) -> void:
	buttons.erase(button)
	var player: Player = button.target
	_chain = _chain + 1 if _time - _last_pickup_time <= CHAIN_WINDOW else 1
	_last_pickup_time = _time
	player.add_xp(button.value)
	collected.emit(player, button.value, _chain)
	button.queue_free()
