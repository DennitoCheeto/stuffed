class_name RunHaul
extends RefCounted
## What a run has collected for the town so far (spec 03 §3): materials and a freed plushie.
## Saved every few seconds while the run goes, so closing the game never loses it.

## Material id ("coins", "stuffing", "thread") -> amount collected in this run.
var materials: Dictionary[String, int] = {}
## Id of the plushie freed in this run ("" = none).
var rescued: String = ""


func add(material: String, amount: int) -> void:
	materials[material] = materials.get(material, 0) + amount


func amount(material: String) -> int:
	return materials.get(material, 0)


## What goes home when `share` of the haul is kept (0.5 = half), each amount rounded up. Coins
## get `coin_bonus` more on top (0.1 = +10%, from plushies living in town).
func kept(share: float, coin_bonus: float = 0.0) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for material: String in materials:
		var boost: float = 1.0 + coin_bonus if material == "coins" else 1.0
		result[material] = ceili(materials[material] * share * boost - 0.0001)
	return result


func to_dict() -> Dictionary:
	return {"materials": materials.duplicate(), "rescued": rescued}


static func from_dict(data: Dictionary) -> RunHaul:
	var haul: RunHaul = RunHaul.new()
	var saved: Variant = data.get("materials", {})
	if saved is Dictionary:
		for key: Variant in saved:
			haul.materials[str(key)] = int(saved[key])
	haul.rescued = str(data.get("rescued", ""))
	return haul
