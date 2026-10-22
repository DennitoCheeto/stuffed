class_name GiftContents
extends RefCounted
## What one gift box held: an evolution, level-ups of things the player already has, or a heal.

const HEAL_ICON: StringName = &"stuffing"

## A weapon that evolves (then there are no level-ups).
var evolution: EvolutionDef
## The name and icon of the weapon it evolves from.
var evolution_from: String = ""
var evolution_from_icon: StringName = &""
## In the order they are given (the same upgrade can come twice: Lv 2 → 3, then Lv 3 → 4).
var level_ups: Array[UpgradeOffer] = []
## Share of max health healed (0 = no heal).
var heal_share: float = 0.0
## Health points the heal was worth (set when given).
var heal_amount: float = 0.0
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
		heal_amount = to_player.max_health * heal_share
		to_player.heal(heal_amount)


## One card per thing received, in the order given (spec 02 §20, AC-27).
func cards() -> Array[GiftCard]:
	var result: Array[GiftCard] = []
	if evolution != null:
		var evolved: GiftCard = GiftCard.new()
		evolved.icon = evolution.icon
		evolved.from_icon = evolution_from_icon
		evolved.from_name = evolution_from
		evolved.title = evolution.display_name()
		evolved.level_text = "Evolved from %s!" % evolution_from
		evolved.text = evolution.card_text
		result.append(evolved)
	for offer: UpgradeOffer in level_ups:
		var card: GiftCard = GiftCard.new()
		card.icon = offer.upgrade.icon
		card.title = offer.upgrade.display_name
		card.level_text = offer.level_text()
		card.text = offer.description()
		result.append(card)
	if heal_share > 0.0:
		var heal: GiftCard = GiftCard.new()
		heal.icon = HEAL_ICON
		heal.title = "Big heal!"
		heal.level_text = "+%d health" % roundi(heal_amount)
		heal.text = "%d%% of your max health" % roundi(heal_share * 100.0)
		result.append(heal)
	return result
