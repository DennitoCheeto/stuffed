class_name RecipeBook
extends RefCounted
## Which evolutions the player has seen, for the Recipes page (unseen ones show as "?").
## Evolving marks one at once; across sessions it comes from the saved Scrapbook (evolved
## weapons are on its Weapons page): Main calls `load_from` when the town is loaded.

static var seen: Dictionary[StringName, bool] = {}


static func mark_seen(evolved_id: StringName) -> void:
	seen[evolved_id] = true


static func is_seen(evolved_id: StringName) -> bool:
	return seen.has(evolved_id)


## Forgets everything, then remembers every weapon the saved Scrapbook has seen.
static func load_from(save: TownSave) -> void:
	seen.clear()
	var weapons: PackedStringArray = save.seen.get(ScrapbookRules.WEAPONS, PackedStringArray())
	for id: String in weapons:
		seen[StringName(id)] = true
