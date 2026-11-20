class_name Raincoat
extends Node
## Raincoat (spec 09 §3, AC-99): every dash leaves a puddle along its path for `GearDef.seconds`.
## Zombies in a puddle walk `amount` slower (per stitch level), and enemy bullets that fly into
## it fizzle out. Each puddle is its own `RaincoatPuddle` (a floor mark under the zombies).

var player: Player
var piece: GearDef
## Puddles left in this run (tests).
var puddles_made: int = 0

var _dash_from: Vector2 = Vector2.ZERO


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.RAINCOAT)
	player.dashed.connect(_on_dashed)
	player.dash_landed.connect(_on_dash_landed)


## The puddles on the floor right now.
func puddles() -> Array[RaincoatPuddle]:
	var result: Array[RaincoatPuddle] = []
	for child: Node in get_children():
		if child is RaincoatPuddle and not child.is_queued_for_deletion():
			result.append(child as RaincoatPuddle)
	return result


func _on_dashed(from_position: Vector2, _direction: Vector2) -> void:
	_dash_from = from_position


func _on_dash_landed(at: Vector2) -> void:
	if not player.armed or player.is_dead():
		return
	var puddle: RaincoatPuddle = RaincoatPuddle.new()
	puddle.setup(_dash_from, at, piece, piece.amount(player.gear.level_of(piece)))
	add_child(puddle)
	puddles_made += 1
	if piece.sound != &"":
		Sfx.play(piece.sound)
