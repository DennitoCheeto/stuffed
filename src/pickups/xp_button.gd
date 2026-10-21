class_name XpButton
extends Sprite2D
## A felt XP button lying on the floor. The PickupManager moves it once a player is close.

var value: int = 1
var size: EnemyStats.XpSize = EnemyStats.XpSize.SMALL
## Once attracted it keeps flying to this player until collected.
var target: Player
var speed: float = 0.0


func setup(button_size: EnemyStats.XpSize, xp_value: int) -> void:
	size = button_size
	value = xp_value
	FeltAtlas.show_part(self, XpButtonLook.KEYS[size])
	scale *= XpButtonLook.DRAW_SCALE
