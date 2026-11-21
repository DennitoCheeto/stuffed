class_name HintBook
extends RefCounted
## Which first-time hints a save still has to show (spec 10 §6, §9). A hint the player did is
## seen; a hint that timed out shows once more next time, then it counts as seen too.


## True if `id` should show for `save` (and hints are on in Settings).
static func is_due(save: TownSave, id: String) -> bool:
	return GameSettings.hints and not save.hints_seen.has(id)


## The player did what hint `id` asked: never show it again.
static func mark_done(save: TownSave, id: String) -> void:
	if not save.hints_seen.has(id):
		save.hints_seen.append(id)
	var once: int = save.hints_once.find(id)
	if once >= 0:
		save.hints_once.remove_at(once)


## Hint `id` went away by itself: it shows once more, the second time it is seen for good.
static func timed_out(save: TownSave, id: String) -> void:
	if save.hints_once.has(id):
		mark_done(save, id)
	else:
		save.hints_once.append(id)


## "Show hints again" / dev "Reset hints": every hint shows again.
static func forget(save: TownSave) -> void:
	save.hints_seen.clear()
	save.hints_once.clear()


## An older save that already has a town: its player knows the basics (spec 10 §9).
static func knows_basics(save: TownSave, basics: PackedStringArray) -> void:
	for id: String in basics:
		mark_done(save, id)
