extends GutTest
## Scenario (spec 04 §5, AC-55): every screen fits on 1920x1080, 1920x1200, 1280x720 and
## 2560x1440 with worst-case content (6 weapons and full items, 2 players, a maxed town, a rescue,
## long upgrade lists): all buttons, panels and labels stay inside the window with a 24 px margin,
## inside their felt box, and no label is cut off. The game runs in a SubViewport the size of the
## window, stretched like the real window (canvas_items / expand).
## New screens: add a step to `_visit_all` (later M3.5 tickets do).

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
const ScreenFit: GDScript = preload("res://tests/scenarios/screen_fit.gd")
const TEST_LOG: String = "user://test_run_log.jsonl"
const TEST_SAVE: String = "user://test_save.json"
const TEST_SETTINGS: String = "user://test_settings.json"
## Frames for containers to settle after a screen opens.
const SETTLE_FRAMES: int = 4

var view: SubViewport
var main: Main
## Screens checked in this test (so a test that checks nothing fails).
var checked: PackedStringArray = []


func before_each() -> void:
	RunLog.path = TEST_LOG
	DirAccess.remove_absolute(TEST_LOG)
	SaveStore.path = TEST_SAVE
	SaveStore.delete_all()
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	checked.clear()


func after_each() -> void:
	GameSettings.reduced_motion = false


func test_ac55_every_screen_fits_at_1920x1080() -> void:
	await _visit_all(ScreenFit.WINDOWS[0])


func test_ac55_every_screen_fits_at_1920x1200() -> void:
	await _visit_all(ScreenFit.WINDOWS[1])


func test_ac55_every_screen_fits_at_1280x720() -> void:
	await _visit_all(ScreenFit.WINDOWS[2])


func test_ac55_every_screen_fits_at_2560x1440() -> void:
	await _visit_all(ScreenFit.WINDOWS[3])


func test_layout_sizes_follow_the_window_stretch() -> void:
	assert_eq(ScreenFit.layout_size(Vector2i(1920, 1080)), Vector2i(1920, 1080))
	assert_eq(ScreenFit.layout_size(Vector2i(1920, 1200)), Vector2i(1920, 1200))
	assert_eq(ScreenFit.layout_size(Vector2i(1280, 720)), Vector2i(1920, 1080))
	assert_eq(ScreenFit.layout_size(Vector2i(2560, 1440)), Vector2i(1920, 1080))


func test_the_check_catches_a_button_off_screen_and_cut_text() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child_autofree(layer)
	var button: Button = Button.new()
	button.text = "Back to the fort"
	button.position = Vector2(1880, 500)
	layer.add_child(button)
	var label: Label = Label.new()
	label.text = "A very long weapon name that will never fit"
	label.clip_text = true
	label.size = Vector2(60, 30)
	label.position = Vector2(400, 400)
	layer.add_child(label)
	await wait_process_frames(2)
	var found: PackedStringArray = ScreenFit.problems(layer, Rect2(0, 0, 1920, 1080))
	assert_eq(found.size(), 2, "both found: %s" % [found])


## Boots the game in a window of `window` px and opens every screen with busy content.
func _visit_all(window: Vector2i) -> void:
	await _boot(window)
	# Screens rest at once: their final layout is what the player looks at. (After the boot: Main
	# loads the saved settings, which would switch it back.)
	GameSettings.reduced_motion = true
	var title: TitleScreen = main.current_screen as TitleScreen
	await _check("title (new game)")
	title.open_settings()
	await _check("settings (title)")
	title.settings.close()
	title.start_button.pressed.emit()
	await _frames()
	var town: Town = main.current_screen as Town
	await _max_the_town(town)
	await _check("town")
	town.open_menu()
	await _check("town menu")
	town.menu.show_settings()
	await _check("settings (town)")
	town.menu.settings.close()
	town.menu.close()
	town.open_scrapbook()
	await _check("scrapbook")
	town.book.close()
	town.open_weapon_picker()
	await _check("start weapon picker")
	town.picker.close()
	town.open_menu()
	town.menu.title_button.pressed.emit()
	await _frames()
	title = main.current_screen as TitleScreen
	await _check("title (saved town)")
	title.press_start_over()
	await _check("title (start over?)")
	title._close_confirm()
	title.open_scrapbook()
	await _check("scrapbook (title)")
	title.book.close()
	main.player_count = 2
	title.start_button.pressed.emit()
	await _frames()
	town = main.current_screen as Town
	town.enter_bedroom()
	await _frames()
	await _visit_run(main.current_screen as Run)
	assert_eq(checked.size(), 18, "every screen checked: %s" % [checked])


