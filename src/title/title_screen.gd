class_name TitleScreen
extends Control
## The first screen: "Stuffed", Start run, Quit. Works with mouse and keyboard.

signal start_requested
signal quit_requested

@onready var title_label: Label = %TitleLabel
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	version_label.text = GameInfo.version_label()
	start_button.pressed.connect(start_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	start_button.grab_focus()
