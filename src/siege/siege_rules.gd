class_name SiegeRules
extends Resource
## The night siege (spec 07): when the horde comes, how big it is, what it gives and what a
## repair costs. Tune it in data/siege/siege_rules.tres, not in code.
##
## The countdown lives in `TownSave.siege_nights`: -1 = no warning yet, N = nights to go,
## 0 = the siege is due. A "night" is one expedition that ended (any ending, spec 07 §3).

## The first warning appears once this many buildings are rebuilt (something to defend).
@export var first_trigger_buildings: int = 2
## Nights to go when the first warning appears.
@export var first_nights: int = 2
## Nights to go after every siege (won or lost).
@export var nights_between: int = 3

@export_group("Waves")
## The waves, in order (spec 07 §5).
@export var wave_list: Array[SiegeWave] = []
## Seconds each wave keeps spawning.
@export var wave_seconds: float = 60.0
## A short rest between waves (seconds).
@export var breather_seconds: float = 8.0
## Each siege after the first brings this share more zombies (0.2 = +20% per siege).
@export var zombie_growth: float = 0.2
## Each siege after the first gives zombies this share more health.
@export var health_growth: float = 0.15
## Zombies appear this far outside the town room's edges (pixels), from all four sides.
@export var spawn_margin: float = 150.0
## What makes a zombie an elite.
@export var elite_rules: EliteRules

@export_group("Fort and heroes")
## The pillow fort's health in a town with nothing built ...
@export var fort_health: float = 600.0
## ... and this much more for every building level built.
@export var fort_health_per_level: float = 60.0
## Share of a zombie's touch damage the fort takes per second while the zombie touches it.
@export var fort_touch_rate: float = 0.6
## Zombies on their way to the fort turn to a hero closer than this (pixels).
@export var hero_reach: float = 260.0
## Zombies on their way turn to a built building closer than this to its walls (pixels; the
## Lucky Jar draws from further away, `BuildingLevel.siege_bait`).
@export var building_reach: float = 110.0
## Share of a zombie's touch damage a building takes per second while the zombie touches it.
@export var building_touch_rate: float = 0.6
## A knocked-down building tips over this far (degrees), sinks a little and greys out.
@export var knocked_tilt_degrees: float = -9.0
@export var knocked_sink: float = 0.88
@export var knocked_tint: Color = Color(0.72, 0.7, 0.74, 1.0)
## A fallen hero stands back up at the fort after this many seconds.
@export var stand_up_seconds: float = 4.0
## A short moment to see the end (won or lost) before going home.
@export var end_pause_seconds: float = 2.5

@export_group("Building helpers")
## The Snack Bar's healing ring and the Party Shop's trap ring on the ground: calm colours, never
## enemy danger (spec 07 §7, AC-83).
@export var heal_ring_color: Color = Color(0.6, 0.9, 0.68, 1.0)
@export var trap_ring_color: Color = Color(0.78, 0.7, 0.96, 1.0)
## How long a trap's confetti flies (seconds).
@export var trap_confetti_seconds: float = 0.9
## The trap's sound (a soft, higher Party Popper).
@export var trap_sound: StringName = &"party_popper"
@export var trap_pitch: float = 1.35

@export_group("Plushies")
## Every plushie living in town helps (spec 07 §4, AC-79): it stands by the fort
## (`TownLayout.siege_plushie_spots`) and throws this weapon (a small stuffing ball every ~2 s).
@export var plushie_ball: WeaponStats
## Its health; at 0 it is knocked out (sits down, dizzy stars) until the Plush Hospital stands it
## back up (`BuildingLevel.siege_revive_seconds`), or until the siege ends.
@export var plushie_health: float = 45.0
## Zombies on their way closer than this (pixels) turn to attack it.
@export var plushie_reach: float = 90.0
## Share of a zombie's touch damage it takes per second.
@export var plushie_touch_rate: float = 0.6
## Half the width of the patch of floor zombies knock at (around its feet).
@export var plushie_footprint: float = 18.0
## Drawing size (PlushieLook `size`) and the soft halo behind it (never a danger colour).
@export var plushie_size: float = 18.0
@export var plushie_halo: Color = Color(1, 0.98, 0.92, 0.55)
## Knocked out: it tips over this far (degrees) and squashes down to this height.
@export var plushie_out_tilt: float = -24.0
@export var plushie_out_squash: float = 0.8
## Dizzy stars circling its head while it is out: how many, turns per second, colour.
@export var dizzy_stars: int = 3
@export var dizzy_spin: float = 0.8
@export var dizzy_color: Color = Color(1, 0.93, 0.56, 1)
## Sounds when it is knocked out and when it stands back up.
@export var plushie_out_sound: StringName = &"puff"
@export var plushie_up_sound: StringName = &"hello"

