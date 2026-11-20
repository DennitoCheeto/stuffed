class_name PatchVest
extends Node
## Patch Vest (spec 09 §3, AC-99): a felt patch on the vest catches one hit whole (before the
## Snack Bar shield), then grows back after `amount` seconds (per stitch level). The vest on the
## hero shows the patch while it is there (`HeroGear.show_patch`: both looks are in the baked
## picture, so it costs no draws). Hidden gear still works, there is just nothing to see.

var player: Player
var piece: GearDef
## Hits caught in this run (tests).
var blocks: int = 0

var _regrow_left: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.PATCH_VEST)
	player.patch_up = true
	player.patch_blocked.connect(_on_patch_blocked)


## Seconds until the patch is back (0 while it is there).
func regrow_left() -> float:
	return _regrow_left


func _on_patch_blocked() -> void:
	blocks += 1
	_regrow_left = piece.amount(player.gear.level_of(piece))
	if piece.sound != &"":
		Sfx.play(piece.sound)


func _process(delta: float) -> void:
	if not player.patch_up and not player.is_dead():
		_regrow_left = maxf(_regrow_left - delta, 0.0)
		if _regrow_left <= 0.0:
			player.patch_up = true
	var puppet: Node = player.get_node_or_null(^"Puppet")
	var view: HeroGear = puppet.get(&"gear_view") as HeroGear if puppet != null else null
	if view != null and view.shows_patch() != player.patch_up:
		view.show_patch(player.patch_up)
