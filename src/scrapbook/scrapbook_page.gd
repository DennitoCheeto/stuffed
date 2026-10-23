class_name ScrapbookPage
extends RefCounted
## One page of the Scrapbook (Weapons, Items, Enemies, Floor pickups, Plushies) and its count.

## The key in TownSave.seen ("weapons", ...).
var id: String = ""
var title: String = ""
var entries: Array[ScrapbookEntry] = []


func _init(page_id: String, page_title: String) -> void:
	id = page_id
	title = page_title


func add(entry: ScrapbookEntry) -> ScrapbookEntry:
	entries.append(entry)
	return entry


func is_seen(entry: ScrapbookEntry, save: TownSave) -> bool:
	return save.has_seen(id, entry.id)


func seen_count(save: TownSave) -> int:
	var count: int = 0
	for entry: ScrapbookEntry in entries:
		if is_seen(entry, save):
			count += 1
	return count


## "Weapons 7 / 14".
func count_text(save: TownSave) -> String:
	return "%s %d / %d" % [title, seen_count(save), entries.size()]


## The entry with this id, or null.
func find(entry_id: String) -> ScrapbookEntry:
	for entry: ScrapbookEntry in entries:
		if entry.id == entry_id:
			return entry
	return null
