class_name TownWardrobe
extends Node2D
## The Wardrobe next to the fort door (spec 08 §2, §4, §5, AC-85, AC-86): it appears once a
## plushie hero is unlocked, with a "Pip wants to play!" banner (later unlocks get their own
## short banner). E next to it opens the hero picker; picking swaps that player's hero in the
## town at once (a puff of stuffing and a pop). Every hero nobody plays lives in town like the
## other plushies, Banane too (his puppet walks around); the plushie you play doesn't also
## wander around or wait in the tent. Not a building: no level, no price, zombies ignore it.

static var _look: BuildingSketch

var town: Town
var rules: WardrobeRules = WardrobeRules.current()
var rect: Rect2
var picker: HeroPicker = HeroPicker.new()
## Banane living in town while nobody plays him (null = someone plays him).
var banane: TownPlushie

var _roster: HeroRoster = HeroRoster.current()
var _sign: Label


func _init(home: Town) -> void:
	town = home
	rect = home.layout.wardrobe_rect
	name = "Wardrobe"
	position = Vector2(rect.get_center().x, rect.end.y)
	picker.pool = Town.UPGRADE_POOL


func _ready() -> void:
	material = WorldPalette.current().grain_material()
	_sign = TownArt.label(rules.sign_text, 22)
	add_child(_sign)
	TownArt.center_label(_sign, 0.0, 10.0, 200.0)
	visible = is_shown()
	town.add_child(picker)
	picker.chosen.connect(swap)
	picker.closed.connect(func() -> void: town.process_mode = Node.PROCESS_MODE_INHERIT)


## The Wardrobe's look (built once).
static func look() -> BuildingSketch:
	if _look == null:
		_look = WardrobeLook.build(WardrobeRules.current().art_scale)
	return _look


func _draw() -> void:
	look().draw(self)


## True once a plushie hero is unlocked and its banner was shown (the Wardrobe stands).
func is_shown() -> bool:
	return town.save.revealed.has(WardrobeRules.REVEALED_ID) and _has_plushie_heroes()


## True when `player` stands close enough to press E at it.
func is_near(player: Player) -> bool:
	if not visible:
		return false
	return TownLayout.distance_to(rect, player.global_position) <= town.layout.reach


## Opens the hero picker for player `by` (0 = player 1); the town waits until it closes.
func open(by: int) -> void:
	town.process_mode = Node.PROCESS_MODE_DISABLED
	picker.open(by, _roster, town.save, taken_by_others(by))


## Hero id -> the player slot playing it, for every player but `slot`.
func taken_by_others(slot: int) -> Dictionary[StringName, int]:
	var taken: Dictionary[StringName, int] = {}
	for player: Player in Players.all(town.get_tree()):
		if player.player_index != slot:
			taken[player.stats.id] = player.player_index
	return taken


## Player `slot` plays `hero` from now on: saved at once, the hero is swapped in place with a
## puff, and the town members follow (the one swapped out moves into town).
func swap(slot: int, hero: HeroStats) -> void:
	var player: Player = _player(slot)
	if player != null and player.stats == hero:
		return
	town.save.set_hero(slot, String(hero.id))
	var at: Vector2 = town.layout.spawn_position
	if player != null:
		at = player.position
		player.get_parent().remove_child(player)
		player.queue_free()
	town.spawn_player(slot).position = at
	town.add_child(TownPuff.new(Rect2(at - Vector2(40.0, 70.0), Vector2(80.0, 80.0)), 0.7))
	Sfx.play(rules.swap_sound, rules.swap_pitch)
	refresh_members(false)
	town.changed.emit()


## The rescued plushies the players play right now (they don't also live in town).
func played_plushie_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for slot: int in maxi(town.player_count, 1):
		var hero: HeroStats = _roster.hero_for(town.save, slot)
		if hero.plushie != null:
			ids.append(hero.plushie.id)
	return ids


