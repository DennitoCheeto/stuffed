extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §6.1-6.4, AC-49, M3.5-06 + 07): the title screen, the pause menu (and its
## Recipes page), the town's Esc menu and Settings use the Stitched Scrapbook pieces: felt
## panels, sewn buttons, the three fonts, the felt cloth behind them; no old grey box, plain
## Button, plain slider or ColorRect is left. Settings' sliders are a thread with a sewing-button
## knob and its switches are felt switches; both react to mouse and keyboard. The level-up cards
## are felt patches that lift but never tilt, Reroll / Skip / Banish are sewn buttons with
## fabric-tag keys, and the gift box moment and the goal screen are felt too. In town (M3.5-08)
## the building card, the start weapon picker, the unlock toast, the "New building!" banner and
## the prompt are felt, and the Scrapbook has fabric-tag tabs and photo entries. The Tricks panel
## and its toast (M3.7-02) are felt too.

const FONT_FILES: Array[FontFile] = [UiFonts.FREDOKA, UiFonts.PATRICK_HAND, UiFonts.NUNITO]
## A spring is done after its length plus a little margin.
const SETTLE: float = 0.1


func after_each() -> void:
	GameSettings.reduced_motion = false
	GameSettings.damage_numbers = true
	GameSettings.set_volume(&"Master", 1.0)
	super.after_each()


## Everything visible under `root` that isn't a themed piece, as readable lines (empty = all
## themed).
func unthemed(root: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	_walk(root, found)
	return found


func _walk(node: Node, found: PackedStringArray) -> void:
	var layer: CanvasLayer = node as CanvasLayer
	if layer != null and not layer.visible:
		return
	var control: Control = node as Control
	if control != null:
		if not control.visible:
			return
		var problem: String = _problem(control)
		if not problem.is_empty():
			found.append("%s (%s): %s" % [control.name, control.get_class(), problem])
	for child: Node in node.get_children():
		_walk(child, found)


func _problem(control: Control) -> String:
	if control is BaseButton and not (control is SewnButton or control is FeltSwitch):
		return "plain button"
	if control is Slider and not control is ThreadSlider:
		return "plain slider"
	if control is ColorRect:
		return "plain colour box (use MenuCloth)"
	if control is PanelContainer or control is Panel:
		var box: StyleBox = control.get_theme_stylebox(&"panel")
		if not (box is StyleBoxFelt or box is StyleBoxEmpty):
			return "panel drawn as %s" % box.get_class()
	if control is Label or control is Button:
		var font: Font = control.get_theme_font(&"font")
		if not _is_ui_font(font):
			return "font %s" % font
	return ""


func _is_ui_font(font: Font) -> bool:
	var variation: FontVariation = font as FontVariation
	if variation != null:
		return FONT_FILES.has(variation.base_font)
	return FONT_FILES.has(font)


## Asserts that `root` has only themed pieces and shows at least one sewn button and felt panel.
func _assert_themed(root: Node, screen: String) -> void:
	var found: PackedStringArray = unthemed(root)
	assert_eq(found.size(), 0, "%s is all felt: %s" % [screen, found])
	assert_gt(_count(root, SewnButton), 0, "%s has sewn buttons" % screen)
	assert_gt(_count(root, FeltPanel), 0, "%s has a felt panel" % screen)


func _count(node: Node, kind: Variant) -> int:
	var total: int = 0
	if is_instance_of(node, kind) and (node as CanvasItem).is_visible_in_tree():
		total += 1
	for child: Node in node.get_children():
		total += _count(child, kind)
	return total


## Moves the mouse onto `point` (local px) of `control` (canvas → window coordinates).
func _point_at(control: Control, point: Vector2) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * point
	sender.mouse_motion(control.get_viewport().get_screen_transform() * canvas)
	await wait_process_frames(2)


func _click_at(control: Control, point: Vector2) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * point
	var window: Vector2 = control.get_viewport().get_screen_transform() * canvas
	sender.mouse_left_button_down(window)
	await wait_process_frames(2)
	sender.mouse_left_button_up(window)
	await wait_process_frames(2)


func _settle() -> void:
	await wait_seconds(UiFeel.STYLE.spring_seconds + SETTLE)


func test_the_check_catches_an_old_grey_button() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child_autofree(layer)
	var old: Button = Button.new()
	old.text = "Give up"
	layer.add_child(old)
	var dim: ColorRect = ColorRect.new()
	layer.add_child(dim)
	layer.add_child(SewnButton.new("Resume"))
	await wait_process_frames(1)
	assert_eq(unthemed(layer).size(), 2, "plain button and plain box found: %s" % [unthemed(layer)])


func test_ac49_the_title_screen_is_felt_with_a_hand_written_name() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	await wait_process_frames(2)
	_assert_themed(title, "title (new game)")
	assert_eq(title.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written name")
	assert_true(title.logo is HandTitle)
	assert_true(title.start_button.main, "New game is the gold button")
	assert_true(title.start_button.has_focus(), "keyboard ready")
	assert_true(title.start_button.get_parent().get_parent() == title.menu_panel.content)
	assert_true(title.cloth.is_visible_in_tree(), "the felt cloth is behind it")


func test_ac49_the_title_with_a_saved_town_and_the_start_over_question_are_felt() -> void:
	await go_to_town()
	main.show_title()
	await wait_process_frames(2)
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_eq(title.start_button.text, "Continue")
	assert_true(title.scrapbook_button.is_visible_in_tree(), "Scrapbook with a saved town")
	_assert_themed(title, "title (saved town)")
	title.start_over_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(title.confirm_box.is_visible_in_tree(), "the question is on a felt patch")
	assert_false(title.start_button.is_visible_in_tree(), "the menu steps aside")
	_assert_themed(title, "title (start over?)")
	assert_true(title.no_button.has_focus(), "the safe answer has the focus")


func test_ac49_settings_has_thread_sliders_and_felt_switches() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.settings_button.pressed.emit()
	await wait_process_frames(2)
	var page: SettingsPanel = title.settings
	assert_true(page.is_open())
	_assert_themed(page, "settings")
	assert_eq(_count(page, ThreadSlider), 3, "three thread sliders")
	assert_eq(_count(page, FeltSwitch), 2, "two felt switches")


func test_ac49_the_pause_menu_and_recipes_are_felt() -> void:
	var run: Run = await start_run()
	await tap_action("pause")
	var menu: PauseMenu = run.pause_menu
	assert_true(menu.is_open(), "Esc opens the pause menu")
	await wait_process_frames(2)
	_assert_themed(menu, "pause menu")
	assert_true(menu.resume_button.main, "Resume is the gold button")
	assert_true(menu.resume_button.has_focus(), "keyboard ready")
	assert_lt(menu.cloth.cloth_color().a, 1.0, "the run shows dimmed behind the cloth")
	menu.recipes_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(menu.recipes_page.is_visible_in_tree())
	_assert_themed(menu, "recipes")
	await tap_action("pause")
	assert_true(menu.recipes_button.has_focus(), "back on the menu, on Recipes")
	menu.settings_button.pressed.emit()
	await wait_process_frames(2)
	_assert_themed(menu, "settings (pause)")


func test_ac49_the_town_menu_is_felt() -> void:
	var town: Town = await go_to_town()
	town.open_menu()
	await wait_process_frames(2)
	_assert_themed(town.menu, "town menu")
	assert_true(town.menu.resume_button.main, "Back to the fort is the gold button")


func test_the_thread_slider_knob_grows_on_hover_and_follows_the_volume() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var slider: ThreadSlider = title.settings.master_slider
	slider.value = 1.0
	var full: Vector2 = slider.knob_center()
	slider.value = 0.5
	assert_lt(slider.knob_center().x, full.x, "the knob moves left with a lower volume")
	Sfx.history.clear()
	await _point_at(slider, slider.knob_center())
	await _settle()
	assert_almost_eq(slider.knob_grow, UiFeel.STYLE.knob_grow, 0.02, "the knob grows on hover")
	assert_true(Sfx.history.has(&"ui_hover"), "felt pat on hover")
	await _point_at(title.settings.back_button, title.settings.back_button.size / 2.0)
	await _settle()
	assert_almost_eq(slider.knob_grow, 1.0, 0.02, "back to rest when the mouse leaves")


func test_the_thread_slider_works_with_the_keyboard_and_a_click() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var slider: ThreadSlider = title.settings.master_slider
	slider.value = 0.5
	slider.grab_focus()
	await _settle()
	assert_true(slider.is_raised(), "focus raises the knob")
	await tap_action("ui_left")
	assert_almost_eq(GameSettings.volume(&"Master"), 0.45, 0.01, "left arrow turns it down")
	await _click_at(slider, Vector2(slider.size.x * 0.25, slider.size.y / 2.0))
	assert_lt(GameSettings.volume(&"Master"), 0.35, "a click on the thread moves the knob there")


func test_the_felt_switch_flips_with_a_click_or_enter_and_slides_its_knob() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	# Let the page finish dropping in, so the click lands where the switch rests.
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var switch: FeltSwitch = title.settings.reduced_motion_check
	assert_false(switch.button_pressed)
	var off_knob: Vector2 = switch.knob_center()
	Sfx.history.clear()
	await _click_at(switch, switch.size / 2.0)
	assert_true(GameSettings.reduced_motion, "a click turns it on")
	assert_true(Sfx.history.has(&"ui_press"), "boop")
	await _settle()
	assert_gt(switch.knob_center().x, off_knob.x, "the knob slid to the right")
	switch.grab_focus()
	await tap_action("ui_accept")
	await wait_process_frames(2)
	assert_false(GameSettings.reduced_motion, "Enter turns it off again")
	title.settings.close()
	GameSettings.reduced_motion = true
	title.open_settings()
	assert_true(switch.button_pressed, "opening shows the saved setting")
	assert_eq(switch.slide, 1.0, "the knob is already on the right side")


## Starts a quiet run and levels Banane up once; returns once the cards can be picked.
func _level_up_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	var hero: Player = first_player()
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	return run


func _gift_showing(run: Run) -> bool:
	return run.gift_screen.showing_contents


func test_ac49_the_level_up_cards_are_felt_patches_with_sewn_buttons() -> void:
	var run: Run = await _level_up_run()
	var screen: LevelUpScreen = run.level_up_screen
	var found: PackedStringArray = unthemed(screen)
	assert_eq(found.size(), 0, "level-up is all felt: %s" % [found])
	assert_true(screen.cloth.is_visible_in_tree(), "the felt cloth is behind the cards")
	assert_eq(screen.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_eq(screen.cards.size(), 3)
	for card: UpgradeCard in screen.cards:
		assert_true(card is SewnButton, "a card reacts like a sewn button")
		assert_true(card.box is StyleBoxFelt, "a felt patch")
		assert_true(card.key_tag.is_visible_in_tree(), "the key number on a fabric tag")
	for button: CardControlButton in screen.controls():
		assert_true(button is SewnButton, "%s is a sewn button" % button.title_label.text)
		assert_true(button.key_tag is FabricTag, "the key on a fabric tag")
		assert_eq(button.key_tag.label.text, button.key_label.text)


func test_ac49_the_chosen_level_up_card_lifts_with_a_gold_ring_but_keeps_its_size() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	var screen: LevelUpScreen = run.level_up_screen
	var hero: Player = first_player()
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await wait_for_signal(screen.cards_shown, 3.0)
	var dropped: float = 0.0
	var turned: float = 0.0
	for i: int in 20:
		dropped = maxf(dropped, screen.cards_holder.lift)
		turned = maxf(turned, absf(screen.cards_holder.spin + screen.cards_holder.tilt))
		await wait_process_frames(1)
	assert_gt(dropped, 0.0, "the cards drop in")
	assert_almost_eq(turned, 0.0, 0.001, "straight, without any tilt")
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var first: UpgradeCard = screen.cards[0]
	assert_true(first.has_focus(), "keyboard ready on card 1")
	await _settle()
	assert_true(first.is_ringed(), "the chosen card has a gold ring")
	assert_almost_eq(first.lift_amount(), UiFeel.STYLE.hover_lift, 0.5, "and lifts (#157)")
	assert_almost_eq(first.face.rotation, 0.0, 0.001, "and doesn't turn")
	assert_almost_eq(first.grow_amount(), 1.0, 0.001, "and keeps its size (#151)")
	for card: UpgradeCard in screen.cards:
		assert_eq(card.size, first.size, "all three cards have one size")
	assert_false(screen.cards[1].is_ringed(), "the others rest")
	assert_almost_eq(screen.cards[1].lift_amount(), 0.0, 0.5, "and stay down")
	Sfx.history.clear()
	await tap_action("ui_right")
	await _settle()
	assert_true(screen.cards[1].has_focus(), "arrow keys move along the cards")
	assert_true(screen.cards[1].is_ringed())
	assert_false(first.is_ringed(), "card 1 loses its ring")
	assert_almost_eq(first.lift_amount(), 0.0, 0.5, "and settles back")
	# (The headless test window has GUT's own panel over that spot: send the hover itself.)
	screen.cards[2].mouse_entered.emit()
	await _settle()
	assert_true(screen.cards[2].has_focus(), "the mouse moves the choice")
	assert_true(screen.cards[2].is_ringed())
	assert_false(screen.cards[1].is_ringed(), "only one card is ever chosen")
	assert_almost_eq(screen.cards[2].lift_amount(), UiFeel.STYLE.hover_lift, 0.5, "it lifts")
	assert_almost_eq(screen.cards[1].lift_amount(), 0.0, 0.5, "the old choice settles: one raised")
	assert_almost_eq(screen.cards[2].grow_amount(), 1.0, 0.001, "without growing")
	assert_true(Sfx.history.has(&"ui_hover"), "felt pat")


func test_a_used_up_card_button_says_nope() -> void:
	var run: Run = await _level_up_run()
	var screen: LevelUpScreen = run.level_up_screen
	for i: int in 3:
		await tap_action("reroll_cards")
		await wait_process_frames(2)
	assert_true(screen.reroll_button.disabled, "no rerolls left")
	Sfx.history.clear()
	await tap_action("reroll_cards")
	assert_true(Sfx.history.has(&"ui_nope"), "nope sound")
	assert_true(screen.reroll_button.is_wiggling(), "nope wiggle")


func test_ac49_the_gift_box_moment_is_felt() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	run.pickups.buttons.clear()
	run.drop_gift_box(first_player().position)
	await wait_until(_gift_showing.bind(run), 5.0)
	var gift: GiftBoxScreen = run.gift_screen
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var found: PackedStringArray = unthemed(gift)
	assert_eq(found.size(), 0, "gift box is all felt: %s" % [found])
	assert_true(gift.cloth.is_visible_in_tree(), "the felt cloth is behind it")
	assert_eq(gift.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_true(gift.continue_button.main, "Continue is the gold button")
	assert_gt(gift.cards.size(), 0)
	for card: GiftCardView in gift.cards:
		assert_true(card.box is StyleBoxFelt, "a felt patch")
		assert_false(card.box.tape_spots.is_empty(), "taped on")
		assert_true(card.level_tag is FabricTag, "the level on a fabric tag")


func test_ac49_the_goal_screen_is_felt() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	run.freeze(&"goal")
	run.goal_screen.open()
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var goal: GoalScreen = run.goal_screen
	_assert_themed(goal, "goal screen")
	assert_eq(goal.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_true(goal.end_button.main, "End run is the gold button")
	assert_false(goal.endless_button.main)
	assert_true(goal.end_button.has_focus(), "keyboard ready")
	assert_true(goal.sticker.is_visible_in_tree(), "a sticker slaps on")
	goal.visible = false
	run.unfreeze(&"goal")


## Puts Banane right below `id`'s spot (in reach of its card) and returns its building.
func _stand_at(town: Town, id: StringName) -> TownBuilding:
	var building: TownBuilding = town.buildings[id]
	var rect: Rect2 = building.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	return building


func test_ac49_the_building_card_is_a_taped_crooked_felt_patch() -> void:
	main.town.materials["coins"] = 50
	var town: Town = await go_to_town()
	await _stand_at(town, &"toy_box_armory")
	var card: BuildingCard = town.card
	assert_true(card.visible, "the card shows")
	var found: PackedStringArray = unthemed(card)
	assert_eq(found.size(), 0, "the card is all felt: %s" % [found])
	assert_true(card.box is StyleBoxFelt, "a felt patch")
	assert_false(card.box.tape_spots.is_empty(), "taped on")
	assert_ne(card.rotation, 0.0, "a little crooked")
	assert_eq(card.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written name")
	assert_true(card.level_tag.is_visible_in_tree(), "the level on a fabric tag")
	assert_eq(card.level_label.text, "Ruin")
	for counter: JarCounter in card.cost_counters.values():
		var ink: Color = counter.amount_label.get_theme_color(&"font_color")
		assert_eq(ink, UiColors.INK, "the price is ink on felt")
	var tag: StyleBox = town.prompt_label.get_theme_stylebox(&"normal")
	assert_true(tag is StyleBoxFelt, "the prompt sits on a fabric tag")


func test_ac49_the_start_weapon_picker_is_felt_with_sewn_tiles() -> void:
	var town: Town = await go_to_town()
	town.open_weapon_picker()
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var picker: StartWeaponPicker = town.picker
	_assert_themed(picker, "start weapon picker")
	assert_true(picker.cloth.is_visible_in_tree(), "the felt cloth is behind it")
	assert_eq(picker.title.label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_gt(picker.tiles.size(), 0)
	var now: SewnButton = picker.tiles[picker.current]
	assert_eq(_count(now, FabricTag), 1, "the current weapon has its Now tag")
	assert_true(now.has_focus(), "keyboard ready on the current weapon")
	await _settle()
	assert_almost_eq(now.lift_amount(), UiFeel.STYLE.hover_lift, 0.5, "the focused tile lifts")
	picker.close()


func test_ac49_the_tricks_panel_toast_and_tag_are_felt() -> void:
	main.town.building_levels["snack_bar"] = 2
	var town: Town = await go_to_town()
	assert_true(town.tricks.open(town.buildings[&"snack_bar"]))
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var panel: TricksPanel = town.tricks.panel
	_assert_themed(panel, "tricks panel")
	assert_true(panel.cloth.is_visible_in_tree(), "the felt cloth is behind it")
	assert_eq(panel.title.label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_true(panel.strip.get_theme_stylebox(&"panel") is StyleBoxFelt, "a strip of cloth")
	for patch: TrickPatch in panel.patches:
		assert_true(patch is SewnButton, "%s is a sewn patch" % patch.trick.display_name)
	panel.close()
	town.tricks.toast.show_for("Snack Bar")
	await wait_process_frames(2)
	var found: PackedStringArray = unthemed(town.tricks.toast)
	assert_eq(found.size(), 0, "the toast is all felt: %s" % [found])
	assert_eq(town.tricks.toast.title_label.get_theme_font(&"font"), UiFonts.hand())


func test_ac49_the_unlock_toast_and_the_new_building_banner_are_felt() -> void:
	var town: Town = await go_to_town()
	var pool: UpgradePool = Town.UPGRADE_POOL
	var weapons: Array[UpgradeDef] = []
	for id: StringName in [&"thimble_mortar", &"bouncy_yarn_ball"]:
		weapons.append(pool.find(id))
	town.unlock_toast.show_weapons(weapons)
	await wait_process_frames(2)
	var toast: WeaponUnlockToast = town.unlock_toast
	var found: PackedStringArray = unthemed(toast)
	assert_eq(found.size(), 0, "the toast is all felt: %s" % [found])
	assert_false(toast.box.tape_spots.is_empty(), "taped on")
	assert_eq(toast.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	town.show_banner("New building!", "Lucky Jar can be rebuilt now")
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	assert_true(town.is_banner_showing())
	found = unthemed(town.banner)
	assert_eq(found.size(), 0, "the banner is all felt: %s" % [found])
	assert_true(town.banner is FeltPanel, "a felt patch")
	assert_eq(town.banner_title.get_theme_font(&"font"), UiFonts.hand(), "hand-written title")
	assert_almost_eq(town.banner.lift, 0.0, 0.5, "dropped into place")


func test_ac49_the_scrapbook_has_fabric_tag_tabs_and_photo_entries() -> void:
	main.town.mark_seen(ScrapbookRules.WEAPONS, "peel_boomerang")
	var town: Town = await go_to_town()
	town.open_scrapbook()
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var book: ScrapbookBook = town.book
	_assert_themed(book, "scrapbook")
	assert_true(book.cloth.is_visible_in_tree(), "the felt cloth is behind it")
	for tab: Button in book.tabs:
		assert_true(tab is SewnButton, "%s is a fabric tag button" % tab.text)
	var open_tab: SewnButton = book.tabs[0] as SewnButton
	assert_eq(open_tab.box.fill, ScrapbookBook.TAB_ON_COLOR, "the open page's tag is marked")
	assert_eq((book.tabs[1] as SewnButton).box.fill, ScrapbookBook.TAB_COLOR)
	var photo: ScrapbookTile = book.tile_for("peel_boomerang")
	assert_eq(photo.box.fill, UiColors.PHOTO, "a found entry is a photo")
	assert_false(photo.box.tape_spots.is_empty(), "taped in")
	assert_ne(photo.lean(), 0.0, "a bit crooked")
	var waiting: ScrapbookTile = book.tile_for("zipper_ray")
	assert_true(waiting.box.tape_spots.is_empty(), "no photo yet: a plain felt patch")
	assert_eq(waiting.lean(), 0.0)
	assert_true(book.detail_photo is PhotoFrame, "the details show a taped photo")
	assert_eq(book.detail_name.get_theme_font(&"font"), UiFonts.hand(), "hand-written name")
	assert_true(photo.has_focus())
	await _settle()
	assert_almost_eq(photo.lift_amount(), UiFeel.STYLE.hover_lift, 0.5, "the focused photo lifts")
	book.turn(1)
	assert_eq((book.tabs[1] as SewnButton).box.fill, ScrapbookBook.TAB_ON_COLOR, "the tag follows")
	book.close()
