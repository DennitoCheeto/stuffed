extends GutTest
## Spec 04 §2-3 (M3.5-01): the Stitched Scrapbook style foundation.

const TEST_SETTINGS: String = "user://test_unit_settings.json"
const THEME_PATH: String = "res://data/ui/stuffed_theme.tres"

var _saved_volumes: Dictionary[StringName, float] = {}


func before_each() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	for bus: StringName in GameSettings.BUSES:
		_saved_volumes[bus] = GameSettings.volume(bus)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.path = GameSettings.DEFAULT_PATH
	GameSettings.reduced_motion = false
	GameSettings.damage_numbers = true
	for bus: StringName in _saved_volumes:
		GameSettings.set_volume(bus, _saved_volumes[bus])


func test_motions_are_short_and_closing_is_quick() -> void:
	var style: UiStyle = UiFeel.STYLE
	assert_lte(style.longest_element_seconds(), 0.4, "every element moves for at most 0.4 s")
	assert_lte(style.close_seconds, 0.2, "closing never feels slow")
	assert_gt(style.hover_grow, 1.0, "hover grows")
	assert_lt(style.press_squish, 1.0, "press squishes")
	assert_gt(style.hover_lift, 0.0, "hover lifts")


func test_stitch_dashes_follow_the_outline() -> void:
	var square: PackedVector2Array = [
		Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)
	]
	var dashes: PackedVector2Array = FeltDraw.dashes(square, 10.0, 10.0)
	assert_eq(dashes.size(), 40, "400 px around, one 10 px dash every 20 px = 20 dashes")
	for index: int in range(0, dashes.size(), 2):
		var length: float = dashes[index].distance_to(dashes[index + 1])
		assert_almost_eq(length, 10.0, 0.01, "dash %d is 10 px" % (index / 2.0))


func test_felt_box_presses_into_its_edge_and_keeps_room_for_it() -> void:
	var box: StyleBoxFelt = StyleBoxFelt.new()
	box.depth = 6.0
	box.pad(40, 12)
	assert_eq(box.content_margin_bottom, 18.0, "the bottom edge is kept free")
	var rect: Rect2 = Rect2(0, 0, 200, 60)
	assert_eq(box.face_rect(rect).position.y, 0.0, "resting on its edge")
	box.press = 1.0
	assert_eq(box.face_rect(rect).position.y, 6.0, "pressed all the way into the edge")
	assert_false(box.stitch_points(rect).is_empty(), "stitched")
	box.stitch_inset = 0.0
	assert_true(box.stitch_points(rect).is_empty(), "no stitches when the inset is 0")


func test_fonts_and_theme() -> void:
	var heading: FontVariation = UiFonts.heading() as FontVariation
	assert_eq(heading.base_font, UiFonts.FREDOKA, "headings are Fredoka")
	assert_eq(UiFonts.hand(), UiFonts.PATRICK_HAND, "hand-written bits are Patrick Hand")
	var body: FontVariation = UiFonts.body() as FontVariation
	assert_eq(body.base_font, UiFonts.NUNITO, "body text is Nunito")
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), THEME_PATH, "project-wide theme")
	var theme: Theme = load(THEME_PATH) as Theme
	var default_font: FontVariation = theme.default_font as FontVariation
	assert_eq(default_font.base_font, UiFonts.NUNITO, "the game's default font is Nunito")


func test_a_wobbly_piece_keeps_its_tilt_and_lift_inside_a_container() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	add_child_autofree(row)
	var panel: FeltPanel = FeltPanel.new(3.0)
	panel.custom_minimum_size = Vector2(300, 200)
	row.add_child(panel)
	panel.lift = 20.0
	await wait_process_frames(2)
	row.queue_sort()
	await wait_process_frames(2)
	assert_almost_eq(panel.body.rotation, deg_to_rad(3.0), 0.0001, "tilt survives a re-sort")
	assert_eq(panel.body.position.y, -20.0, "lift survives a re-sort")
	assert_eq(panel.size, Vector2(300, 200), "the layout never notices the motion")
	panel.rest()
	assert_eq(panel.body.position.y, 0.0, "back to rest")


func test_sewn_button_keeps_its_text_in_step() -> void:
	var button: SewnButton = SewnButton.new("Back to the fort", true)
	add_child_autofree(button)
	await wait_process_frames(1)
	assert_eq(button.caption.text, "Back to the fort")
	button.text = "Try again"
	await wait_process_frames(1)
	assert_eq(button.caption.text, "Try again", "the face shows the new text")
	assert_gte(button.size.x, button.face.get_combined_minimum_size().x, "the face fits")


func test_settings_save_reload_compare() -> void:
	GameSettings.reduced_motion = true
	GameSettings.damage_numbers = false
	GameSettings.set_volume(&"Music", 0.25)
	assert_true(GameSettings.save(), "written")
	var saved: Dictionary = GameSettings.to_dict()
	GameSettings.reduced_motion = false
	GameSettings.damage_numbers = true
	GameSettings.set_volume(&"Music", 1.0)
	GameSettings.load_saved()
	var loaded: Dictionary = GameSettings.to_dict()
	assert_eq(loaded["reduced_motion"], saved["reduced_motion"], "reduced animations kept")
	assert_eq(loaded["damage_numbers"], saved["damage_numbers"], "damage numbers kept")
	for bus: StringName in GameSettings.BUSES:
		var before: float = (saved["volumes"] as Dictionary)[String(bus)]
		var after: float = (loaded["volumes"] as Dictionary)[String(bus)]
		assert_almost_eq(after, before, 0.001, "%s volume kept" % bus)
	assert_true(GameSettings.reduced_motion, "reduced animations on")
	assert_almost_eq(GameSettings.volume(&"Music"), 0.25, 0.001, "music volume kept")


func test_no_settings_file_means_defaults() -> void:
	GameSettings.reduced_motion = true
	GameSettings.damage_numbers = false
	GameSettings.load_saved()
	assert_false(GameSettings.reduced_motion, "full animations by default")
	assert_true(GameSettings.damage_numbers, "damage numbers on by default")
