class_name BroughtHomePanel
extends VBoxContainer
## "Brought home" on the end screen (spec 03 §2.6, §11): what the run takes home counts up into
## the jars with a rising "plip", like the XP chain.

## How long the count-up takes.
const COUNT_SECONDS: float = 1.2
## Fewest seconds between two plips.
const PLIP_GAP: float = 0.07
const HEADING_COLOR: Color = Color("#cfe3f0")
const NOTE_COLOR: Color = Color("#b8b2c4")
## The rescued plushie line (soft lilac, like its ring in the run).
const RESCUE_COLOR: Color = Color("#d4b8ff")

## Material id -> amount brought home this run.
var kept: Dictionary[String, int] = {}
## Material id -> amount in the jars before this run's haul.
var jars_before: Dictionary[String, int] = {}
var heading: Label
var note_label: Label
## "Plushies in town: +10% coins" (hidden without plushies in town).
var bonus_label: Label
## "Bunny is coming home!" (hidden when nobody was rescued).
var rescue_label: Label
## Material id -> "+12" counter (this run).
var gained: Dictionary[String, JarCounter] = {}
## Material id -> total in the jars.
var totals: Dictionary[String, JarCounter] = {}

var _time: float = 0.0
var _since_plip: float = 0.0
var _plips: int = 0
var _counting: bool = false


func _init() -> void:
	name = "BroughtHome"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 10)
	heading = TownArt.label("Brought home", 44)
	heading.add_theme_color_override(&"font_color", HEADING_COLOR)
	add_child(heading)
	note_label = TownArt.label("", 22)
	note_label.add_theme_color_override(&"font_color", NOTE_COLOR)
	add_child(note_label)
	bonus_label = TownArt.label("", 22)
	bonus_label.add_theme_color_override(&"font_color", RESCUE_COLOR)
	bonus_label.visible = false
	add_child(bonus_label)
	rescue_label = TownArt.label("", 28)
	rescue_label.add_theme_color_override(&"font_color", RESCUE_COLOR)
	rescue_label.visible = false
	add_child(rescue_label)
	var gained_row: HBoxContainer = _row(48)
	var totals_row: HBoxContainer = _row(36)
	var jars_label: Label = TownArt.label("In your jars:", 22)
	jars_label.add_theme_color_override(&"font_color", NOTE_COLOR)
	totals_row.add_child(jars_label)
	for material: String in JarIcon.MATERIALS:
		gained[material] = JarCounter.new(material, 40, 48.0)
		gained_row.add_child(gained[material])
		totals[material] = JarCounter.new(material, 22, 28.0)
		totals_row.add_child(totals[material])


## Starts counting `kept_amounts` into jars that held `before` (`share` of the haul was kept,
## coins got `coin_bonus` more from plushies in town).
func show_haul(
	kept_amounts: Dictionary[String, int],
	before: Dictionary[String, int],
	share: float,
	coin_bonus: float = 0.0
) -> void:
	kept = kept_amounts.duplicate()
	jars_before = before.duplicate()
	note_label.text = share_text(share)
	bonus_label.text = bonus_text(coin_bonus)
	bonus_label.visible = not bonus_label.text.is_empty()
	_time = 0.0
	_plips = 0
	_counting = true
	_show_at(0.0)


## Shows that the plushie `plushie_name` was rescued in this run and moves into town.
func show_rescue(plushie_name: String) -> void:
	rescue_label.text = "%s is coming home!" % plushie_name
	rescue_label.visible = true


## The line about the coin bonus from plushies in town ("" = none).
static func bonus_text(coin_bonus: float) -> String:
	if coin_bonus <= 0.0:
		return ""
	return "Plushies in town: +%d%% coins" % roundi(coin_bonus * 100.0)


## What the note under the heading says for a kept share.
static func share_text(share: float) -> String:
	if share >= 1.0:
		return "You kept everything!"
	if is_equal_approx(share, 0.5):
		return "You kept half (rounded up). No run is wasted."
	return "You kept %d%%." % roundi(share * 100.0)


func amount(material: String) -> int:
	return kept.get(material, 0)


## The "+N" shown for `material` right now.
func shown_gain(material: String) -> int:
	return gained[material].shown


func shown_total(material: String) -> int:
	return totals[material].shown


func is_done() -> bool:
	return not _counting


## Jumps to the end of the count.
func finish() -> void:
	_counting = false
	_show_at(1.0)


func _process(delta: float) -> void:
	if not _counting:
		return
	_time += delta
	_since_plip += delta
	var progress: float = clampf(_time / COUNT_SECONDS, 0.0, 1.0)
	var before: int = _shown_sum()
	_show_at(progress)
	if _shown_sum() > before and _since_plip >= PLIP_GAP:
		_since_plip = 0.0
		_plips += 1
		Sfx.play(&"pickup", 1.0 + 0.05 * mini(_plips, 14))
	if progress >= 1.0:
		_counting = false


func _show_at(progress: float) -> void:
	for material: String in JarIcon.MATERIALS:
		var part: int = floori(amount(material) * progress)
		gained[material].show_amount(part, "+")
		totals[material].show_amount(jars_before.get(material, 0) + part)


func _shown_sum() -> int:
	var sum: int = 0
	for material: String in JarIcon.MATERIALS:
		sum += gained[material].shown
	return sum


func _row(separation: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", separation)
	add_child(row)
	return row
