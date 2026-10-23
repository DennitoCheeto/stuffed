class_name Town
extends Node2D
## The Pillow Fort (spec 03 §5, §6): a small walkable town between runs. The fort in the middle
## has the Bedroom door (E starts a run), next to it the Scrapbook stand, and 6 building spots
## around it that start as ruins. Walk up to one and press E to rebuild or upgrade it. Players
## walk like in a run (no zombies, no weapons); the camera follows. Anyone can rebuild (the
## jars are shared).

## A player pressed E at the Bedroom door: Main starts a run.
signal bedroom_requested
signal title_requested
signal quit_requested
## The town changed (a rebuild, an upgrade, a revealed building): Main saves it.
signal changed

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const PROMPT_COLOR: Color = Color("#f4efe6")
const BANNER_COLOR: Color = Color("#cfe3f0")
## Seconds after a rebuild before new buildings are revealed and the fort grows (after the pop).
const AFTER_BUILD_SECONDS: float = 1.0
## Seconds after arriving before buildings unlocked during the run are revealed.
const ARRIVAL_REVEAL_SECONDS: float = 0.8
const BANNER_SECONDS: float = 2.6
const BANNER_FADE: float = 0.5

@export var layout: TownLayout

## The saved town (Main sets it before adding the town to the tree).
var save: TownSave = TownSave.new()
var floor_art: TownFloor
var fort: TownFort
var scrapbook: ScrapbookStand
## Building spot id -> its building (a ruin at level 0).
var buildings: Dictionary[StringName, TownBuilding] = {}
var actors: Node2D
var camera: PlayersCamera
var hud: CanvasLayer
## Material id -> counter in the top-left corner.
var jars: Dictionary[String, JarCounter] = {}
## What E does where a player stands ("E  Go to the Bedroom", "E  Rebuild", ...).
var prompt_label: Label
## The info card next to the building a player stands at.
var card: BuildingCard = BuildingCard.new()
## "New building!" when a ruin's yarn falls away.
var banner: VBoxContainer
var banner_title: Label
var banner_subtitle: Label
var menu: TownMenu = TownMenu.new()

## Set once the Bedroom door was used (one press = one run).
var _leaving: bool = false
## Counts down to revealing new buildings and growing the fort (0 = nothing waiting).
var _settle_left: float = 0.0
var _banner_left: float = 0.0


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
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	spawn_player(0)
	add_child(card)
	camera = PlayersCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.set_bounds(layout.outer_rect())
	camera.make_current()
	camera.snap_to_players()
	_build_hud()
	refresh()
	if not pending_reveals().is_empty():
		_settle_left = ARRIVAL_REVEAL_SECONDS
	add_child(menu)
	menu.resumed.connect(func() -> void: process_mode = Node.PROCESS_MODE_INHERIT)
	menu.title_requested.connect(title_requested.emit)
	menu.quit_requested.connect(quit_requested.emit)


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
			prompt = "Scrapbook: coming soon"
		else:
			var building: TownBuilding = building_near(player)
			if building == null:
				continue
			if pressed:
				try_build(building)
			if shown == null:
				shown = building
				prompt = BuildingCard.action_text(building, save)
				_show_card(building, player)
	if shown == null:
		card.hide_card()
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
	var new_level: int = building.level + 1
	save.building_levels[String(building.spot.id)] = new_level
	building.play_build(new_level)
	refresh()
	_settle_left = AFTER_BUILD_SECONDS
	changed.emit()
	return true


## Updates the jars and every sign for what's in the jars now.
func refresh() -> void:
	for material: String in jars:
		jars[material].show_amount(save.material(material))
	for id: StringName in buildings:
		buildings[id].refresh(save)


## After a rebuild settles (and on arrival): the fort grows and newly unlocked ruins lose
## their yarn.
func settle() -> void:
	var pieces: int = TownFort.pieces_for(save.total_levels(), layout.fort_piece_every)
	if pieces > fort.pieces:
		fort.pieces = pieces
		add_child(TownPuff.new(layout.fort_rect, 0.7))
		Sfx.play(&"upgrade", 0.8)
	reveal_new_buildings()


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


func is_banner_showing() -> bool:
	return banner.visible


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
	card.show_for(building, save, above)


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
	prompt_label = TownArt.label("", 34)
	prompt_label.add_theme_color_override(&"font_color", PROMPT_COLOR)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_label.offset_bottom = -60.0
	prompt_label.visible = false
	hud.add_child(prompt_label)
	banner = VBoxContainer.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 110.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	hud.add_child(banner)
	banner_title = TownArt.label("", 60)
	banner_title.add_theme_color_override(&"font_color", BANNER_COLOR)
	banner.add_child(banner_title)
	banner_subtitle = TownArt.label("", 30)
	banner.add_child(banner_subtitle)
