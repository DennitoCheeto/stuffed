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
@export var waves: int = 3
## Seconds each wave keeps spawning.
@export var wave_seconds: float = 60.0
## A short rest between waves (seconds).
@export var breather_seconds: float = 8.0
## Each siege after the first brings this share more zombies (0.2 = +20% per siege).
@export var zombie_growth: float = 0.2
## Each siege after the first gives zombies this share more health.
@export var health_growth: float = 0.15

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
