class_name WorldLayers
extends RefCounted
## The clarity ladder (#172, vision §6, hard rule 9): what is drawn over what in a run, back to
## front. Danger reads first, your hero right after, your own attacks are quieter, pickups lie on
## the floor:
##
##   floor (Arena, -10) < floor marks (hero ring, landing rings, -1) < pickups (0)
##   < own shots (1) < zombies, bursts, damage numbers (2) < heroes (3) < enemy bullets (50)
##
## Run nodes get these in run.tscn and ProjectileManager; heroes and their ring in Player.
## `test_clarity_ladder.gd` checks the real scene against this order.

const FLOOR_MARKS: int = -1
const PICKUPS: int = 0
const OWN_SHOTS: int = 1
const ENEMIES: int = 2
const HEROES: int = 3
const ENEMY_BULLETS: int = 50


## The z index `node` is really drawn at (its own plus every relative parent's).
static func absolute_z(node: Node) -> int:
	var z: int = 0
	var at: Node = node
	while at != null:
		var item: CanvasItem = at as CanvasItem
		if item != null:
			z += item.z_index
			if not item.z_as_relative:
				return z
		at = at.get_parent()
	return z
