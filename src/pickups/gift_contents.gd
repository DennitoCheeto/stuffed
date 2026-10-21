class_name GiftContents
extends RefCounted
## What one gift box held: level-ups of things the player already has, or a heal.

## In the order they are given (the same upgrade can come twice: Lv 2 → 3, then Lv 3 → 4).
var level_ups: Array[UpgradeOffer] = []
## Share of max health healed (0 = no heal).
var heal_share: float = 0.0
## Who opened the box.
var player: Player


func is_heal() -> bool:
	return level_ups.is_empty()


## Gives everything to `player`.
func apply_to(player: Player) -> void:
	for offer: UpgradeOffer in level_ups:
		player.apply_upgrade(offer)
	if heal_share > 0.0:
		player.heal(player.max_health * heal_share)


## One line per gift for the opening moment, e.g. "Peel Boomerang  Lv 2 → 3".
func lines() -> PackedStringArray:
	var result: PackedStringArray = []
	for offer: UpgradeOffer in level_ups:
		result.append("%s  %s" % [offer.upgrade.display_name, offer.level_text()])
	if heal_share > 0.0:
		result.append("Big heal! +%d%% health" % roundi(heal_share * 100.0))
	return result
