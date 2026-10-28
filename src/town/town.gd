class_name Town
extends Node2D
## The Pillow Fort (spec 03 §5, §6): a small walkable town between runs. The fort in the middle
## has the Bedroom door (E starts a run), next to it the Scrapbook stand (E opens the book), and
## 6 building spots around it that start as ruins. Walk up to one and press E to rebuild or
## upgrade it. Players walk like in a run (no zombies, no weapons); the camera follows. Anyone
## can rebuild (the jars are shared).

## A player pressed E at the Bedroom door: Main starts a run.
signal bedroom_requested
signal title_requested
signal quit_requested
## The developer menu's "Reset town": Main starts a fresh town.
signal reset_requested
## The town changed (a rebuild, an upgrade, a revealed building): Main saves it.
signal changed

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
## The level-up cards (weapon names and icons for the Toy Box Armory).
const UPGRADE_POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
## Who can be rescued (to find a saved plushie by its id).
const RESCUE_RULES: RescueRules = preload("res://data/town/rescue_rules.tres")
## How plushies walk, sit and wave at home.
const PLUSHIE_RULES: PlushieTownRules = preload("res://data/town/plushie_town_rules.tres")
const PROMPT_COLOR: Color = UiColors.INK
## Seconds after a rebuild before new buildings are revealed and the fort grows (after the pop).
const AFTER_BUILD_SECONDS: float = 1.0
## Seconds after arriving before buildings unlocked during the run are revealed.
const ARRIVAL_REVEAL_SECONDS: float = 0.8
const BANNER_SECONDS: float = 2.6
const BANNER_FADE: float = 0.5

@export var layout: TownLayout

## The saved town (Main sets it before adding the town to the tree).
var save: TownSave = TownSave.new()
## How many players walk around (Main sets it: everybody who came home from the run).
var player_count: int = 1
var floor_art: TownFloor
var fort: TownFort
var scrapbook: ScrapbookStand
## Building spot id -> its building (a ruin at level 0).
var buildings: Dictionary[StringName, TownBuilding] = {}
## Plushie id -> the rescued plushie living in town.
var plushies: Dictionary[String, TownPlushie] = {}
## Where rescued plushies wait for a Hospital bed.
var tent: PlushieTent
## Which hangout spots are open and who uses them (spec 05 §3.4).
var hangouts: PlushieHangouts
var actors: Node2D
## Sunbeams, dust sparkles and the paper plane over everything (spec 05 §3.4).
var life: TownLife
var camera: PlayersCamera
var hud: CanvasLayer
## Material id -> counter in the top-left corner.
var jars: Dictionary[String, JarCounter] = {}
## What E does where a player stands ("E  Go to the Bedroom", "E  Rebuild", ...).
var prompt_label: Label
## The info card next to the building a player stands at.
var card: BuildingCard = BuildingCard.new()
## "New building!" when a ruin's yarn falls away: a taped felt patch with a hand-written title.
var banner: FeltPanel = FeltPanel.new(-2.0)
var banner_title: Label
var banner_subtitle: Label
var menu: TownMenu = TownMenu.new()
## Choosing Banane's starting weapon (Toy Box Armory, level 3).
var picker: StartWeaponPicker = StartWeaponPicker.new()
## "New weapons for your cards!" when an Armory level adds weapons.
var unlock_toast: WeaponUnlockToast = WeaponUnlockToast.new()
## The Scrapbook, opened (E at its stand).
var book: ScrapbookBook = ScrapbookBook.new()
## Developer shortcuts (F1, spec 03 §10).
var dev_menu: TownDevMenu = TownDevMenu.new()
## Buying building tricks (spec 06).
var tricks: TownTricks = TownTricks.new(self)

## Set once the Bedroom door was used (one press = one run).
var _leaving: bool = false
## Counts down to revealing new buildings and growing the fort (0 = nothing waiting).
var _settle_left: float = 0.0
var _banner_left: float = 0.0
var _banner_drop: Tween


