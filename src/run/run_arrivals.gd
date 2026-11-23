class_name RunArrivals
extends Node
## Tells the player in a few words what just turned up (#340): a floor toy dropping shows
## "A toy appeared!", an elite arriving shows "A big one is here!" and gets a short edge arrow
## while it is off screen. Texts and times live in data/run_rules.tres. A child of the run
## scene that only listens, so the run itself needs no code for it.

var _run: Run


func _ready() -> void:
	_run = get_parent() as Run
	if _run != null:
		_run.ready.connect(_on_run_ready, CONNECT_ONE_SHOT)


func _on_run_ready() -> void:
	_run.spawner.elite_spawned.connect(_on_elite_spawned)
	_run.floor_items.child_entered_tree.connect(_on_floor_item_added)


func _on_elite_spawned(elite: Zombie) -> void:
	_say(_run.rules.elite_callout, ArrivalCallout.ELITE_COLOR)
	_run.pickup_arrows.watch_arrival(elite, _run.rules.elite_arrow_seconds)


func _on_floor_item_added(item: Node) -> void:
	if item is FloorPickup:
		_say(_run.rules.toy_callout, ArrivalCallout.TOY_COLOR)


func _say(text: String, color: Color) -> void:
	_run.hud.callout.show_note(text, color, _run.rules.callout_seconds)
