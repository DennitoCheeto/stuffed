class_name GiftContents
extends RefCounted
## What one gift box held: an evolution, level-ups of things the player already has, or a heal.

## A weapon that evolves (then there are no level-ups).
var evolution: EvolutionDef
## The name of the weapon it evolves from.
var evolution_from: String = ""
## In the order they are given (the same upgrade can come twice: Lv 2 → 3, then Lv 3 → 4).
var level_ups: Array[UpgradeOffer] = []
## Share of max health healed (0 = no heal).
var heal_share: float = 0.0
## Who opened the box.
var player: Player


func is_evolution() -> bool:
	return evolution != null


func is_heal() -> bool:
	return evolution == null and level_ups.is_empty()


## Gives everything to `player`.
func apply_to(to_player: Player) -> void:
	if evolution != null:
		to_player.evolve(evolution)
	for offer: UpgradeOffer in level_ups:
		to_player.apply_upgrade(offer)
	if heal_share > 0.0:
		to_player.heal(to_player.max_health * heal_share)


## One line per gift for the opening moment, e.g. "Peel Boomerang  Lv 2 → 3".
func lines() -> PackedStringArray:
	var result: PackedStringArray = []
	if evolution != null:
		result.append("%s → %s!" % [evolution_from, evolution.display_name()])
		result.append(evolution.card_text)
	for offer: UpgradeOffer in level_ups:
		result.append("%s  %s" % [offer.upgrade.display_name, offer.level_text()])
	if heal_share > 0.0:
		result.append("Big heal! +%d%% health" % roundi(heal_share * 100.0))
	return result
