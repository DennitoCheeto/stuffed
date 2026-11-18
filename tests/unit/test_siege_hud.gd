extends GutTest
## Siege HUD and tricks (spec 07 §4, §7): the wave counter says which wave comes (or how long the
## breather lasts), the edge arrow points to the fort only while it is hit off screen, and only
## the tricks that make sense in the siege stay on.

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const FAR_AWAY: Rect2 = Rect2(50000, 50000, 400, 300)
const ON_SCREEN: Rect2 = Rect2(100, 100, 400, 300)
const BEDROOM_ONLY: Array[String] = [
	"treasure_map", "picnic", "quick_untangle", "thank_you_gift", "plushie_buddy"
]

var _view_before: Transform2D


func before_each() -> void:
	_view_before = get_viewport().canvas_transform
	get_viewport().canvas_transform = Transform2D.IDENTITY


func after_each() -> void:
	get_viewport().canvas_transform = _view_before


func _arrows(fort: SiegeFort) -> PickupArrows:
	var arrows: PickupArrows = PickupArrows.new()
	arrows.floor_items = Node2D.new()
	arrows.add_child(arrows.floor_items)
	add_child_autofree(arrows)
	arrows.watch_fort(fort, RULES.fort_arrow_seconds)
	return arrows


func test_the_wave_counter_follows_the_waves() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	var counter: WaveCounter = WaveCounter.new(waves, RULES)
	autofree(counter)
	waves.tick(0.1)
	assert_eq(counter.shown_text(), "Wave 1 of 3")
	waves.next_wave()
	assert_eq(counter.shown_text(), "Wave 2 of 3")
	waves.tick(RULES.wave_seconds)
	assert_true(waves.resting)
	assert_eq(counter.shown_text(), "Next wave in 8", "the breather counts down")
	waves.tick(5.5)
	assert_eq(counter.shown_text(), "Next wave in 3")
	waves.tick(3.0)
	assert_eq(counter.shown_text(), "Wave 3 of 3")
	waves.tick(RULES.wave_seconds)
	assert_true(waves.finished)
	assert_eq(counter.shown_text(), "Pop the last ones!")


func test_the_wave_counter_sits_right_of_the_fort_bar() -> void:
	var counter: WaveCounter = WaveCounter.new(SiegeWaves.new(RULES), RULES)
	autofree(counter)
	assert_gt(counter.offset_left, FortHealthBar.SIZE.x / 2.0, "beside the bar, not over it")
	assert_eq(counter.offset_top, FortHealthBar.TOP, "on the same line")
	assert_false(UiColors.is_danger(counter.get_theme_color("font_color")))


func test_an_arrow_points_to_the_fort_while_it_is_hit_off_screen() -> void:
	var fort: SiegeFort = SiegeFort.new(FAR_AWAY, 100.0, 260.0, 0.5)
	var arrows: PickupArrows = _arrows(fort)
	await wait_process_frames(2)
	assert_eq(arrows.points.size(), 0, "no arrow while nobody attacks it")
	fort.hurt(5.0)
	await wait_process_frames(2)
	assert_eq(arrows.points.size(), 1, "an arrow once it is hit")
	if arrows.points.size() == 1:
		assert_eq(arrows.colors[0], PickupArrows.FORT_COLOR)
		assert_gt(arrows.directions[0].x, 0.0, "towards the fort")
		assert_gt(arrows.directions[0].y, 0.0)
	assert_false(UiColors.is_danger(PickupArrows.FORT_COLOR), "the player's side, not danger")
	await wait_seconds(RULES.fort_arrow_seconds + 0.2)
	assert_eq(arrows.points.size(), 0, "gone a while after the last hit")


func test_no_fort_arrow_while_the_fort_is_on_screen() -> void:
	var fort: SiegeFort = SiegeFort.new(ON_SCREEN, 100.0, 260.0, 0.5)
	var arrows: PickupArrows = _arrows(fort)
	fort.hurt(5.0)
	await wait_process_frames(2)
	assert_eq(arrows.points.size(), 0)


func test_only_tricks_that_make_sense_stay_on_in_the_siege() -> void:
	var save: TownSave = TownSave.new()
	var all: PackedStringArray = []
	for trick: TrickDef in TrickBook.all_tricks(LAYOUT):
		save.tricks.append(String(trick.id))
		all.append(String(trick.id))
	save.last_rescued = "pip"
	var perks: TownPerks = TownPerks.from_save(save, LAYOUT)
	assert_eq(perks.tricks.size(), 18)
	perks.keep_siege_tricks()
	assert_eq(perks.tricks.size(), 18 - BEDROOM_ONLY.size())
	for id: String in all:
		var kept: bool = perks.has_trick(StringName(id))
		assert_eq(kept, not BEDROOM_ONLY.has(id), "%s on in the siege: %s" % [id, kept])
	assert_eq(perks.buddy, "", "no Plushie Buddy")
