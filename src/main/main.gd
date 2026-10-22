class_name Main
extends Node
## The game's root: shows one screen at a time (title, town, run or end screen) and handles
## app-wide keys like fullscreen. The loop: title -> town -> run -> "Brought home" -> town.

signal quit_requested

const TITLE_SCENE: PackedScene = preload("res://src/title/title_screen.tscn")
const TOWN_SCENE: PackedScene = preload("res://src/town/town.tscn")
const RUN_SCENE: PackedScene = preload("res://src/run/run.tscn")
const END_SCENE: PackedScene = preload("res://src/ui/end_screen.tscn")
const MATERIAL_RULES: MaterialRules = preload("res://data/town/material_rules.tres")

## Tests turn this off so "Quit" doesn't close the test runner.
var quit_enabled: bool = true
## The screen that is currently shown (title, town, run or end screen).
var current_screen: Node
## Background music (title, town, run and boss tracks).
var music: MusicPlayer
## The saved town (spec 03 §9). Loaded at start, saved after every run and on quit.
var town: TownSave


func _ready() -> void:
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
	_switch_to(title)


## The Pillow Fort between runs (Continue / New game, and after every run).
func show_town() -> void:
	Crosshair.stop()
	_play_music(&"town")
	# A new game is saved right away, so the title offers Continue next time.
	SaveStore.write(town)
	var pillow_fort: Town = TOWN_SCENE.instantiate()
	pillow_fort.save = town
	pillow_fort.bedroom_requested.connect(start_run)
	pillow_fort.title_requested.connect(show_title)
	pillow_fort.quit_requested.connect(quit)
	_switch_to(pillow_fort)


## Starts a fresh run; `seed_value` 0 = a random seed (the developer menu replays seeds).
func start_run(seed_value: int = 0) -> void:
	var run: Run = RUN_SCENE.instantiate()
	run.finished.connect(show_end)
	run.gave_up.connect(show_end)
	run.seed_value = seed_value
	run.restart_requested.connect(start_run)
	run.music_requested.connect(_play_music)
	run.checkpoint_due.connect(save_now)
	town.runs_started += 1
	town.unfinished_run = run.haul.to_dict()
	SaveStore.write(town)
	_play_music(&"run")
	_switch_to(run)


## The end screen for a finished or given-up run (also written to the run log): its stats and
## what it brought home, counting into the jars.
func show_end(result: RunResult) -> void:
	RunLog.append(result)
	var before: Dictionary[String, int] = town.materials.duplicate()
	var share: float = MATERIAL_RULES.keep_share(result)
	var kept: Dictionary[String, int] = _bank_run(share)
	Crosshair.stop()
	_play_music(&"town")
	var end: EndScreen = END_SCENE.instantiate()
	end.show_result(result)
	end.brought_home.show_haul(kept, before, share)
	end.try_again_requested.connect(start_run)
	end.fort_requested.connect(show_town)
	_switch_to(end)


func _play_music(track: StringName) -> void:
	MusicPlayer.set_muffled(false)
	music.play_track(track)


## Loads the saved town. A run the game closed during counts as given up (spec 03 §9).
func load_town() -> void:
	town = SaveStore.read()
	if town.settle_unfinished_run(MATERIAL_RULES.keep_share_lost):
		SaveStore.write(town)


## Saves the town now; a run that is still going is saved with its haul so far, so closing the
## game doesn't lose it (it counts as given up on the next start).
func save_now() -> void:
	var run: Run = current_screen as Run
	if run != null and not run.over:
		town.unfinished_run = run.haul.to_dict()
	SaveStore.write(town)


## "Start over" on the title screen: the whole town is gone.
func start_over() -> void:
	SaveStore.delete_all()
	town = TownSave.new()


## Takes `share` of the finished run's haul home and saves. Returns what was kept.
func _bank_run(share: float) -> Dictionary[String, int]:
	var kept: Dictionary[String, int] = {}
	var run: Run = current_screen as Run
	if run != null:
		kept = run.haul.kept(share)
		town.bank(run.haul, share)
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
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var fullscreen: bool = (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _switch_to(screen: Node) -> void:
	if current_screen != null:
		current_screen.queue_free()
		remove_child(current_screen)
	current_screen = screen
	add_child(screen)
