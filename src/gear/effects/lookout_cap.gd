class_name LookoutCap
extends Node2D
## Lookout Cap (spec 09 §3, AC-99): standing still for `GearDef.seconds` grows the hero's pickup
## range to `amount` times (per stitch level) until they move again. While it is on, a thin calm
## ring in the cap's colour shows the bigger reach on the floor.

const RING_WIDTH: float = 2.0
const RING_ALPHA: float = 0.35
const RING_POINTS: int = 48

var player: Player
var piece: GearDef
## Seconds the hero has stood still.
var still_for: float = 0.0


func setup(owner_player: Player) -> void:
	player = owner_player
	piece = player.gear.find_piece(GearEffects.LOOKOUT_CAP)
	# A floor mark under the hero, like the hero ring.
	z_as_relative = false
	z_index = WorldLayers.FLOOR_MARKS
	visible = false


## True while the bigger pickup range is on.
func is_on() -> bool:
	return still_for >= piece.seconds


func _physics_process(delta: float) -> void:
	if player.is_dead() or player.is_dashing() or player.velocity != Vector2.ZERO:
		still_for = 0.0
	else:
		still_for += delta
	var was_on: bool = visible
	player.pickup_factor = piece.amount(player.gear.level_of(piece)) if is_on() else 1.0
	visible = is_on()
	modulate.a = GameSettings.own_effects
	if visible != was_on:
		queue_redraw()


func _draw() -> void:
	var color: Color = Color(piece.color, RING_ALPHA)
	draw_arc(
		Vector2.ZERO,
		GearEffects.pickup_reach(player),
		0.0,
		TAU,
		RING_POINTS,
		color,
		RING_WIDTH,
		true
	)
