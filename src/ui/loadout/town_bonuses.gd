class_name TownBonuses
extends VBoxContainer
## The "Town bonuses" strip under the players' columns on the town loadout page (spec 04b §3.3):
## the bought tricks grouped by building (the trick's text shows on hover; Bedroom-only tricks are
## marked) and the building bonuses in plain words: the totals the next run really uses.

const BLOCK_COLUMNS: int = 3
const BLOCK_WIDTH: float = 380.0
const TEXT_SIZE: int = 17
const TAG_SIZE: int = 14
## Bedroom-only tricks get a pinker tag.
const BEDROOM_FILL: Color = UiColors.STICKER_PINK
const BEDROOM_INK: Color = UiColors.STICKER_PINK_INK

## Building name -> the trick names shown under it (tests).
var shown_tricks: Dictionary[String, PackedStringArray] = {}
## Trick id -> its tag (tests: tooltip, Bedroom-only text).
var trick_tags: Dictionary[StringName, FabricTag] = {}
## The bonus lines shown.
var bonus_lines: PackedStringArray = []


func _init(layout: TownLayout, perks: TownPerks, texts: LoadoutTexts) -> void:
	name = "TownBonuses"
	add_theme_constant_override(&"separation", 6)
	add_child(UiFonts.label(texts.bonuses_heading, 22, UiColors.INK_SOFT, UiFonts.heading()))
	var grid: GridContainer = GridContainer.new()
	grid.columns = BLOCK_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 8)
	for spot: TownSpot in layout.spots:
		var bought: Array[TrickDef] = _bought(spot.building, perks)
		if not bought.is_empty():
			grid.add_child(_block(spot.building, bought, texts))
	if grid.get_child_count() > 0:
		add_child(grid)
	else:
		add_child(UiFonts.label(KeyBindings.fill(texts.no_tricks), TEXT_SIZE, UiColors.INK_SOFT))
	bonus_lines = lines_for(perks, texts)
	var words: String = (
		"   ·   ".join(bonus_lines) if not bonus_lines.is_empty() else texts.no_bonuses
	)
	var label: Label = UiFonts.label(words, TEXT_SIZE + 1, UiColors.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = BLOCK_WIDTH * BLOCK_COLUMNS
	add_child(label)


## The building bonuses of `perks` in plain words (only the ones the town has).
static func lines_for(perks: TownPerks, texts: LoadoutTexts) -> PackedStringArray:
	var lines: PackedStringArray = []
	if perks.extra_card_uses > 0:
		lines.append(texts.card_uses_bonus % perks.extra_card_uses)
	if perks.max_health_bonus > 0.0:
		lines.append(texts.health_bonus % roundi(perks.max_health_bonus))
	if perks.pickup_range_bonus > 0.0:
		lines.append(texts.pickup_range % roundi(perks.pickup_range_bonus * 100.0))
	if perks.pickup_gap_cut > 0.0:
		lines.append(texts.pickup_sooner % roundi(perks.pickup_gap_cut * 100.0))
	if perks.first_pickup_at > 0.0:
		lines.append(texts.first_pickup % _clock(perks.first_pickup_at))
	return lines


## "0:15" for 15 seconds.
static func _clock(seconds: float) -> String:
	var whole: int = roundi(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## The tricks of `building` the run uses, in branch order.
static func _bought(building: BuildingDef, perks: TownPerks) -> Array[TrickDef]:
	var bought: Array[TrickDef] = []
	for trick: TrickDef in building.tricks:
		if perks.has_trick(trick.id):
			bought.append(trick)
	return bought


func _block(building: BuildingDef, bought: Array[TrickDef], texts: LoadoutTexts) -> VBoxContainer:
	var block: VBoxContainer = VBoxContainer.new()
	block.custom_minimum_size.x = BLOCK_WIDTH
	block.add_theme_constant_override(&"separation", 3)
	var title: Label = UiFonts.label(
		building.display_name, TEXT_SIZE, UiColors.INK, UiFonts.heading()
	)
	block.add_child(title)
	var tags: HFlowContainer = HFlowContainer.new()
	tags.add_theme_constant_override(&"h_separation", 6)
	tags.add_theme_constant_override(&"v_separation", 4)
	var names: PackedStringArray = []
	for trick: TrickDef in bought:
		var words: String = trick.display_name
		var tag: FabricTag
		if trick.in_siege:
			tag = FabricTag.new(words, UiColors.TAG, UiColors.INK, TAG_SIZE)
		else:
			words = "%s (%s)" % [trick.display_name, texts.bedroom_only]
			tag = FabricTag.new(words, BEDROOM_FILL, BEDROOM_INK, TAG_SIZE)
		tag.mouse_filter = Control.MOUSE_FILTER_STOP
		tag.tooltip_text = KeyBindings.fill(trick.text)
		tags.add_child(tag)
		trick_tags[trick.id] = tag
		names.append(words)
	block.add_child(tags)
	shown_tricks[building.display_name] = names
	return block
