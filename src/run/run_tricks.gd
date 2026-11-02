class_name RunTricks
extends RefCounted
## The building tricks in one run (spec 06): which are on (from the run's TownPerks, town-wide),
## when each first fired (banner + run log, AC-70), and the trick rules that hook into the run.
## The run owns one as `run.tricks`; trick code calls `note(id, player)` whenever a trick acts.

## The trick sounds: a light whistle and a springy pop, both softer than enemy danger (§7).
const WHISTLE_SOUND: StringName = &"whistle"
const WHISTLE_PITCH: float = 1.0
const SPARE_SOUND: StringName = &"pop_up"
const SPARE_PITCH: float = 1.0
## Treasure Map tries this many random spots before it falls back to a far corner.
const TREASURE_TRIES: int = 60

## The first time each trick fired, for the run log: {"id", "time", "player"}.
var moments: Array[Dictionary] = []
## Separate randomness for tricks (Second Toy), so they don't change the cards or zombies.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Shiny Card: the level-up on screen is a lucky one (one of its cards shines).
var shiny_level_up: bool = false
## Treasure Map: the hidden big gift box (null without the trick; freed once opened).
var treasure: GiftBox

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
	var second_helping: TrickDef = perks.trick(&"second_helping")
	if second_helping != null:
		player.max_shield = second_helping.amount
	var spare_stuffing: TrickDef = perks.trick(&"spare_stuffing")
	if spare_stuffing != null:
		player.spare_stuffing = spare_stuffing.amount


## After the hero is added: the tricks they started with show their banner once, and the
## Snack Bar tricks listen to the hero.
func hero_added(player: Player) -> void:
	if player.starting_weapon_level > 1:
		note(&"head_start", player)
	if not player.extra_weapons.is_empty():
		note(&"second_toy", player)
	player.shield_changed.connect(_on_shield_changed.bind(player))
	player.popped_back_up.connect(pop_back_up.bind(player))


## Picnic: the mini-boss was beaten, so every hero still standing heals to full.
func mini_boss_beaten() -> void:
	if not has(&"picnic"):
		return
	for player: Player in Players.all(_run.get_tree()):
		if not player.is_dead():
			player.heal(player.max_health - player.health)
	note(&"picnic")


## Spare Stuffing: `player` just popped back up instead of falling. A soft shockwave pushes the
## zombies around them away (numbers in run_rules.tres) and Banane quacks. Returns how many
## zombies were pushed.
func pop_back_up(player: Player) -> int:
	var rules: RunRules = _run.rules
	var center: Vector2 = player.global_position
	var pushed: Array[Zombie] = _run.enemies.query_circle(center, rules.spare_shockwave_radius)
	for zombie: Zombie in pushed:
		var away: Vector2 = zombie.position - center
		var direction: Vector2 = away.normalized() if away != Vector2.ZERO else Vector2.RIGHT
		zombie.knockback += direction * rules.spare_shockwave_push * zombie.knockback_taken()
	var wave: SpareShockwave = SpareShockwave.new(
		center, player.player_index, rules.spare_shockwave_radius
	)
	wave.lifetime = rules.spare_shockwave_seconds
	_run.effects.add_child(wave)
	Sfx.play(SPARE_SOUND, SPARE_PITCH)
	note(&"spare_stuffing", player)
	return pushed.size()


func _on_shield_changed(shield: float, player: Player) -> void:
	if shield > 0.0:
		note(&"second_helping", player)


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


## Every hero is in and the camera is in place: Spyglass hands the edge arrows the zombies, and
## Treasure Map hides its big gift box.
func run_started() -> void:
	if has(&"spyglass"):
		_run.pickup_arrows.threats = _run.enemies
		_run.pickup_arrows.threat_pointed.connect(_on_threat_pointed, CONNECT_ONE_SHOT)
	if has(&"treasure_map"):
		hide_treasure()


## Magnet Whistle: `player` levelled up, so every XP button on screen flies to them (a soft
## magnet sound, quieter than enemy danger). Returns how many buttons came.
func leveled_up(player: Player) -> int:
	if not player.has_trick(&"magnet_whistle"):
		return 0
	var count: int = _run.pickups.attract_in(_run.spawner.visible_rect(), player)
	if count > 0:
		Sfx.play(WHISTLE_SOUND, WHISTLE_PITCH)
		note(&"magnet_whistle", player)
	return count


## Treasure Map: puts the big gift box at a free spot away from the start screen (see
## `treasure_spot`); the edge arrows show the way. Returns the box.
func hide_treasure() -> GiftBox:
	var trick: TrickDef = _run.perks.trick(&"treasure_map")
	var box: GiftBox = _run.drop_gift_box(treasure_spot(trick.amount), true)
	box.treasure = true
	treasure = box
	note(&"treasure_map")
	return box


## A random spot in the room at least `away` pixels outside the screen the heroes start on,
## inside the wall margin and clear of furniture (numbers in gift_box_rules.tres).
func treasure_spot(away: float) -> Vector2:
	var rules: GiftBoxRules = _run.gift_box_rules
	var start: Vector2 = Players.centroid(_run.get_tree())
	var start_screen: Rect2 = start_rect(start).grow(away)
	var area: Rect2 = _run.arena.play_rect().grow(-rules.treasure_wall_margin)
	var furniture: Obstacles = _run.enemies.obstacles
	var radius: float = rules.treasure_stand_radius
	for attempt: int in TREASURE_TRIES:
		var x: float = rng.randf_range(area.position.x, area.end.x)
		var spot: Vector2 = Vector2(x, rng.randf_range(area.position.y, area.end.y))
		if not start_screen.has_point(spot) and not furniture.blocks(spot, radius):
			return spot
	# Very unlikely: the room corner farthest from the start, pushed out of any furniture.
	var corner: Vector2 = area.position
	var others: Array[Vector2] = [
		area.end, Vector2(area.end.x, area.position.y), Vector2(area.position.x, area.end.y)
	]
	for point: Vector2 in others:
		if point.distance_squared_to(start) > corner.distance_squared_to(start):
			corner = point
	return furniture.push_out(corner, radius)


## The world rect the screen shows when the camera is centred on `at`.
func start_rect(at: Vector2) -> Rect2:
	var view: Vector2 = _run.get_viewport_rect().size / _run.camera.zoom
	return Rect2(at - view / 2.0, view)


func _on_threat_pointed() -> void:
	note(&"spyglass")


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