func _ready() -> void:
	floor_art = TownFloor.new(layout)
	add_child(floor_art)
	_build_walls()
	var holder: Node2D = Node2D.new()
	holder.name = "Buildings"
	add_child(holder)
	fort = TownFort.new(layout)
	fort.name = "Fort"
	fort.pieces = TownFort.pieces_for(save.total_levels(), layout.fort_piece_every)
	holder.add_child(fort)
	scrapbook = ScrapbookStand.new(layout.scrapbook_rect)
	holder.add_child(scrapbook)
	for spot: TownSpot in layout.spots:
		var level: int = save.building_level(String(spot.id))
		var building: TownBuilding = TownBuilding.new(spot, level, _is_open(spot))
		holder.add_child(building)
		buildings[spot.id] = building
	tent = PlushieTent.new(PLUSHIE_RULES, layout.tent_position)
	holder.add_child(tent)
	hangouts = PlushieHangouts.new(layout.plushie_spots, save)
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	for id: String in save.plushies:
		var who: PlushieDef = RESCUE_RULES.find(id)
		if save.plushies[id] == "in_town" and who != null:
			spawn_plushie(who, random_town_spot(), true)
	refresh_tent()
	for index: int in maxi(player_count, 1):
		spawn_player(index)
	life = TownLife.new(layout)
	add_child(life)
	add_child(card)
	camera = PlayersCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.set_bounds(layout.outer_rect())
	camera.make_current()
	camera.snap_to_players()
	_build_hud()
	tricks.attach(hud)
	refresh()
	if not pending_reveals().is_empty() or can_move_in():
		_settle_left = ARRIVAL_REVEAL_SECONDS
	add_child(menu)
	menu.resumed.connect(func() -> void: process_mode = Node.PROCESS_MODE_INHERIT)
	menu.title_requested.connect(title_requested.emit)
	menu.quit_requested.connect(quit_requested.emit)
	add_child(picker)
	picker.chosen.connect(_on_start_weapon_chosen)
	picker.closed.connect(func() -> void: process_mode = Node.PROCESS_MODE_INHERIT)
	add_child(book)
	book.closed.connect(func() -> void: process_mode = Node.PROCESS_MODE_INHERIT)
	add_child(dev_menu)
	dev_menu.setup(self)


func _physics_process(delta: float) -> void:
	var prompt: String = ""
	var shown: TownBuilding = null
	for player: Player in Players.all(get_tree()):
		var pressed: bool = player.just_pressed("interact")
		if is_at_door(player):
			prompt = "E   Go to the Bedroom"
			if pressed:
				enter_bedroom()
		elif is_at_scrapbook(player):
			prompt = "E   Open the Scrapbook"
			if pressed:
				open_scrapbook()
		else:
			var building: TownBuilding = building_near(player)
			if building == null:
				continue
			if pressed:
				interact(building)
			elif player.just_pressed("tricks"):
				tricks.open(building, player.player_index)
			if shown == null:
				shown = building
				prompt = BuildingCard.action_text(building, save)
				_show_card(building, player)
	if shown == null:
		card.hide_card()
	for id: StringName in buildings:
		buildings[id].card_shown = buildings[id] == shown
	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()
	if _settle_left > 0.0:
		_settle_left -= delta
		if _settle_left <= 0.0:
			_settle_left = 0.0
			settle()


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		banner.modulate.a = clampf(_banner_left / BANNER_FADE, 0.0, 1.0)
		banner.visible = _banner_left > 0.0


## Esc opens the town menu.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not menu.is_open():
		get_viewport().set_input_as_handled()
		open_menu()


func open_menu() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	menu.open()


## Adds a hero for player `index` (0 = player 1) in front of the door. Unarmed: it's home.
func spawn_player(index: int) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.player_index = index
	player.armed = false
	player.position = layout.spawn_position + Vector2(layout.spawn_spacing * index, 0.0)
	player.dashed.connect(func(_from: Vector2, _direction: Vector2) -> void: Sfx.play(&"dash"))
	actors.add_child(player)
	return player


func is_at_door(player: Player) -> bool:
	return TownLayout.distance_to(layout.door_rect, player.global_position) <= layout.reach


func is_at_scrapbook(player: Player) -> bool:
	var distance: float = TownLayout.distance_to(layout.scrapbook_rect, player.global_position)
	return distance <= layout.reach


## The building `player` stands next to (null = none in reach).
func building_near(player: Player) -> TownBuilding:
	var best: TownBuilding = null
	var best_distance: float = layout.reach
	for id: StringName in buildings:
		var rect: Rect2 = buildings[id].spot.rect
		var distance: float = TownLayout.distance_to(rect, player.global_position)
		if distance <= best_distance:
			best = buildings[id]
			best_distance = distance
	return best


