class_name WindUpKey
extends Node
## Wind-up Key (spec 09 §3, AC-99): every `GearDef.every` seconds the key winds up and the hero's
## weapons fire `amount` faster (per stitch level, added to `Player.attack_speed`) for
## `GearDef.seconds`. While it lasts the key spins on the hero's back (the charm sprite turns;
## hidden gear still works, there is just nothing to see).

## How fast the key spins while wound up (turns per second).
const SPIN_TURNS: float = 2.0

var player: Player
var piece: GearDef
## Wind-ups in this run (tests).
var wind_ups: int = 0

var _next_in: float = 0.0
var _left: float = 0.0
var _boost: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.WIND_UP_KEY)
	_next_in = piece.every


## True while the weapons fire faster.
func is_wound_up() -> bool:
	return _left > 0.0


## Seconds until the next wind-up (while not wound up).
func next_in() -> float:
	return _next_in


## Winds up now: faster weapons for `GearDef.seconds`.
func wind_up() -> void:
	if not is_wound_up():
		_boost = piece.amount(player.gear.level_of(piece))
		player.attack_speed += _boost
		player.bonus_version += 1
	wind_ups += 1
	_left = piece.seconds
	_next_in = piece.every
	if piece.sound != &"":
		Sfx.play(piece.sound)


func _physics_process(delta: float) -> void:
	if not player.armed or player.is_dead():
		return
	if is_wound_up():
		_left = maxf(_left - delta, 0.0)
		if not is_wound_up():
			player.attack_speed -= _boost
			player.bonus_version += 1
			_boost = 0.0
	else:
		_next_in -= delta
		if _next_in <= 0.0:
			wind_up()


func _process(delta: float) -> void:
	var key: Sprite2D = _charm_sprite()
	if key == null:
		return
	key.rotation = key.rotation + TAU * SPIN_TURNS * delta if is_wound_up() else 0.0


func _charm_sprite() -> Sprite2D:
	var puppet: Node = player.get_node_or_null(^"Puppet")
	var view: HeroGear = puppet.get(&"gear_view") as HeroGear if puppet != null else null
	return view.sprite(GearDef.Slot.CHARM) if view != null else null
