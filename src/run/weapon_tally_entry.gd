class_name WeaponTallyEntry
extends RefCounted
## One row of the WeaponTally: one weapon of one player (or a source that isn't a weapon).

## Weapon id (upgrade pool id), or WeaponTally.PARTY_POPPER / GOAL_POPS / OTHER.
var id: StringName = &""
var display_name: String = ""
## 0-based player index; -1 for sources that aren't a player's weapon.
var player: int = -1
var is_weapon: bool = true
## Damage that landed (never more than the zombie had left).
var damage: float = 0.0
var kills: int = 0
## Seconds the player had this weapon while the run was going (its old weapon's time included).
var seconds: float = 0.0
## Level at the end of the run.
var level: int = 1
var evolved: bool = false


## Damage per second held (0 if never held).
func dps() -> float:
	return damage / seconds if seconds > 0.0 else 0.0


func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"name": display_name,
		"player": player,
		"weapon": is_weapon,
		"damage": roundi(damage),
		"kills": kills,
		"seconds_held": snappedf(seconds, 0.1),
		"level": level,
		"evolved": evolved,
	}
