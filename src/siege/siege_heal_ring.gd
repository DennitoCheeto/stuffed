class_name SiegeHealRing
extends SiegeRing
## The Snack Bar in the night siege (spec 07 §4, AC-78, AC-82): every hero standing in its ring
## heals `per_second` health per second. Heroes are looked up each tick (co-op: all of them,
## never "the player"). The ring glows while it heals someone. Numbers:
## `BuildingLevel.siege_heal` / `siege_range`.

## How fast the glow follows (per second).
const GLOW_SPEED: float = 4.0

var per_second: float = 0.0
## Health healed so far, all heroes together (for tests).
var healed: float = 0.0
## True while at least one hero heals in the ring.
var healing: bool = false


func setup(target: SiegeBuilding, heal: float, reach: float, at: Vector2, ring: Color) -> void:
	place(target, reach, at, ring)
	per_second = heal
	name = "HealRing_%s" % target.id


func stop() -> void:
	healing = false
	super()


func _work(delta: float) -> void:
	healing = false
	for player: Player in Players.all(get_tree()):
		if player.is_dead() or not covers(player.global_position):
			continue
		healing = true
		var before: float = player.health + player.shield
		player.heal(per_second * delta)
		healed += player.health + player.shield - before
	glow = move_toward(glow, 1.0 if healing else 0.0, GLOW_SPEED * delta)