## Buildings that can be rebuilt or upgraded now (not tangled in yarn).
func open_buildings() -> Array[TownBuilding]:
	var result: Array[TownBuilding] = []
	for id: StringName in buildings:
		if buildings[id].unlocked:
			result.append(buildings[id])
	return result


## What pressing E at `building` does: pays for its next level if the jars hold enough and plays
## the rebuild moment. Returns false (and only shows what's missing) if it can't.
func try_build(building: TownBuilding) -> bool:
	if building.is_busy() or not building.unlocked:
		return false
	var next: BuildingLevel = building.building.next(building.level)
	if next == null:
		return false
	if not save.spend(next.cost()):
		Sfx.play(&"nope")
		return false
	_raise(building, next)
	return true


## Developer menu: the next level of `building` for free, even if it's still tangled in yarn.
func dev_build(building: TownBuilding) -> bool:
	var next: BuildingLevel = building.building.next(building.level)
	if building.is_busy() or next == null:
		return false
	_raise(building, next)
	return true


## Gives `building` its next level `next` (already paid for) and plays the moment.
func _raise(building: TownBuilding, next: BuildingLevel) -> void:
	var new_level: int = building.level + 1
	save.building_levels[String(building.spot.id)] = new_level
	building.play_build(new_level)
	if not next.unlocks_weapons.is_empty():
		unlock_toast.show_weapons(_weapons(next.unlocks_weapons))
	tricks.on_built(building, new_level)
	refresh()
	_settle_left = AFTER_BUILD_SECONDS
	changed.emit()


## What pressing E next to `building` does: choose the starting weapon at a fully built Toy
## Box Armory, else rebuild or upgrade it.
func interact(building: TownBuilding) -> void:
	if can_choose_start_weapon(building):
		open_weapon_picker()
	else:
		try_build(building)


## True when E at `building` opens the starting weapon choice (nothing left to upgrade there).
func can_choose_start_weapon(building: TownBuilding) -> bool:
	if building.is_busy() or building.building.next(building.level) != null:
		return false
	return building.building.chooses_start_weapon(building.level)


## What the town's buildings change in the next run.
func perks() -> TownPerks:
	return TownPerks.from_save(save, layout)


## The weapon Banane starts the next run with (its upgrade pool id).
func start_weapon_id() -> StringName:
	var hero: Player = Players.all(get_tree())[0]
	return perks().starting_weapon(UPGRADE_POOL, hero.stats.starting_weapon).id


## Opens the Scrapbook; the town waits until it closes.
func open_scrapbook() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	book.open(save)


## Shows the starting weapon choice; the town waits until it closes.
func open_weapon_picker() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	_banner_left = 0.0
	banner.visible = false
	unlock_toast.visible = false
	picker.open(perks().open_weapons(UPGRADE_POOL), start_weapon_id())


func _on_start_weapon_chosen(id: StringName) -> void:
	save.start_weapon = String(id)
	var weapon: UpgradeDef = UPGRADE_POOL.find(id)
	Sfx.play(weapon.weapon.sound, weapon.weapon.sound_pitch)
	changed.emit()


## The pool entries of the weapons `ids`.
func _weapons(ids: Array[StringName]) -> Array[UpgradeDef]:
	var result: Array[UpgradeDef] = []
	for id: StringName in ids:
		var weapon: UpgradeDef = UPGRADE_POOL.find(id)
		if weapon != null:
			result.append(weapon)
	return result


## An extra line on the info card: beds at the Hospital, the starting weapon at a building that
## lets you choose it.
func _note_for(building: TownBuilding) -> String:
	if _has_beds(building.building):
		return _bed_note(building.level)
	if not building.building.chooses_start_weapon(building.level):
		return ""
	return "Starting weapon: " + UPGRADE_POOL.find(start_weapon_id()).display_name


func _has_beds(building: BuildingDef) -> bool:
	for level: BuildingLevel in building.levels:
		if level.plushie_beds > 0:
			return true
	return false


## "Beds used: 1 / 2   1 waiting in the tent".
func _bed_note(level: int) -> String:
	var parts: PackedStringArray = []
	if level > 0:
		parts.append("Beds used: %d / %d" % [save.plushies_in_town(), hospital_beds()])
	var waiting: int = save.waiting_plushies().size()
	if waiting > 0:
		parts.append("%d waiting in the tent" % waiting)
	return "   ".join(parts)


