class_name Hud
extends CanvasLayer
## Run information on top of the game: the timer with the goal and player 1's health.

@onready var timer_label: Label = %TimerLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel


func show_time(elapsed: float, goal: float) -> void:
	timer_label.text = TimeFormat.run_timer(elapsed, goal)


## Shows this player's health from now on.
func follow_player(player: Player) -> void:
	player.health_changed.connect(show_health)
	show_health(player.health, player.max_health)


func show_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), roundi(maximum)]
