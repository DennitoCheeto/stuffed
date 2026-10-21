class_name PauseMenu
extends CanvasLayer
## The Esc menu: Resume, damage numbers on/off, Master / Effects / Music volume, Quit to title.
## Changes take effect right away. Keeps running while the run is frozen.

signal resumed
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var damage_numbers_check: CheckButton = %DamageNumbersCheck
@onready var master_slider: HSlider = %MasterSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	quit_button.pressed.connect(quit_requested.emit)
	damage_numbers_check.toggled.connect(_on_damage_numbers_toggled)
	master_slider.value_changed.connect(_on_volume_changed.bind(&"Master"))
	effects_slider.value_changed.connect(_on_volume_changed.bind(&"Effects"))
	music_slider.value_changed.connect(_on_volume_changed.bind(&"Music"))


func is_open() -> bool:
	return visible


func open() -> void:
	damage_numbers_check.set_pressed_no_signal(GameSettings.damage_numbers)
	master_slider.set_value_no_signal(GameSettings.volume(&"Master"))
	effects_slider.set_value_no_signal(GameSettings.volume(&"Effects"))
	music_slider.set_value_no_signal(GameSettings.volume(&"Music"))
	visible = true
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _on_damage_numbers_toggled(on: bool) -> void:
	GameSettings.damage_numbers = on


func _on_volume_changed(value: float, bus: StringName) -> void:
	GameSettings.set_volume(bus, value)
