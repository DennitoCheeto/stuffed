class_name Hud
extends CanvasLayer
## Run information on top of the game: the timer with the goal.

@onready var timer_label: Label = %TimerLabel


func show_time(elapsed: float, goal: float) -> void:
	timer_label.text = TimeFormat.run_timer(elapsed, goal)
