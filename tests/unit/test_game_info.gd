extends GutTest


func test_version_comes_from_project_settings() -> void:
	var expected: String = str(ProjectSettings.get_setting("application/config/version"))
	assert_eq(GameInfo.version(), expected)


func test_version_label_has_v_prefix() -> void:
	assert_eq(GameInfo.version_label(), "v" + GameInfo.version())
