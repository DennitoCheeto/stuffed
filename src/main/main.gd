class_name Main
extends Node
## The game's root: shows one screen at a time (title, town, run or end screen) and handles
## app-wide keys like fullscreen. The loop: title -> town -> run -> "Brought home" -> town.

signal quit_requested

const TITLE_SCENE: PackedScene = preload("res://src/title/title_screen.tscn")
const TOWN_SCENE: PackedScene = preload("res://src/town/town.tscn")
const RUN_SCENE: PackedScene = preload("res://src/run/run.tscn")
const SIEGE_SCENE: PackedScene = preload("res://src/siege/siege.tscn")
const END_SCENE: PackedScene = preload("res://src/ui/end_screen.tscn")
const MATERIAL_RULES: MaterialRules = preload("res://data/town/material_rules.tres")
## Where the town's buildings stand (their levels decide what changes in a run).
const TOWN_LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
## Who can be rescued in a run (for the name on the "Brought home" screen).
const RESCUE_RULES: RescueRules = preload("res://data/town/rescue_rules.tres")
## Plushies living in town add coins to every run.
const PLUSHIE_RULES: PlushieTownRules = preload("res://data/town/plushie_town_rules.tres")
## Which run titles a finished run earns (spec 04 §4.2).
const RUN_TITLES: RunTitleRules = preload("res://data/ui/run_titles.tres")
## When the night siege comes (spec 07 §3).
const SIEGE_RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")

## Tests turn this off so "Quit" doesn't close the test runner.
var quit_enabled: bool = true
## The screen that is currently shown (title, town, run or end screen).
var current_screen: Node
## Background music (title, town, run and boss tracks).
var music: MusicPlayer
## The saved town (spec 03 §9). Loaded at start, saved after every run and on quit.
var town: TownSave
## How many players play together (everybody who came home from the last run walks in town).
var player_count: int = 1
## What the town shows on arrival after a siege (title, subtitle; empty = nothing).
var _siege_news: PackedStringArray = []


func _ready() -> void:
	add_to_group(SettingsPanel.HINT_KEEPERS)
	GameSettings.load_saved()
	GameSettings.apply_screen()
	load_town()
	FeltAtlas.bake(self)
	Sfx.attach(self)
	music = MusicPlayer.new()
	music.name = "Music"
	add_child(music)
	show_title()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func show_title() -> void:
	Crosshair.stop()
	_play_music(&"title")
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.start_requested.connect(show_town)
	title.quit_requested.connect(quit)
	title.start_over_requested.connect(start_over)
	title.has_save = SaveStore.exists()
	title.save = town
	_switch_to(title)


## The Pillow Fort between runs (Continue / New game, and after every run).
func show_town() -> void:
	Crosshair.stop()
	_play_music(&"town")
	# A new game is saved right away, so the title offers Continue next time.
	SaveStore.write(town)
	var pillow_fort: Town = TOWN_SCENE.instantiate()
	pillow_fort.save = town
	pillow_fort.player_count = player_count
	pillow_fort.bedroom_requested.connect(start_run)
	pillow_fort.siege_requested.connect(start_siege)
	pillow_fort.welcome_banner = _siege_news
	_siege_news = PackedStringArray()
	pillow_fort.title_requested.connect(show_title)
	pillow_fort.quit_requested.connect(quit)
	pillow_fort.changed.connect(save_now)
	pillow_fort.reset_requested.connect(_reset_town)
	_switch_to(pillow_fort)


## Starts a fresh run; `seed_value` 0 = a random seed (the developer menu replays seeds). While
## the horde is due no expedition starts (spec 07 §2): "Try again" goes back to the town.
func start_run(seed_value: int = 0) -> void:
	if SIEGE_RULES.is_due(town):
		show_town()
		return
	var run: Run = RUN_SCENE.instantiate()
	run.finished.connect(show_end)
	run.gave_up.connect(show_end)
	run.seed_value = seed_value
	run.player_count = player_count
	run.perks = TownPerks.from_save(town, TOWN_LAYOUT)
	run.restart_requested.connect(start_run)
	run.music_requested.connect(_play_music)
	run.checkpoint_due.connect(save_now)
	town.runs_started += 1
	run.run_number = town.runs_started
	run.rescued_before = PackedStringArray(town.plushies.keys())
	town.unfinished_run = run.haul.to_dict()
	SaveStore.write(town)
	RunHints.attach(run, town)
	_play_music(&"run")
	_switch_to(run)