## Updates the jars and every sign for what's in the jars now.
func refresh() -> void:
	for material: String in jars:
		jars[material].show_amount(save.material(material))
	for id: StringName in buildings:
		buildings[id].refresh(save)


## After a rebuild settles (and on arrival): the fort grows, newly unlocked ruins lose their
## yarn and waiting plushies move into free Hospital beds.
func settle() -> void:
	var pieces: int = TownFort.pieces_for(save.total_levels(), layout.fort_piece_every)
	if pieces > fort.pieces:
		fort.pieces = pieces
		add_child(TownPuff.new(layout.fort_rect, 0.7))
		Sfx.play(&"upgrade", 0.8)
	reveal_new_buildings()
	move_in_waiting()


## True while a rebuild or arrival is still waiting for `settle` (or a building is animating).
func is_settling() -> bool:
	if _settle_left > 0.0:
		return true
	for id: StringName in buildings:
		if buildings[id].is_busy():
			return true
	return false


## Ruins whose unlock was reached but whose "New building!" moment hasn't played yet.
func pending_reveals() -> Array[TownBuilding]:
	var result: Array[TownBuilding] = []
	for spot: TownSpot in layout.spots:
		var building: TownBuilding = buildings[spot.id]
		if not building.unlocked and spot.is_unlocked_in(save):
			result.append(building)
	return result


## The yarn falls off every ruin that can be rebuilt now, with a "New building!" banner.
func reveal_new_buildings() -> Array[TownBuilding]:
	var revealed: Array[TownBuilding] = pending_reveals()
	if revealed.is_empty():
		return revealed
	var names: PackedStringArray = []
	for building: TownBuilding in revealed:
		building.reveal()
		names.append(building.building.display_name)
		if not save.revealed.has(String(building.spot.id)):
			save.revealed.append(String(building.spot.id))
	var title: String = "New building!" if revealed.size() == 1 else "New buildings!"
	show_banner(title, "%s can be rebuilt now" % " and ".join(names))
	Sfx.play(&"new_building")
	refresh()
	changed.emit()
	return revealed


func show_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
	_banner_left = BANNER_SECONDS
	banner.modulate.a = 1.0
	banner.visible = true
	_drop_banner()


## The banner drops in from above with a little overshoot (not with reduced menu animations).
func _drop_banner() -> void:
	if _banner_drop != null:
		_banner_drop.kill()
	banner.rest()
	if UiFeel.reduced() or not is_inside_tree():
		return
	var style: UiStyle = UiFeel.STYLE
	banner.lift = style.open_drop
	banner.fade = 0.0
	_banner_drop = create_tween().set_parallel()
	var drop: PropertyTweener = _banner_drop.tween_property(banner, "lift", 0.0, style.open_seconds)
	drop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_drop.tween_property(banner, "fade", 1.0, style.open_seconds * 0.4)


func is_banner_showing() -> bool:
	return banner.visible


## Beds for plushies in town right now (the Plush Hospital at its level).
func hospital_beds() -> int:
	var beds: int = 0
	for spot: TownSpot in layout.spots:
		var reached: BuildingLevel = spot.building.reached(save.building_level(String(spot.id)))
		if reached != null:
			beds += reached.plushie_beds
	return beds


func free_beds() -> int:
	return maxi(hospital_beds() - save.plushies_in_town(), 0)


## True when a plushie waits in the tent and there is a free bed for it.
func can_move_in() -> bool:
	return free_beds() > 0 and not save.waiting_plushies().is_empty()


## Every waiting plushie that gets a free bed (first come, first served) is stitched up and
## moves into town, with a banner. Returns the plushies that moved in.
func move_in_waiting() -> Array[TownPlushie]:
	var moved: Array[TownPlushie] = []
	var names: PackedStringArray = []
	for id: String in save.waiting_plushies():
		var who: PlushieDef = RESCUE_RULES.find(id)
		if free_beds() <= 0:
			break
		if who == null:
			continue
		save.plushies[id] = "in_town"
		moved.append(spawn_plushie(who, hospital_door(), false))
		names.append(who.display_name)
	if moved.is_empty():
		return moved
	var bonus: int = roundi(PLUSHIE_RULES.coin_bonus_per_plushie * 100.0)
	var title: String = PLUSHIE_RULES.moved_in_banner % " and ".join(names)
	show_banner(title, PLUSHIE_RULES.moved_in_subtitle % bonus)
	Sfx.play(PLUSHIE_RULES.moved_in_sound)
	refresh_tent()
	changed.emit()
	return moved


