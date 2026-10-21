class_name Hud
extends CanvasLayer
## Run information on top of the game: the timer with the goal, player 1's health, XP and level.

@onready var timer_label: Label = %TimerLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel


func show_time(elapsed: float, goal: float) -> void:
	timer_label.text = TimeFormat.run_timer(elapsed, goal)


## Shows this player's health from now on.
func follow_player(player: Player) -> void:
	player.health_changed.connect(show_health)
	show_health(player.health, player.max_health)
	player.progress.xp_changed.connect(show_xp)
	show_xp(player.progress.xp, player.progress.xp_needed(), player.progress.level)


func show_xp(xp: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	level_label.text = "Lv %d" % level


func show_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), roundi(maximum)]
