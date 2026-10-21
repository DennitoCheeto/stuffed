class_name UpgradeDef
extends Resource
## One upgrade that can appear on a level-up card: a weapon (new or its next level), a boost,
## or the Banana Snack filler. Tune them in data/upgrade_pool.tres, not in code.

enum Kind { WEAPON, BOOST, SNACK }
enum Boost { MOVE_SPEED, MAX_HEALTH, PICKUP_RANGE, ATTACK_SPEED }

## Stable name for the run log and upgrade levels.
@export var id: StringName = &""
@export var display_name: String = "Upgrade"
@export var kind: Kind = Kind.BOOST
## For weapons: the weapon this card gives or levels up.
@export var weapon: WeaponStats
## For boosts: what it raises.
@export var boost: Boost = Boost.MOVE_SPEED
## For boosts: how much per level (0.1 = +10% for speeds and range, flat HP for max health).
## For the snack: share of max health healed.
@export var amount: float = 0.1
## For boosts.
@export var max_level: int = 5
## Card line for boosts and the snack (weapons use their level's card text).
@export var card_text: String = ""
## Which felt icon the card shows.
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
