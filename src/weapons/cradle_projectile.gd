class_name CradleProjectile
extends YarnProjectile
## One Cat's Cradle ball (spec 11 §4.1): bounces like a yarn ball, stretches a thread from its last
## bounce point to each new one, and sends XP buttons it rolls over to its hero. It finds the
## threads by node name, so it never refers to the weapon's class (script cycles leak resources).

## XP buttons it sent to the hero (for tests).
var snagged: int = 0

var _last_point: Vector2 = Vector2.ZERO
var _threads: CradleThreads
var _pickups: PickupManager


func reset() -> void:
	super()
	snagged = 0
	_threads = null
	_pickups = null


func launch(from: Weapon, direction: Vector2) -> void:
	super(from, direction)
	_last_point = global_position
	_threads = from.get_node_or_null(NodePath(CradleThreads.NAME)) as CradleThreads
	var run: Run = from.get_tree().get_first_node_in_group(Run.GROUP) as Run
	_pickups = run.pickups if run != null else null


func advance(delta: float) -> bool:
	var flying: bool = super(delta)
	_snag()
	return flying


func _bounced(at: Vector2) -> void:
	if _threads != null:
		_threads.add(_last_point, at)
	_last_point = at


func _snag() -> void:
	var cradle: YarnCradle = weapon.stats.yarn_cradle
	if _pickups == null or cradle == null or weapon.player == null:
		return
	snagged += _pickups.attract_near(global_position, cradle.snag_radius, weapon.player)
