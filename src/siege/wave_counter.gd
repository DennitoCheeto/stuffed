class_name WaveCounter
extends Label
## The night siege's wave counter on the HUD (spec 07 §7): a small felt tag right of the fort's
## health bar. "Wave 2 of 3" while a wave comes, "Next wave in 6" in the breather, and "Pop the
## last ones!" once the last wave stopped coming. Texts in siege_rules.tres.

const GAP: float = 14.0
const WIDTH: float = 260.0
const FONT_SIZE: int = 20

var waves: SiegeWaves
var rules: SiegeRules


func _init(siege_waves: SiegeWaves, siege_rules: SiegeRules) -> void:
	name = "WaveCounter"
	waves = siege_waves
	rules = siege_rules
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = FortHealthBar.SIZE.x / 2.0 + GAP
	offset_right = offset_left + WIDTH
	offset_top = FortHealthBar.TOP
	offset_bottom = FortHealthBar.TOP + FortHealthBar.SIZE.y
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_stylebox_override("normal", StyleBoxFelt.hud(12.0))
	add_theme_font_override("font", UiFonts.heading())
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_color_override("font_color", UiColors.HUD_TEXT)
	add_theme_color_override("font_outline_color", UiColors.HUD_OUTLINE)
	add_theme_constant_override("outline_size", 6)
	text = shown_text()


func _process(_delta: float) -> void:
	text = shown_text()


## What the counter says right now.
func shown_text() -> String:
	if waves.finished:
		return rules.last_ones_counter
	if waves.resting:
		var left: int = ceili(rules.breather_seconds - waves.wave_time)
		return rules.breather_counter % maxi(left, 1)
	return rules.wave_counter % [maxi(waves.wave, 0) + 1, waves.count()]
