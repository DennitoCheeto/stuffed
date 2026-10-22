class_name Town
extends Node2D
## The Pillow Fort (spec 03 §5): a small walkable town between runs. The fort in the middle has
## the Bedroom door (E starts a run), next to it the Scrapbook stand, and 6 building spots around
## it that start as ruins. Players walk like in a run (no zombies, no weapons); the camera follows.

## A player pressed E at the Bedroom door: Main starts a run.
signal bedroom_requested
signal title_requested
signal quit_requested

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const PROMPT_COLOR: Color = Color("#f4efe6")

@export var layout: TownLayout

## The saved town (Main sets it before adding the town to the tree).
var save: TownSave = TownSave.new()
var floor_art: TownFloor
var fort: TownFort
var scrapbook: ScrapbookStand
## Building spot id -> its ruin.
var ruins: Dictionary[StringName, TownRuin] = {}
var actors: Node2D
var camera: PlayersCamera
var hud: CanvasLayer
## Material id -> counter in the top-left corner.
var jars: Dictionary[String, JarCounter] = {}
## "E  Go to the Bedroom" while a player stands at the door.
var prompt_label: Label
var menu: TownMenu = TownMenu.new()

## Set once the Bedroom door was used (one press = one run).
var _leaving: bool = false


func _ready() -> void:
	floor_art = TownFloor.new(layout)
	add_child(floor_art)
	_build_walls()
	var buildings: Node2D = Node2D.new()
	buildings.name = "Buildings"
	add_child(buildings)
	fort = TownFort.new(layout)
	fort.name = "Fort"
	buildings.add_child(fort)
	scrapbook = ScrapbookStand.new(layout.scrapbook_rect)
	buildings.add_child(scrapbook)
	for spot: TownSpot in layout.spots:
		var ruin: TownRuin = TownRuin.new(spot, spot.is_unlocked_in(save))
		buildings.add_child(ruin)
		ruins[spot.id] = ruin
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	spawn_player(0)
	camera = PlayersCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.set_bounds(layout.outer_rect())
	camera.make_current()
	camera.snap_to_players()
	_build_hud()
	add_child(menu)
	menu.resumed.connect(func() -> void: process_mode = Node.PROCESS_MODE_INHERIT)
	menu.title_requested.connect(title_requested.emit)
	menu.quit_requested.connect(quit_requested.emit)


func _physics_process(_delta: float) -> void:
	var at_door: bool = false
	var at_scrapbook: bool = false
	for player: Player in Players.all(get_tree()):
		if is_at_door(player):
			at_door = true
			if player.just_pressed("interact"):
				enter_bedroom()
		elif is_at_scrapbook(player):
			at_scrapbook = true
	if at_door:
		prompt_label.text = "E   Go to the Bedroom"
	elif at_scrapbook:
		prompt_label.text = "Scrapbook: coming soon"
	prompt_label.visible = at_door or at_scrapbook


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


## Ruins that can be rebuilt now (not tangled in yarn).
func open_ruins() -> Array[TownRuin]:
	var result: Array[TownRuin] = []
	for id: StringName in ruins:
		if ruins[id].unlocked:
			result.append(ruins[id])
	return result


## What pressing E at the door does: off to the Bedroom (once).
func enter_bedroom() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play(&"pop")
	bedroom_requested.emit()


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


## The jars in the top-left corner and the prompt at the bottom.
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
		counter.show_amount(save.material(material))
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
