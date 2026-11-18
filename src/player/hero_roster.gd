class_name HeroRoster
extends Resource
## Every playable hero in pick order (spec 08): Banane first, then the rescued plushies. A
## plushie hero is unlocked once that plushie was freed in the Bedroom and came home (any entry
## in TownSave.plushies, "waiting" or "in_town"). Data: data/heroes/hero_roster.tres.

const PATH: String = "res://data/heroes/hero_roster.tres"

static var _current: HeroRoster

## The heroes in pick order. The first one is the starter (always playable).
@export var heroes: Array[HeroStats] = []


## The game's roster, loaded at first use. Hero files load weapons whose scripts depend on the
## town's perks, so a `preload` of the roster in game code would load in a circle.
static func current() -> HeroRoster:
	if _current == null:
		_current = load(PATH) as HeroRoster
	return _current


## The hero every new game starts with (Banane).
func starter() -> HeroStats:
	return heroes[0]


## The hero with this id, or null.
func find(id: StringName) -> HeroStats:
	for hero: HeroStats in heroes:
		if hero.id == id:
			return hero
	return null


## True when `hero` may be played with the town in `save`.
func is_unlocked(hero: HeroStats, save: TownSave) -> bool:
	return hero.plushie == null or save.plushies.has(hero.plushie.id)


## The heroes `save` has unlocked, in pick order.
func unlocked(save: TownSave) -> Array[HeroStats]:
	var result: Array[HeroStats] = []
	for hero: HeroStats in heroes:
		if is_unlocked(hero, save):
			result.append(hero)
	return result


## The hero player `slot` plays: the saved one while it is unlocked, else the starter.
func hero_for(save: TownSave, slot: int) -> HeroStats:
	var hero: HeroStats = find(StringName(save.hero_id(slot)))
	if hero == null or not is_unlocked(hero, save):
		return starter()
	return hero


## The next unlocked hero after `current` (wraps around), for the developer menu.
func next_unlocked(save: TownSave, current: HeroStats) -> HeroStats:
	var open: Array[HeroStats] = unlocked(save)
	var at: int = open.find(current)
	return open[(at + 1) % open.size()]
