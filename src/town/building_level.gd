class_name BuildingLevel
extends Resource
## One level of a town building (spec 03 §6): what it costs to reach it and what the building
## does at this level. Level 1 is the rebuild (coins), level 2 adds stuffing, level 3 thread.

@export var coins: int = 0
@export var stuffing: int = 0
@export var thread: int = 0
## What the building does at this level, in a few words ("+20% pickup range").
@export var effect: String = ""
## Weapons (upgrade pool ids) this level adds to the level-up cards (Toy Box Armory). Weapons
## listed on any building level stay off the cards until that level is reached.
@export var unlocks_weapons: Array[StringName] = []
## From this level on, the player can choose Banane's starting weapon (Toy Box Armory Lv 3).
@export var start_weapon_choice: bool = false
## Extra rerolls, skips and banishes per run at this level, in total (Lucky Jar).
@export var extra_card_uses: int = 0
## Extra pickup range at this level, in total, as a share of the hero's own (0.2 = +20%,
## Watchtower).
@export var pickup_range_bonus: float = 0.0
## Extra max health at this level, in total (Snack Bar).
@export var max_health_bonus: float = 0.0
## How much shorter the wait between floor pickups gets at this level, in total, as a share
## (0.15 = 15% shorter, Party Shop).
@export var pickup_gap_cut: float = 0.0
## From this level on, the first floor pickup of a run is due at this run time (seconds;
## 0 = the normal first drop time, Party Shop Lv 3).
@export var first_pickup_at: float = 0.0
## Beds for rescued plushies at this level, in total (Plush Hospital). A plushie waits in the
## tent until there is a free bed, then moves into town.
@export var plushie_beds: int = 0

@export_group("Night siege")
## Health in the night siege at this level (spec 07 §4).
@export var siege_health: float = 0.0
## Bait (Lucky Jar): zombies this close to its walls (pixels) go for it first. 0 = no bait.
@export var siege_bait: float = 0.0
## Turret (Toy Box Armory, Watchtower): the level of the weapon it fires; 0 = no turret. The
## weapon is `BuildingDef.siege_weapon`, or the hero's starting weapon when that is empty.
@export var siege_weapon_level: int = 0
## Turret, healing ring, trap: how far it reaches (pixels; turrets from their firing spot, the
## ring and the trap from the middle of the footprint).
@export var siege_range: float = 0.0
## Healing spot (Snack Bar): heroes in its ring heal this much health per second. 0 = none.
@export var siege_heal: float = 0.0
## Trap (Party Shop): a confetti pop every this many seconds. 0 = no trap.
@export var siege_trap_seconds: float = 0.0
## Trap: damage of each pop to every zombie inside `siege_range`.
@export var siege_trap_damage: float = 0.0
## Plush Hospital: a knocked-out plushie stands back up after this many seconds. 0 = never
## (it stays out until the siege ends).
@export var siege_revive_seconds: float = 0.0


## Material id -> amount, only the materials this level needs.
func cost() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for pair: Array in [["coins", coins], ["stuffing", stuffing], ["thread", thread]]:
		if int(pair[1]) > 0:
			result[str(pair[0])] = int(pair[1])
	return result
