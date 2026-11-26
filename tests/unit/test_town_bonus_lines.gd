extends GutTest
## Spec 04b §3.3: the building bonuses in plain words are the totals TownPerks hands the run.

const TEXTS: LoadoutTexts = preload("res://data/ui/loadout_view.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")


func test_a_fresh_town_has_no_bonus_lines() -> void:
	assert_eq(TownBonuses.lines_for(TownPerks.new(), TEXTS).size(), 0)


func test_lines_use_the_perks_totals() -> void:
	var perks: TownPerks = TownPerks.new()
	perks.extra_card_uses = 3
	perks.max_health_bonus = 20.0
	perks.pickup_range_bonus = 0.3
	perks.pickup_gap_cut = 0.45
	perks.first_pickup_at = 15.0
	var lines: PackedStringArray = TownBonuses.lines_for(perks, TEXTS)
	assert_eq(
		lines,
		PackedStringArray(
			[
				TEXTS.card_uses_bonus % 3,
				TEXTS.health_bonus % 20,
				TEXTS.pickup_range % 30,
				TEXTS.pickup_sooner % 45,
				TEXTS.first_pickup % "0:15",
			]
		)
	)


func test_a_maxed_town_matches_its_building_data() -> void:
	var save: TownSave = TownSave.new()
	for spot: TownSpot in LAYOUT.spots:
		save.building_levels[String(spot.id)] = spot.building.levels.size()
	var perks: TownPerks = TownPerks.from_save(save, LAYOUT)
	var lines: PackedStringArray = TownBonuses.lines_for(perks, TEXTS)
	assert_has(lines, TEXTS.card_uses_bonus % perks.extra_card_uses)
	assert_has(lines, TEXTS.health_bonus % roundi(perks.max_health_bonus))
	assert_eq(lines.size(), 5, "every kind of building bonus shows")