## True when Banane is played by somebody.
func is_banane_played() -> bool:
	for slot: int in maxi(town.player_count, 1):
		if _roster.hero_for(town.save, slot).plushie == null:
			return true
	return false


## Every hero nobody plays lives in town; the played plushies leave it. `arriving` = the town
## just opened (members stand around), else they hop out of the Wardrobe.
func refresh_members(arriving: bool) -> void:
	var played: PackedStringArray = played_plushie_ids()
	for id: String in town.plushies.keys():
		if played.has(id):
			var gone: TownPlushie = town.plushies[id]
			town.plushies.erase(id)
			gone.get_parent().remove_child(gone)
			gone.queue_free()
	for id: String in town.save.plushies:
		if town.save.plushies[id] != "in_town" or played.has(id) or town.plushies.has(id):
			continue
		var who: PlushieDef = Town.RESCUE_RULES.find(id)
		if who != null:
			town.spawn_plushie(who, _step_out(arriving), true)
	_refresh_banane(arriving)
	town.refresh_tent()


## Where a hero that just stopped being played steps out: beside the Wardrobe.
func door() -> Vector2:
	return Vector2(rect.end.x + 40.0, rect.end.y + 10.0)


## True when a hero's "wants to play!" banner (or the Wardrobe itself) is still to come.
func has_news() -> bool:
	return not _news().is_empty()


## The Wardrobe pops up (first time) and new heroes get their banner. Returns true if a banner
## was shown.
func announce() -> bool:
	var heroes: Array[HeroStats] = _news()
	if heroes.is_empty():
		return false
	var names: PackedStringArray = []
	for hero: HeroStats in heroes:
		names.append(hero.display_name)
		town.save.revealed.append(WardrobeRules.HERO_PREFIX + String(hero.id))
	var subtitle: String = rules.later_subtitle
	if not town.save.revealed.has(WardrobeRules.REVEALED_ID):
		town.save.revealed.append(WardrobeRules.REVEALED_ID)
		subtitle = heroes[0].try_on_text if heroes.size() == 1 else rules.later_subtitle
		_pop_in()
	var title: String = rules.unlock_title if names.size() == 1 else rules.unlock_title_many
	town.show_banner(title % _listed(names), subtitle)
	Sfx.play(rules.reveal_sound)
	town.changed.emit()
	return true


## "Pip", "Pip and Böbö", "Pip, Böbö and BamBam".
static func _listed(names: PackedStringArray) -> String:
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, -1)) + " and " + names[-1]


func _news() -> Array[HeroStats]:
	var heroes: Array[HeroStats] = []
	for hero: HeroStats in _roster.heroes:
		if hero.plushie == null or not _roster.is_unlocked(hero, town.save):
			continue
		if not town.save.revealed.has(WardrobeRules.HERO_PREFIX + String(hero.id)):
			heroes.append(hero)
	return heroes


func _has_plushie_heroes() -> bool:
	return _roster.unlocked(town.save).size() > 1


func _pop_in() -> void:
	visible = true
	town.add_child(TownPuff.new(rect.grow(10.0), 0.8))
	if not is_inside_tree() or UiFeel.reduced():
		return
	scale = Vector2(0.3, 0.3)
	var pop: Tween = create_tween()
	pop.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)


func _refresh_banane(arriving: bool) -> void:
	var member: PlushieDef = _roster.starter().town_member
	if is_banane_played() or member == null:
		if banane != null:
			banane.get_parent().remove_child(banane)
			banane.queue_free()
			banane = null
		return
	if banane != null:
		return
	banane = TownPlushie.new(member, Town.PLUSHIE_RULES, town.layout, _step_out(arriving), true)
	town.actors.add_child(banane)


func _step_out(arriving: bool) -> Vector2:
	return town.random_town_spot() if arriving else door()


func _player(slot: int) -> Player:
	for player: Player in Players.all(town.get_tree()):
		if player.player_index == slot:
			return player
	return null