## The night siege in the town (spec 07 §2). Saved on start; closing the game during it leaves
## it due, so it starts over next time (nothing is lost).
func start_siege() -> void:
	var siege: Siege = SIEGE_SCENE.instantiate()
	siege.town_save = town
	siege.number = town.sieges_played + 1
	siege.player_count = player_count
	siege.perks = TownPerks.from_save(town, TOWN_LAYOUT)
	siege.finished.connect(_end_siege)
	siege.gave_up.connect(_end_siege)
	siege.restart_requested.connect(func(_seed_value: int) -> void: start_siege())
	siege.music_requested.connect(_play_music)
	town.unfinished_run = {}
	SaveStore.write(town)
	_play_music(&"siege")
	_switch_to(siege)


## A siege ended (won, lost, or given up = lost; spec 07 §6, AC-80): won brings the reward
## home, lost a consolation haul and damages every building knocked down in the fight. The
## countdown starts again, all saved at once; the end screen shows how it went, and the town
## tells it again on arrival.
func _end_siege(result: RunResult) -> void:
	player_count = maxi(Players.all(get_tree()).size(), 1)
	var won: bool = result.won
	var before: Dictionary[String, int] = town.materials.duplicate()
	var haul: Dictionary[String, int] = SIEGE_RULES.haul_for(result.siege_number, won)
	town.add_materials(haul)
	result.materials_kept = haul
	var damaged: PackedStringArray = []
	if not won:
		for id: String in result.knocked_down:
			if town.building_level(id) > 0 and not town.is_damaged(id):
				damaged.append(id)
		town.damage(damaged)
	result.damaged = damaged
	SIEGE_RULES.siege_ended(town, won)
	SaveStore.write(town)
	RunLog.append(result)
	if won:
		_siege_news = PackedStringArray([SIEGE_RULES.won_banner, SIEGE_RULES.won_subtitle])
	elif damaged.is_empty():
		_siege_news = PackedStringArray([SIEGE_RULES.lost_banner, SIEGE_RULES.lost_subtitle])
	else:
		var repair_note: String = KeyBindings.fill(SIEGE_RULES.damaged_subtitle)
		_siege_news = PackedStringArray([SIEGE_RULES.lost_banner, repair_note])
	music.play_stinger(&"siege_won" if won else &"siege_lost")
	Crosshair.stop()
	_play_music(&"town")
	var end: EndScreen = END_SCENE.instantiate()
	end.show_result(result)
	end.brought_home.show_haul(haul, before, 1.0)
	end.brought_home.show_siege(
		SIEGE_RULES.won_note if won else SIEGE_RULES.lost_note, _damaged_line(damaged)
	)
	end.brought_home.show_horde(SIEGE_RULES.end_line(town.siege_nights))
	end.fort_requested.connect(show_town)
	end.try_again_requested.connect(show_town)
	_switch_to(end)


## "Damaged: Snack Bar, Lucky Jar. Repair them at the fort." ("" = nothing was damaged).
func _damaged_line(ids: PackedStringArray) -> String:
	if ids.is_empty():
		return ""
	var names: PackedStringArray = []
	for id: String in ids:
		var spot: TownSpot = TOWN_LAYOUT.spot(StringName(id))
		names.append(spot.building.display_name if spot != null else id)
	return SIEGE_RULES.damaged_line % ", ".join(names)


