extends Control
## M0 start screen: proves the build pipeline works. Replaced by the real title screen in M1.

signal quit_requested

## Tests turn this off so pressing Esc doesn't close the test runner.
var quit_on_cancel: bool = true

@onready var title_label: Label = %TitleLabel
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	version_label.text = GameInfo.version_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		quit_requested.emit()
		if quit_on_cancel:
			get_tree().quit()
