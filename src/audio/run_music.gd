class_name RunMusic
extends Node
## The music's side of a run or siege (spec 10 §4.1): raises the intensity as the run goes on
## (drums after `MusicRules.run_drums_seconds` or a big crowd on screen, everything after
## `run_full_seconds`; it never drops back), or per siege wave (`follow_wave`), and asks for the
## stingers: goal reached, a hero falls, a weapon evolves. Endless gets its own track. Talks to
## the `MusicPlayer` through its group, so a run without Main stays quiet.

const RULES: MusicRules = preload("res://data/audio/music/music_rules.tres")

## The intensity asked for right now (0-2).
var level: int = 0
## False in the siege: the waves set the level instead of time and crowd.
var follows_clock: bool = true
var _run: Run
var _wait: float = 0.0
var _heard: Array[Player] = []


func _init(run: Run) -> void:
	_run = run
	name = "RunMusic"


func _ready() -> void:
	_run.goal_reached.connect(sting.bind(&"goal"))
	_run.endless_started.connect(_on_endless_started)


## Siege wave `index` (0 = the first) started: the music gets busier.
func follow_wave(index: int) -> void:
	follows_clock = false
	_set_level(RULES.siege_level(index))


## How many living zombies are on screen.
func crowd() -> int:
	var view: Rect2 = _run.spawner.visible_rect()
	var count: int = 0
	for zombie: Zombie in _run.enemies.zombies:
		if is_instance_valid(zombie) and not zombie.dead and view.has_point(zombie.global_position):
			count += 1
	return count


## Plays stinger `id` over the music.
func sting(id: StringName) -> void:
	if is_inside_tree():
		get_tree().call_group(MusicPlayer.GROUP, &"play_stinger", id)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = RULES.check_seconds
	_listen_to_heroes()
	if follows_clock:
		_set_level(maxi(level, RULES.run_level(_run.elapsed, crowd())))
	else:
		_set_level(level)


func _set_level(next: int) -> void:
	level = next
	if is_inside_tree():
		get_tree().call_group(MusicPlayer.GROUP, &"set_intensity", level)


func _listen_to_heroes() -> void:
	for player: Player in Players.all(get_tree()):
		if _heard.has(player):
			continue
		_heard.append(player)
		player.died.connect(_on_hero_died)
		player.evolved.connect(_on_evolved)


func _on_hero_died(_player: Player) -> void:
	sting(&"hero_died")


func _on_evolved(_weapon: Weapon) -> void:
	sting(&"evolution")


func _on_endless_started() -> void:
	_run.music_requested.emit(&"endless")