## The end screen for a finished or given-up run (also written to the run log): its stats and
## what it brought home, counting into the jars.
func show_end(result: RunResult) -> void:
	# The portal (or the end) takes everybody home, the fallen too.
	player_count = maxi(Players.all(get_tree()).size(), 1)
	var before: Dictionary[String, int] = town.materials.duplicate()
	var share: float = MATERIAL_RULES.keep_share(result)
	var bonus: float = coin_bonus()
	var titles: Array[RunTitle] = _earn_titles(result)
	# One more night went by (spec 07 §3); saved with the haul.
	SIEGE_RULES.night_passed(town)
	var kept: Dictionary[String, int] = _bank_run(share, bonus)
	result.materials_kept = kept
	var hints: RunHints = RunHints.of(current_screen)
	if hints != null:
		result.hints = hints.shown
	RunLog.append(result)
	Crosshair.stop()
	_play_music(&"town")
	var end: EndScreen = END_SCENE.instantiate()
	end.show_result(result)
	end.show_titles(titles, RUN_TITLES.slap_gap)
	end.brought_home.show_haul(kept, before, share, bonus)
	end.brought_home.show_horde(SIEGE_RULES.end_line(town.siege_nights))
	var rescued: PlushieDef = RESCUE_RULES.find(result.rescued_plushie())
	if rescued != null:
		end.brought_home.show_rescue(rescued.display_name, rescued)
	end.try_again_requested.connect(start_run)
	end.fort_requested.connect(show_town)
	_switch_to(end)


## The run titles `result` earned (rarest first); first-time ones are marked new and remembered
## (saved with the haul right after).
func _earn_titles(result: RunResult) -> Array[RunTitle]:
	var run: Run = current_screen as Run
	if run != null:
		result.new_scrapbook_entries = town.new_entries(run.haul)
	var titles: Array[RunTitle] = RUN_TITLES.pick(result)
	for title: RunTitle in titles:
		title.is_new = town.note_title(title.id)
		result.titles.append(title.id)
	return titles


func _play_music(track: StringName) -> void:
	MusicPlayer.set_muffled(false)
	music.play_track(track)


## Loads the saved town. A run the game closed during counts as given up (spec 03 §9). The
## Recipes page remembers the evolutions in the saved Scrapbook.
func load_town() -> void:
	town = SaveStore.read()
	if town.settle_unfinished_run(MATERIAL_RULES.keep_share_lost, coin_bonus()):
		SIEGE_RULES.night_passed(town)
		SaveStore.write(town)
	RecipeBook.load_from(town)


## Saves the town now; a run that is still going is saved with its haul so far, so closing the
## game doesn't lose it (it counts as given up on the next start).
func save_now() -> void:
	var run: Run = current_screen as Run
	# A siege isn't an expedition: closing during it just leaves it due (spec 07 §8).
	if run != null and not run.over and not run is Siege:
		town.unfinished_run = run.haul.to_dict()
	SaveStore.write(town)


## "Start over" on the title screen: the whole town is gone.
func start_over() -> void:
	SaveStore.delete_all()
	town = TownSave.new()
	RecipeBook.load_from(town)


## The developer menu's "Reset town": a fresh town, right away.
func _reset_town() -> void:
	start_over()
	show_town()


## Extra share of coins every run brings home, from the plushies living in town (spec 03 §7).
func coin_bonus() -> float:
	return town.plushies_in_town() * PLUSHIE_RULES.coin_bonus_per_plushie


## Takes `share` of the finished run's haul home (coins plus `bonus`) and saves. Returns what
## was kept.
func _bank_run(share: float, bonus: float) -> Dictionary[String, int]:
	var kept: Dictionary[String, int] = {}
	var run: Run = current_screen as Run
	if run != null:
		kept = run.haul.kept(share, bonus)
		town.bank(run.haul, share, bonus)
	town.unfinished_run = {}
	SaveStore.write(town)
	return kept


## Closing the window saves first (a running run stays "unfinished" until the next start).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and town != null:
		save_now()


func quit() -> void:
	quit_requested.emit()
	save_now()
	if quit_enabled:
		get_tree().quit()


func toggle_fullscreen() -> void:
	GameSettings.window_mode = GameSettings.toggled_mode(GameSettings.window_mode)
	GameSettings.apply_screen()
	GameSettings.save()
	get_tree().call_group(SettingsPanel.GROUP, &"sync_screen")


func _switch_to(screen: Node) -> void:
	if current_screen != null:
		current_screen.queue_free()
		remove_child(current_screen)
	current_screen = screen
	add_child(screen)


## Settings → "Show hints again" (spec 10 §6): every first-time hint shows again.
func forget_hints() -> void:
	HintBook.forget(town)
	SaveStore.write(town)
