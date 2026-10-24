class_name UiFeel
extends RefCounted
## Shared access to the menu juice: the style numbers and the "reduced animations" setting.

const STYLE: UiStyle = preload("res://data/ui/ui_style.tres")


## True when the player chose "Menu animations: reduced" (spec 04 §3): no wobble, no drops,
## instant count-ups.
static func reduced() -> bool:
	return GameSettings.reduced_motion


## How long a motion of `seconds` really takes (0 with reduced animations).
static func seconds(full: float) -> float:
	return 0.0 if reduced() else full