## Adds the rescued plushie `who` to the town at `at` (`stitched` = it already lived here).
func spawn_plushie(who: PlushieDef, at: Vector2, stitched: bool) -> TownPlushie:
	var plushie: TownPlushie = TownPlushie.new(who, PLUSHIE_RULES, layout, at, stitched)
	plushie.hangouts = hangouts
	actors.add_child(plushie)
	plushies[who.id] = plushie
	return plushie


## Where a freshly stitched plushie steps out: beside the Plush Hospital.
func hospital_door() -> Vector2:
	for spot: TownSpot in layout.spots:
		for level: BuildingLevel in spot.building.levels:
			if level.plushie_beds > 0:
				var margin: float = PLUSHIE_RULES.keep_clear + 10.0
				return Vector2(spot.rect.position.x - margin, spot.rect.end.y - 20.0)
	return layout.spawn_position


## A random free spot on the blanket (where plushies stand when you get home).
func random_town_spot() -> Vector2:
	for i: int in 50:
		var spot: Vector2 = Vector2(randf() * layout.size.x, randf() * layout.size.y)
		if TownPlushie.is_walkable(layout, spot, PLUSHIE_RULES.keep_clear):
			return spot
	return layout.spawn_position + Vector2(0.0, 120.0)


## The tent shows who still waits for a bed.
func refresh_tent() -> void:
	var waiting: Array[PlushieDef] = []
	for id: String in save.waiting_plushies():
		var who: PlushieDef = RESCUE_RULES.find(id)
		if who != null:
			waiting.append(who)
	tent.show_waiting(waiting)


## What pressing E at the door does: off to the Bedroom (once).
func enter_bedroom() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play(&"pop")
	bedroom_requested.emit()


## True when `spot` can be rebuilt and its yarn already fell away (or it never had any).
func _is_open(spot: TownSpot) -> bool:
	if not spot.is_unlocked_in(save):
		return false
	return not spot.starts_locked() or save.revealed.has(String(spot.id))


func _show_card(building: TownBuilding, player: Player) -> void:
	var above: bool = player.global_position.y > building.spot.rect.get_center().y
	card.show_for(building, save, above, _note_for(building))


func _build_walls() -> void:
	var outer: Rect2 = layout.outer_rect()
	var t: float = layout.wall_thickness
	var rects: Array[Rect2] = [
		Rect2(outer.position, Vector2(outer.size.x, t)),
		Rect2(Vector2(outer.position.x, layout.size.y), Vector2(outer.size.x, t)),
		Rect2(Vector2(-t, 0.0), Vector2(t, layout.size.y)),
		Rect2(Vector2(layout.size.x, 0.0), Vector2(t, layout.size.y)),
	]
	rects.append_array(layout.blocking_rects())
	for rect: Rect2 in rects:
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = Arena.WALL_LAYER
		body.collision_mask = 0
		body.position = rect.get_center()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


## The jars in the top-left corner, the banner at the top and the prompt at the bottom.
func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "Hud"
	add_child(hud)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(32, 24)
	row.add_theme_constant_override(&"separation", 36)
	hud.add_child(row)
	for material: String in JarIcon.MATERIALS:
		var counter: JarCounter = JarCounter.new(material)
		row.add_child(counter)
		jars[material] = counter
	prompt_label = UiFonts.label("", 30, PROMPT_COLOR, UiFonts.heading())
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tag: StyleBoxFelt = StyleBoxFelt.new(UiColors.TAG, UiColors.TAG_STITCH)
	tag.radius = 14.0
	tag.stitch_inset = 5.0
	tag.stitch_width = 2.0
	tag.shadow = UiColors.SHADOW
	tag.shadow_offset = 4.0
	tag.pad(24, 6)
	prompt_label.add_theme_stylebox_override(&"normal", tag)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_label.offset_bottom = -60.0
	prompt_label.visible = false
	hud.add_child(prompt_label)
	banner.add_tape(0.5, 3.0, UiColors.TAPE_TEAL)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 110.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	hud.add_child(banner)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.content.add_child(lines)
	var heading: HandTitle = HandTitle.new("", 60, UiColors.PURPLE, 0.0)
	banner_title = heading.label
	lines.add_child(heading)
	banner_subtitle = UiFonts.label("", 26, UiColors.INK)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lines.add_child(banner_subtitle)
	hud.add_child(unlock_toast)
