class_name SaveStore
extends RefCounted
## Reads and writes the town save (spec 03 §9). One save in M3, as JSON in user://.
## On Windows: %APPDATA%\Godot\app_userdata\Stuffed\save.json.
## Every write first keeps the last good save as a backup; a damaged save loads the backup.

enum Source { NEW, MAIN, BACKUP }

const DEFAULT_PATH: String = "user://save.json"

## Tests point this at a scratch file.
static var path: String = DEFAULT_PATH
## Where the last read() found the save (for tests and the log).
static var last_source: Source = Source.NEW


static func backup_path() -> String:
	return path.get_basename() + ".backup.json"


static func _temp_path() -> String:
	return path.get_basename() + ".tmp"


## True if there is a save (or at least its backup) on disk.
static func exists() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(backup_path())


## Writes `save` safely: new data goes to a temp file first, the old good save becomes the
## backup, then the temp file takes its place. Returns false if it couldn't be written.
static func write(save: TownSave) -> bool:
	var file: FileAccess = FileAccess.open(_temp_path(), FileAccess.WRITE)
	if file == null:
		push_warning("Save not written: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(save.to_dict(), "\t"))
	file.close()
	if _read_dict(path) != null:
		DirAccess.copy_absolute(path, backup_path())
	DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(_temp_path(), path) == OK


## The saved town: the main file, else the backup, else a brand-new town.
static func read() -> TownSave:
	var data: Variant = _read_dict(path)
	last_source = Source.MAIN
	if data == null:
		data = _read_dict(backup_path())
		last_source = Source.BACKUP
	if data == null:
		last_source = Source.NEW
		return TownSave.new()
	return TownSave.from_dict(data as Dictionary)


## "Start over": removes the save, its backup and any half-written file.
static func delete_all() -> void:
	for file_path: String in [path, backup_path(), _temp_path()]:
		DirAccess.remove_absolute(file_path)


## The file's contents if it is a readable save, else null (missing, damaged, not a save).
static func _read_dict(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	# A JSON object (not JSON.parse_string): a damaged file must not print an engine error.
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return null
	var parsed: Variant = json.data
	if not parsed is Dictionary or not (parsed as Dictionary).has("version"):
		return null
	return parsed
