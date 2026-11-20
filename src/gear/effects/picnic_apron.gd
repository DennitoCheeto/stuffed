class_name PicnicApron
extends Node
## Picnic Apron (spec 09 §3, AC-99): every `amount` seconds (per stitch level) the hero drops a
## snack on the floor behind them. Any hero who is not at full health and touches it eats it and
## heals `GearDef.factor` of their max health, so co-op partners can take it too. At most
## `MAX_SNACKS` wait on the floor; the timer waits while they are all there.

const MAX_SNACKS: int = 3
## How far behind the hero the snack lands (pixels).
const DROP_BEHIND: float = 34.0

var player: Player
var piece: GearDef
## Snacks dropped and eaten in this run (tests).
var dropped: int = 0
var eaten: int = 0

var _next_in: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.PICNIC_APRON)
	_next_in = gap()


## Seconds between snacks at the worn stitch level.
func gap() -> float:
	return piece.amount(player.gear.level_of(piece))


## Seconds until the next snack drops.
func next_in() -> float:
	return _next_in


## The snacks waiting on the floor.
func snacks() -> Array[ApronSnack]:
	var result: Array[ApronSnack] = []
	for child: Node in get_children():
		if child is ApronSnack and not child.is_queued_for_deletion():
			result.append(child as ApronSnack)
	return result


## Drops a snack behind the hero now (the timer starts over).
func drop() -> ApronSnack:
	_next_in = gap()
	var snack: ApronSnack = ApronSnack.new()
	snack.setup(player.global_position - player.facing.normalized() * DROP_BEHIND, piece)
	snack.eaten.connect(_on_eaten)
	add_child(snack)
	dropped += 1
	return snack


func _physics_process(delta: float) -> void:
	if not player.armed or player.is_dead() or snacks().size() >= MAX_SNACKS:
		return
	_next_in -= delta
	if _next_in <= 0.0:
		drop()


func _on_eaten(_by: Player) -> void:
	eaten += 1
	if piece.sound != &"":
		Sfx.play(piece.sound)
