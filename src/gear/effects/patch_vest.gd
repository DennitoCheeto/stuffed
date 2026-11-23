class_name PatchVest
extends Node
## Patch Vest (spec 09 §3, AC-99): a felt patch on the vest catches one hit whole (before the
## Snack Bar shield), then grows back after `amount` seconds (per stitch level). Gear isn't drawn
## on the hero (#331): a small patch icon under the hero's health bar shows it (`ready_share`).

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


## How far the patch is back: 1 while it is there, 0 right after it caught a hit (the icon).
func ready_share() -> float:
	if player.patch_up:
		return 1.0
	var total: float = piece.amount(player.gear.level_of(piece))
	return clampf(1.0 - _regrow_left / total, 0.0, 1.0) if total > 0.0 else 0.0


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
