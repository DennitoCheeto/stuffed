class_name GiftBoxRules
extends Resource
## What a gift box gives and how its opening moment plays (spec 02 §6).
## Tune it in data/gift_box_rules.tres, not in code.

## A player this close (plus their hitbox) opens it.
@export var touch_radius: float = 24.0
## How likely 1, 2 or 3 level-ups are (weights: 2 = twice as likely as 1).
@export var level_up_weights: PackedFloat32Array = [5.0, 3.0, 2.0]
## With nothing left to level up, the box heals this share of max health (0.5 = 50%).
@export var heal_share: float = 0.5
## The boss's big box tries to give this many more level-ups (spec 02 §6) ...
@export var big_box_extra_level_ups: int = 2
## ... and is drawn this much bigger.
@export var big_box_scale: float = 1.6
## How long the opening moment lasts (any key skips it).
@export var moment_seconds: float = 2.0
## Keys are ignored this long after the moment starts, so a key pressed while playing doesn't
## skip it by accident.
@export var skip_delay: float = 0.3


## What a box holds for a player whose upgrades are at `levels` (id → level): an evolution if a
## weapon is ready to evolve; otherwise 1-3 level-ups of weapons or items they already have
## (different ones while possible, never past the top level; `extra` more from a big box), or a
## heal if everything is maxed.
func contents(
	levels: Dictionary[StringName, int],
	pool: UpgradePool,
	rng: RandomNumberGenerator,
	extra: int = 0
) -> GiftContents:
	var gift: GiftContents = GiftContents.new()
	gift.evolution = pool.ready_evolution(levels)
	if gift.evolution != null:
		gift.evolution_from = pool.find(gift.evolution.weapon).display_name
		return gift
	var working: Dictionary[StringName, int] = levels.duplicate()
	var given: Array[StringName] = []
	for i: int in roll_count(rng) + extra:
		var picked: UpgradeDef = _pick(_upgradable(working, pool), given, rng)
		if picked == null:
			break
		working[picked.id] = working.get(picked.id, 0) + 1
		given.append(picked.id)
		gift.level_ups.append(UpgradeOffer.new(picked, working[picked.id]))
	if gift.level_ups.is_empty():
		gift.heal_share = heal_share
	return gift


## How many level-ups a box tries to give (1, 2 or 3, following `level_up_weights`).
func roll_count(rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for weight: float in level_up_weights:
		total += weight
	var roll_at: float = rng.randf() * total
	for index: int in level_up_weights.size():
		roll_at -= level_up_weights[index]
		if roll_at < 0.0:
			return index + 1
	return level_up_weights.size()


## Owned weapons and items below their top level.
func _upgradable(levels: Dictionary[StringName, int], pool: UpgradePool) -> Array[UpgradeDef]:
	var result: Array[UpgradeDef] = []
	for upgrade: UpgradeDef in pool.upgrades:
		var level: int = levels.get(upgrade.id, 0)
		if upgrade.kind != UpgradeDef.Kind.SNACK and level > 0 and level < upgrade.top_level():
			result.append(upgrade)
	return result


## A random one of `choices`, preferring those not in `given`; null if there are none.
func _pick(
	choices: Array[UpgradeDef], given: Array[StringName], rng: RandomNumberGenerator
) -> UpgradeDef:
	var fresh: Array[UpgradeDef] = []
	for choice: UpgradeDef in choices:
		if not given.has(choice.id):
			fresh.append(choice)
	var from: Array[UpgradeDef] = fresh if not fresh.is_empty() else choices
	if from.is_empty():
		return null
	return from[rng.randi_range(0, from.size() - 1)]
