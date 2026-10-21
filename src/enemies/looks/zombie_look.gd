class_name ZombieLook
extends RefCounted
## How one zombie type is put together (where its parts hang, in concept units) and how it moves.
## Each look (ShamblerLook, RunnerLook, FrogLook, PigLook, ElephantLook) fills one of these and
## draws its parts for the FeltAtlas.

## Atlas keys are "<prefix>/<part>": shadow, limb_left, limb_right, body, head, eye, flash.
var prefix: String = ""
## Concept point that sits on the zombie's centre.
var anchor: Vector2 = Vector2.ZERO
## Concept point the body rocks and squishes around (its feet).
var root_pivot: Vector2 = Vector2.ZERO
var shadow_pivot: Vector2 = Vector2.ZERO
var limb_left_pivot: Vector2 = Vector2.ZERO
var limb_right_pivot: Vector2 = Vector2.ZERO
var body_pivot: Vector2 = Vector2.ZERO
var head_pivot: Vector2 = Vector2.ZERO
var eye_pivot: Vector2 = Vector2.ZERO
## Concept units → pixels.
var draw_scale: float = 0.3
## Walk rhythm.
var steps_per_second: float = 1.3
## How far the body rocks side to side, in degrees.
var sway_degrees: float = 6.0
## How high it bobs per step, in concept units.
var bounce: float = 5.0
## How far the limbs (arms, ears) swing, in degrees.
var limb_swing: float = 14.0
## True: the limbs swing in opposite directions (arms). False: together (floppy ears).
var limbs_mirrored: bool = true


func key(part: String) -> StringName:
	return StringName("%s/%s" % [prefix, part])


static func for_look(look: EnemyStats.Look) -> ZombieLook:
	match look:
		EnemyStats.Look.RUNNER:
			return RunnerLook.spec()
		EnemyStats.Look.FROG:
			return FrogLook.spec()
		EnemyStats.Look.PIG:
			return PigLook.spec()
		EnemyStats.Look.ELEPHANT:
			return ElephantLook.spec()
	return ShamblerLook.spec()


## Every zombie part of every look, for the FeltAtlas.
static func all_parts() -> Dictionary[StringName, FeltPiece]:
	var parts: Dictionary[StringName, FeltPiece] = ShamblerLook.make_parts()
	parts.merge(RunnerLook.make_parts())
	parts.merge(FrogLook.make_parts())
	parts.merge(PigLook.make_parts())
	parts.merge(ElephantLook.make_parts())
	return parts


## A felt part with its pivot at `pivot` and an outline in concept coordinates.
static func part(pivot: Vector2, outline: PackedVector2Array, fill: Color) -> FeltPiece:
	var piece: FeltPiece = FeltPiece.new()
	piece.pivot = pivot
	piece.polygon = FeltShapes.shifted(outline, -pivot)
	piece.color = fill
	return piece


## A sewn-on button eye with four holes.
static func button_eye(center: Vector2, radius: float) -> FeltPiece:
	var eye: FeltPiece = part(center, FeltShapes.circle(center, radius, 16), Color("#2a2a2a"))
	eye.soft = false
	var spread: float = radius * 0.33
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var hole: Vector2 = center + offset * spread
		eye.add_layer(FeltShapes.circle(hole, radius * 0.18, 8), Color("#666666"))
	return eye


static func shadow(center: Vector2, radii: Vector2) -> FeltPiece:
	var piece: FeltPiece = part(center, FeltShapes.ellipse(center, radii), Color(0, 0, 0, 0.35))
	piece.soft = false
	return piece