@export_group("After the siege")
## The haul of the first won siege (material id -> amount).
@export var reward: Dictionary[String, int] = {"coins": 400, "stuffing": 20, "thread": 4}
## Each siege after the first gives this share more (0.25 = +25% per siege).
@export var reward_growth: float = 0.25
## A lost siege still gives this share of the reward.
@export var consolation_share: float = 0.3
## Repairing a damaged building costs this share of its current level's coins.
@export var repair_share: float = 0.25

@export_group("Texts")
## The moon calendar's sign: nights to go ("%d" = how many).
@export var calendar_text: String = "The horde arrives in %d nights."
@export var calendar_text_one: String = "The horde arrives in 1 night."
@export var calendar_text_due: String = "The horde arrives tonight!"
## On the end screen, under what the run brought home.
@export var end_text: String = "%d nights until the horde!"
@export var end_text_one: String = "1 night until the horde!"
@export var end_text_due: String = "The horde is coming tonight!"
## The banner when the first warning appears in town.
@export var warning_banner: String = "A horde is on its way!"
@export var warning_subtitle: String = "It arrives in %d nights. Get the fort ready!"
## The banner when you come home and the siege is due (the town turns to dusk).
@export var due_banner: String = "The horde is coming!"
@export var due_subtitle: String = "Build and repair, then defend the fort at the door."
## The door's prompt while the siege is due.
@export var door_prompt: String = "E   Defend the fort"
## The banner when wave N of M starts ("%d of %d").
@export var wave_banner: String = "Wave %d of %d"
@export var wave_subtitle: String = "Keep them away from the fort!"
@export var last_wave_subtitle: String = "The last wave! Something big is coming..."
@export var won_banner: String = "Night defended!"
@export var won_subtitle: String = "The fort stands. The horde runs home."
@export var lost_banner: String = "The horde got in"
@export var lost_subtitle: String = "The fort fell. They leave at dawn."


## Shows the first warning once enough buildings stand. Returns true if it just appeared.
func warn_if_ready(save: TownSave) -> bool:
	if save.siege_nights >= 0 or save.rebuilt_count() < first_trigger_buildings:
		return false
	save.siege_nights = first_nights
	return true


## One expedition ended: the countdown ticks down by one (never below 0). A town that just got
## its second building gets its first warning instead.
func night_passed(save: TownSave) -> void:
	if save.siege_nights > 0:
		save.siege_nights -= 1
	else:
		warn_if_ready(save)


func is_warned(save: TownSave) -> bool:
	return save.siege_nights >= 0


## True when the horde comes before the next expedition.
func is_due(save: TownSave) -> bool:
	return save.siege_nights == 0


## A siege was played (won or lost): counts it and starts the countdown again.
func siege_ended(save: TownSave, won: bool) -> void:
	save.sieges_played += 1
	if won:
		save.sieges_won += 1
	save.siege_nights = nights_between


## How many times bigger siege `number` (1 = the first) is than the first.
func zombie_scale(number: int) -> float:
	return 1.0 + zombie_growth * maxi(number - 1, 0)


func health_scale(number: int) -> float:
	return 1.0 + health_growth * maxi(number - 1, 0)


## The pillow fort's health in a town with `built_levels` building levels in total.
func fort_health_for(built_levels: int) -> float:
	return fort_health + fort_health_per_level * maxi(built_levels, 0)


## How long all waves with their breathers take (seconds).
func total_seconds() -> float:
	var count: int = wave_list.size()
	return wave_seconds * count + breather_seconds * maxi(count - 1, 0)


## What winning siege `number` (1 = the first) brings home.
func reward_for(number: int) -> Dictionary[String, int]:
	return _scaled(1.0 + reward_growth * maxi(number - 1, 0))


## What losing siege `number` still brings home.
func consolation_for(number: int) -> Dictionary[String, int]:
	return _scaled((1.0 + reward_growth * maxi(number - 1, 0)) * consolation_share)


## What repairing a building damaged at `level` costs (coins, rounded up).
func repair_cost(level: BuildingLevel) -> Dictionary[String, int]:
	if level == null:
		return {}
	return {"coins": ceili(level.coins * repair_share)}


## The calendar sign for `nights` to go.
func calendar_line(nights: int) -> String:
	return _counted(nights, calendar_text, calendar_text_one, calendar_text_due)


## The end screen line for `nights` to go ("" = no warning yet).
func end_line(nights: int) -> String:
	if nights < 0:
		return ""
	return _counted(nights, end_text, end_text_one, end_text_due)


func _counted(nights: int, many: String, one: String, due: String) -> String:
	if nights <= 0:
		return due
	if nights == 1:
		return one
	return many % nights


func _scaled(factor: float) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for id: String in reward:
		result[id] = roundi(reward[id] * factor)
	return result
