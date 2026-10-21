class_name RecipeBook
extends RefCounted
## Which evolutions the player has seen, for the Recipes page (unseen ones show as "?").
## Kept while the game runs; saving it comes with the town (M3).

static var seen: Dictionary[StringName, bool] = {}


static func mark_seen(evolved_id: StringName) -> void:
	seen[evolved_id] = true


static func is_seen(evolved_id: StringName) -> bool:
	return seen.has(evolved_id)
