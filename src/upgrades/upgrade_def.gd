class_name UpgradeDef
extends Resource
## One upgrade that can appear on a level-up card: a weapon (new or its next level), an item,
## or the Banana Snack filler. Tune them in data/upgrade_pool.tres, not in code.

enum Kind { WEAPON, ITEM, SNACK }
## What an item raises. Items never fire; they make the hero or all their weapons better.
enum Effect {
	MOVE_SPEED,
	MAX_HEALTH,
	PICKUP_RANGE,
	ATTACK_SPEED,
	DAMAGE,
	DURATION_AND_RANGE,
	AREA,
	DAMAGE_TAKEN,
}

## Stable name for the run log and upgrade levels.
@export var id: StringName = &""
@export var display_name: String = "Upgrade"
@export var kind: Kind = Kind.ITEM
## For weapons: the weapon this card gives or levels up.
@export var weapon: WeaponStats
## For items: what it raises.
@export var effect: Effect = Effect.MOVE_SPEED
## For items: how much per level (0.1 = +10% for speeds, range, damage and area, flat HP for max
## health, 0.08 = 8% less damage taken). For the snack: share of max health healed.
@export var amount: float = 0.1
## For items.
@export var max_level: int = 5
## How likely this card is compared to the others (2 = twice as likely as 1).
@export var weight: float = 1.0
## Card line for items and the snack (weapons use their level's card text).
@export var card_text: String = ""
## Which felt icon the card and the HUD show.
@export var icon: StringName = &""


## The last level this upgrade can reach.
func top_level() -> int:
	if kind == Kind.WEAPON:
		return weapon.max_level()
	if kind == Kind.SNACK:
		return 1
	return max_level


## The card line for reaching `level`.
func text_for(level: int) -> String:
	if kind == Kind.WEAPON:
		return weapon.at_level(level).card_text
	return card_text
