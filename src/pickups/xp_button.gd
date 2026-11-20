class_name XpButton
extends Sprite2D
## A felt XP button lying on the floor. The PickupManager moves it once a player is close.

var value: int = 1
var size: EnemyStats.XpSize = EnemyStats.XpSize.SMALL
## Once attracted it keeps flying to this player until collected.
var target: Player
var speed: float = 0.0
## Lucky Button: a golden button (its value is already the bigger one).
var golden: bool = false


func setup(button_size: EnemyStats.XpSize, xp_value: int) -> void:
	size = button_size
	value = xp_value
	FeltAtlas.show_part(self, XpButtonLook.KEYS[size])
	scale *= XpButtonLook.DRAW_SCALE


## Turns it into a golden button worth `factor` times as much (Lucky Button).
func make_golden(factor: float) -> void:
	golden = true
	value = roundi(value * factor)
	FeltAtlas.show_part(self, XpButtonLook.GOLDEN_KEY)
	scale *= XpButtonLook.DRAW_SCALE
