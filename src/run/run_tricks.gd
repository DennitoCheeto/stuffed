class_name RunTricks
extends RefCounted
## The building tricks in one run (spec 06): which are on (from the run's TownPerks, town-wide),
## when each first fired (banner + run log, AC-70), and the trick rules that hook into the run.
## The run owns one as `run.tricks`; trick code calls `note(id, player)` whenever a trick acts.

## The first time each trick fired, for the run log: {"id", "time", "player"}.
var moments: Array[Dictionary] = []
## Separate randomness for tricks (Second Toy), so they don't change the cards or zombies.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Shiny Card: the level-up on screen is a lucky one (one of its cards shines).
var shiny_level_up: bool = false

var _run: Run


func _init(run: Run) -> void:
	_run = run


## True if the town bought trick `id` (every hero has it).
func has(id: StringName) -> bool:
	return _run.perks.has_trick(id)


## Call each time trick `id` does its thing for `player` (null = for everyone). The first time
## in a run it shows a small banner naming the trick in the player's colour and notes it for
## the run log. Returns true on that first time.
func note(id: StringName, player: Player = null) -> bool:
	var trick: TrickDef = _run.perks.trick(id)
	if trick == null or fired(id):
		return false
	var index: int = player.player_index if player != null else 0
	moments.append({"id": String(id), "time": _run.elapsed, "player": index})
	_run.hud.trick_banner.show_trick(trick.display_name, index, _run.rules.trick_banner_seconds)
	return true


## True once trick `id` has fired in this run.
func fired(id: StringName) -> bool:
	for moment: Dictionary in moments:
		if moment["id"] == String(id):
			return true
	return false


## Sets up `player` before the hero is added: their tricks, Head Start and Second Toy.
func prepare_hero(player: Player) -> void:
	var perks: TownPerks = _run.perks
	player.tricks = perks.trick_ids()
	var head_start: TrickDef = perks.trick(&"head_start")
	if head_start != null:
		player.starting_weapon_level = int(head_start.amount)
	var second_toy: TrickDef = perks.trick(&"second_toy")
	if second_toy != null:
		player.extra_weapons = _random_weapons(int(second_toy.amount), player.starting_weapon)


## After the hero is added: the tricks they started with show their banner once.
func hero_added(player: Player) -> void:
	if player.starting_weapon_level > 1:
		note(&"head_start", player)
	if not player.extra_weapons.is_empty():
		note(&"second_toy", player)


## The cards `player` must not get: `excluded`, plus everything but new weapons on their first
## level-up with Show-and-Tell (which then fires).
func card_excluded(player: Player, excluded: Array[StringName]) -> Array[StringName]:
	var new_weapons: Array[StringName] = new_weapons_only(player, excluded)
	if new_weapons.is_empty():
		return excluded
	var result: Array[StringName] = excluded.duplicate()
	for upgrade: UpgradeDef in _run.upgrade_pool.upgrades:
		if not new_weapons.has(upgrade.id) and not result.has(upgrade.id):
			result.append(upgrade.id)
	note(&"show_and_tell", player)
	return result


## Show-and-Tell (spec 06 §3): on `player`'s first level-up, the weapons they could get that
## they don't have yet (not in `excluded`). Empty when the trick doesn't apply, or when there
## aren't enough of them to fill the cards (then the cards are normal).
func new_weapons_only(player: Player, excluded: Array[StringName]) -> Array[StringName]:
	var ids: Array[StringName] = []
	if player.first_level_up_done or not player.has_trick(&"show_and_tell"):
		return ids
	var pool: UpgradePool = _run.upgrade_pool
	var levels: Dictionary[StringName, int] = player.upgrade_levels()
	if pool.owned_count(levels, UpgradeDef.Kind.WEAPON) >= pool.max_weapons:
		return ids
	for upgrade: UpgradeDef in pool.upgrades:
		var open: bool = upgrade.weight > 0.0 and not excluded.has(upgrade.id)
		if upgrade.kind == UpgradeDef.Kind.WEAPON and open and levels.get(upgrade.id, 0) == 0:
			ids.append(upgrade.id)
	if ids.size() < card_count(player):
		ids.clear()
	return ids


## How many cards `player`'s level-ups show: Four of a Kind's number, else the pool's.
func card_count(player: Player) -> int:
	var four: TrickDef = _run.perks.trick(&"four_of_a_kind")
	if four != null and player.has_trick(&"four_of_a_kind"):
		return int(four.amount)
	return _run.upgrade_pool.cards_per_level_up


## A new level-up for `player` starts: Shiny Card rolls (its chance in data) whether one of its
## cards shines. The shine stays with this level-up through rerolls and banishes.
func start_level_up(player: Player) -> void:
	var shiny_card: TrickDef = _run.perks.trick(&"shiny_card")
	var has_it: bool = shiny_card != null and player.has_trick(&"shiny_card")
	shiny_level_up = has_it and rng.randf() < shiny_card.amount


## `offers` were just dealt to `player` (a new level-up, a reroll or a banish): Four of a Kind
## fires on more cards than normal, and on a lucky level-up one random card that can shine
## becomes shiny (unless one already is).
func dealt(offers: Array[UpgradeOffer], player: Player) -> void:
	if offers.size() > _run.upgrade_pool.cards_per_level_up:
		note(&"four_of_a_kind", player)
	if not shiny_level_up:
		return
	var choices: Array[UpgradeOffer] = []
	for offer: UpgradeOffer in offers:
		if offer.shiny:
			return
		if offer.can_shine():
			choices.append(offer)
	if choices.is_empty():
		return
	choices[rng.randi_range(0, choices.size() - 1)].shiny = true
	note(&"shiny_card", player)


## Lucky Gift: how many more level-ups a gift box opened by `player` tries to give.
func gift_extra(player: Player) -> int:
	var lucky_gift: TrickDef = _run.perks.trick(&"lucky_gift")
	if lucky_gift == null or not player.has_trick(&"lucky_gift"):
		return 0
	return int(lucky_gift.amount)


## `count` different unlocked weapons, never `besides` (the starting weapon), within the slots.
func _random_weapons(count: int, besides: WeaponStats) -> Array[WeaponStats]:
	var choices: Array[WeaponStats] = []
	for upgrade: UpgradeDef in _run.perks.open_weapons(_run.upgrade_pool):
		if besides == null or upgrade.weapon.id != besides.id:
			choices.append(upgrade.weapon)
	var picked: Array[WeaponStats] = []
	var room: int = _run.upgrade_pool.max_weapons - (1 if besides != null else 0)
	while picked.size() < mini(count, room) and not choices.is_empty():
		picked.append(choices.pop_at(rng.randi_range(0, choices.size() - 1)))
	return picked