func _visit_run(run: Run) -> void:
	run.rescue_plan = null
	run.spawner.active = false
	_fill_the_build(run)
	await _check("run (HUD)")
	run.pause()
	await _check("pause menu")
	run.pause_menu.show_settings()
	await _check("settings (pause)")
	run.pause_menu.settings.close()
	run.pause_menu.show_recipes()
	await _check("recipes")
	run.pause_menu.close()
	var hero: Player = Players.all(run.get_tree())[0]
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await _wait_until(run.level_up_screen.is_open)
	await wait_seconds(LevelUpScreen.MOMENT_TIME + 0.1)
	await _check("level-up")
	run.level_up_screen.picked.emit(run.level_up_screen.offers[0])
	await _frames()
	run.pickups.buttons.clear()
	run.drop_gift_box(hero.position)
	await _wait_until(_gift_shown.bind(run))
	await _check("gift box")
	run.gift_screen.close()
	await _frames()
	run.freeze(&"goal")
	run.goal_screen.open()
	await _check("goal screen")
	run.goal_screen.visible = false
	run.unfreeze(&"goal")
	_free_a_plushie(run)
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await _frames()
	var end: EndScreen = main.current_screen as EndScreen
	end.brought_home.finish()
	_longest_titles(end)
	await _check("end screen")


func _boot(window: Vector2i) -> void:
	view = SubViewport.new()
	view.size = window
	view.size_2d_override = ScreenFit.layout_size(window)
	view.size_2d_override_stretch = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(view)
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	view.add_child(main)
	await _frames()


## Checks the whole game for things that don't fit; `screen` names it in the failure.
func _check(screen: String) -> void:
	await _frames()
	checked.append(screen)
	var found: PackedStringArray = ScreenFit.problems(main, view.get_visible_rect())
	assert_eq(found, PackedStringArray(), "%s at %s fits" % [screen, view.size])


func _frames() -> void:
	await wait_process_frames(SETTLE_FRAMES)


func _wait_until(done: Callable) -> void:
	var left: int = 300
	while not done.call() and left > 0:
		left -= 1
		await wait_process_frames(1)
	assert_true(done.call(), "waited for the screen")


func _gift_shown(run: Run) -> bool:
	return run.gift_screen.showing_contents


## Every building at its top level and full jars: the longest cards and the Armory picker.
func _max_the_town(town: Town) -> void:
	for building: TownBuilding in town.buildings.values():
		while town.dev_build(building):
			pass
	for material: String in town.save.materials:
		town.save.materials[material] = 99999
	town.refresh()
	await wait_seconds(2.0)


## 6 weapons (long names), every item slot, all at their top level; player 2 gets the same build
## (two full weapon columns on the end screen).
func _fill_the_build(run: Run) -> void:
	run.dev_menu.max_everything()
	var players: Array[Player] = Players.all(run.get_tree())
	var first: Player = players[0]
	for other: Player in players.slice(1):
		for weapon: Weapon in other.weapons():
			weapon.get_parent().remove_child(weapon)
			weapon.free()
		for weapon: Weapon in first.weapons():
			var copy: Weapon = other.add_weapon(weapon.stats)
			while copy.level < weapon.level:
				copy.level_up()
		other.items = first.items.duplicate()
		other.item_levels = first.item_levels.duplicate()


## The two longest titles that can come together, both new (with their "New!" stickers).
func _longest_titles(end: EndScreen) -> void:
	var titles: Array[RunTitle] = []
	for words: String in ["Endless Explorer", "Evolution Expert"]:
		var title: RunTitle = RunTitle.new(words, words, 4)
		title.is_new = true
		titles.append(title)
	end.title_label.text = "Banane got stuffed"
	end.show_titles(titles)


func _free_a_plushie(run: Run) -> void:
	var plushie: TangledPlushie = run.start_rescue()
	plushie.freed.emit(Players.all(run.get_tree())[0])
