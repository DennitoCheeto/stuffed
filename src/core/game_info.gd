class_name GameInfo
extends RefCounted
## Facts about the game build, shown on screen and in bug reports.


static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


static func version_label() -> String:
	return "v%s" % version()
