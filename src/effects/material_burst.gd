class_name MaterialBurst
extends Node2D
## A short burst of coins / tufts / spools that pops out where an elite, boss or gift box was and
## flies into the HUD jars (spec 03 §3, §11). Lives on the HUD; quieter than XP: small pieces,
## a little see-through. One node draws all pieces and frees itself when they have landed.

signal piece_landed(material: String)

## Seconds a piece pops outwards before it flies to its jar.
const POP_SECONDS: float = 0.18
## Seconds of the flight to the jar.
const FLY_SECONDS: float = 0.55
## Seconds between two pieces starting.
const STAGGER: float = 0.035
## How far the pieces pop out, in pixels.
const POP_DISTANCE: float = 60.0
const PIECE_RADIUS: float = 9.0
const PIECE_ALPHA: float = 0.85
## Most pieces per material, however big the amount.
const MAX_PIECES: int = 10
## Coins per flying coin piece (other materials: one piece each).
const COINS_PER_PIECE: int = 10

## One entry per piece: {"material", "from", "spread", "to", "delay"}.
var pieces: Array[Dictionary] = []
var _time: float = 0.0
var _landed: int = 0


## Sets up pieces for `amounts`, starting at screen position `from`; `targets` maps a material
## to its jar's screen position.
func setup(
	amounts: Dictionary[String, int], from: Vector2, targets: Dictionary[String, Vector2]
) -> void:
	modulate.a = PIECE_ALPHA
	for material: String in amounts:
		for i: int in piece_count(material, amounts[material]):
			var angle: float = TAU * float(pieces.size()) * 0.382 + randf() * 0.4
			var piece: Dictionary = {
				"material": material,
				"from": from,
				"spread": from + Vector2.from_angle(angle) * POP_DISTANCE * randf_range(0.6, 1.0),
				"to": targets.get(material, from),
				"delay": STAGGER * pieces.size(),
			}
			pieces.append(piece)


## How many pieces fly for `amount` of `material`.
static func piece_count(material: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var count: int = ceili(amount / float(COINS_PER_PIECE)) if material == "coins" else amount
	return clampi(count, 1, MAX_PIECES)


## Seconds until the last piece has landed.
func duration() -> float:
	return STAGGER * maxi(pieces.size() - 1, 0) + POP_SECONDS + FLY_SECONDS


## Where piece `index` is right now (a landed piece sits on its jar).
func piece_position(index: int) -> Vector2:
	var piece: Dictionary = pieces[index]
	var t: float = maxf(_time - float(piece["delay"]), 0.0)
	if t < POP_SECONDS:
		var pop: float = ease(t / POP_SECONDS, 0.4)
		return (piece["from"] as Vector2).lerp(piece["spread"], pop)
	var fly: float = clampf((t - POP_SECONDS) / FLY_SECONDS, 0.0, 1.0)
	return (piece["spread"] as Vector2).lerp(piece["to"], ease(fly, 2.2))


func _process(delta: float) -> void:
	var before: float = _time
	_time += delta
	for piece: Dictionary in pieces:
		var lands_at: float = float(piece["delay"]) + POP_SECONDS + FLY_SECONDS
		if before < lands_at and _time >= lands_at:
			_landed += 1
			piece_landed.emit(piece["material"])
	queue_redraw()
	if _landed >= pieces.size():
		queue_free()


func _draw() -> void:
	for index: int in pieces.size():
		var piece: Dictionary = pieces[index]
		var t: float = _time - float(piece["delay"])
		if t < 0.0 or t >= POP_SECONDS + FLY_SECONDS:
			continue
		var material: String = piece["material"]
		JarIcon.draw_material(self, material, piece_position(index), PIECE_RADIUS)
