class_name EndScreen
extends Control
## After a run: "You survived!" or "Banane got stuffed", the run's stats, and Try again.

signal try_again_requested
signal title_requested

var result: RunResult

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var upgrades_label: Label = %UpgradesLabel
@onready var seed_label: Label = %SeedLabel
@onready var try_again_button: Button = %TryAgainButton
@onready var title_button: Button = %TitleButton


func _ready() -> void:
	try_again_button.pressed.connect(try_again_requested.emit)
	title_button.pressed.connect(title_requested.emit)
	try_again_button.grab_focus()


## Fills the screen with `run_result`. Call before or after adding to the tree.
func show_result(run_result: RunResult) -> void:
	result = run_result
	if not is_node_ready():
		await ready
	title_label.text = result.title()
	var won_color: Color = Color("#f2b52e") if result.won else Color("#e8836b")
	title_label.add_theme_color_override("font_color", won_color)
	stats_label.text = "\n".join(stat_lines(result))
	upgrades_label.text = upgrades_text(result)
	seed_label.text = "Seed %d" % result.seed_value


## The stat lines shown on the end screen.
static func stat_lines(run_result: RunResult) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("Time survived: %s" % TimeFormat.clock(run_result.survived_seconds))
	if run_result.endless_seconds > 0.0:
		lines.append("Endless: +%s" % TimeFormat.clock(run_result.endless_seconds))
	lines.append("Level: %d" % run_result.level)
	lines.append("Zombies stuffed: %d" % run_result.kills)
	if run_result.killed_by != "":
		lines.append("Got stuffed by: %s" % run_result.killed_by)
	return lines


static func upgrades_text(run_result: RunResult) -> String:
	if run_result.upgrades.is_empty():
		return "Upgrades: none"
	return "Upgrades: " + ", ".join(run_result.upgrades)
