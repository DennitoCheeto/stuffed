class_name BroughtHomePanel
extends VBoxContainer
## "Brought home" on the end screen (spec 03 §2.6, §11; look: spec 04 §4.3): what the run takes
## home counts up into the jars with a rising "plip", like the XP chain. It sits on a cream felt
## patch: a hand-written heading, dark ink, and a photo of a rescued plushie.

## How long the count-up takes.
const COUNT_SECONDS: float = 1.2
## Fewest seconds between two plips.
const PLIP_GAP: float = 0.07
## Narrowest the panel gets (long notes wrap inside it).
const WIDTH: float = 380.0
const NOTE_COLOR: Color = UiColors.INK_SOFT
## The rescued plushie line and the plushie bonus.
const RESCUE_COLOR: Color = UiColors.PURPLE
const PHOTO_PICTURE: Vector2 = Vector2(120, 104)

## Material id -> amount brought home this run.
var kept: Dictionary[String, int] = {}
## Material id -> amount in the jars before this run's haul.
var jars_before: Dictionary[String, int] = {}
var heading: HandTitle
var note_label: Label
## "Plushies in town: +10% coins" (hidden without plushies in town).
var bonus_label: Label
## "Bunny is coming home!" (hidden when nobody was rescued).
var rescue_label: Label
## The rescued plushie's photo (null until one is shown).
var rescue_photo: PhotoFrame
## Material id -> "+12" counter (this run).
var gained: Dictionary[String, JarCounter] = {}
## Material id -> total in the jars.
var totals: Dictionary[String, JarCounter] = {}

var _time: float = 0.0
var _since_plip: float = 0.0
var _plips: int = 0
var _counting: bool = false
var _rescue_box: VBoxContainer


func _init() -> void:
	name = "BroughtHome"
	alignment = BoxContainer.ALIGNMENT_CENTER
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_constant_override(&"separation", 10)
	heading = HandTitle.new("Brought home", 44, UiColors.TEAL, -2.0)
	add_child(heading)
	note_label = _text(20, NOTE_COLOR)
	add_child(note_label)
	bonus_label = _text(20, RESCUE_COLOR)
	bonus_label.visible = false
	add_child(bonus_label)
	var jars: GridContainer = GridContainer.new()
	jars.columns = 2
	jars.add_theme_constant_override(&"h_separation", 36)
	jars.add_theme_constant_override(&"v_separation", 6)
	jars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(jars)
	jars.add_child(UiFonts.label("This run", 16, NOTE_COLOR))
	jars.add_child(UiFonts.label("In your jars", 16, NOTE_COLOR))
	for material: String in JarIcon.MATERIALS:
		gained[material] = JarCounter.new(material, 34, 40.0).on_felt()
		jars.add_child(gained[material])
		totals[material] = JarCounter.new(material, 22, 28.0).on_felt(UiColors.INK_SOFT)
		totals[material].size_flags_vertical = Control.SIZE_SHRINK_CENTER
		jars.add_child(totals[material])
	_rescue_box = VBoxContainer.new()
	_rescue_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_rescue_box.add_theme_constant_override(&"separation", 6)
	_rescue_box.visible = false
	add_child(_rescue_box)
	rescue_label = _text(26, RESCUE_COLOR)
	rescue_label.add_theme_font_override(&"font", UiFonts.hand())
	rescue_label.visible = false
	_rescue_box.add_child(rescue_label)


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


## Shows that the plushie `plushie_name` was rescued in this run and moves into town, with a
## photo of it when `who` is given.
func show_rescue(plushie_name: String, who: PlushieDef = null) -> void:
	rescue_label.text = "%s is coming home!" % plushie_name
	rescue_label.visible = true
	_rescue_box.visible = true
	if who == null or rescue_photo != null:
		return
	rescue_photo = PhotoFrame.new(plushie_name, PHOTO_PICTURE, -3.0, UiColors.TAPE_PINK)
	rescue_photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rescue_photo.picture.add_child(PlushiePhoto.new(who))
	_rescue_box.add_child(rescue_photo)


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


func _text(font_size: int, color: Color, words: String = "") -> Label:
	var label: Label = UiFonts.label(words, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
