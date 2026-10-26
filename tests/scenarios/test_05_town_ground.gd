extends GutTest
## Scenario (spec 05 §3.1, AC-62): the compact town. Walking around the Pillow Fort, the camera
## never shows anything outside the room (pillow walls included), on 16:9 and 16:10 screens, and
## from the Bedroom door you see at least 4 buildings. The town runs in a SubViewport the size of
## the game's view, like the real window.

const TOWN_SCENE: PackedScene = preload("res://src/town/town.tscn")
const VIEW_16_9: Vector2i = Vector2i(1920, 1080)
const VIEW_16_10: Vector2i = Vector2i(1920, 1200)
## Frames to let the camera's smoothing catch up with the hero.
const SETTLE_FRAMES: int = 90
const CHECK_EVERY: int = 10
## Rounding slack in px.
const SLACK: float = 1.0

var view: SubViewport
var town: Town


func _open_town(size: Vector2i) -> void:
	view = SubViewport.new()
	view.size = size
	add_child_autofree(view)
	town = TOWN_SCENE.instantiate() as Town
	town.save = TownSave.new()
	view.add_child(town)
	await wait_physics_frames(2)


## The part of the town the camera shows right now, in town pixels.
func _shown() -> Rect2:
	return view.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, Vector2(view.size))


## Puts the hero at each corner of the quilt and in between; the view must stay in the room.
func _walk_everywhere() -> void:
	var room: Rect2 = town.layout.outer_rect().grow(SLACK)
	var quilt: Rect2 = town.layout.play_rect().grow(-40.0)
	var spots: Array[Vector2] = [
		quilt.position,
		Vector2(quilt.end.x, quilt.position.y),
		quilt.end,
		Vector2(quilt.position.x, quilt.end.y),
		quilt.get_center(),
		town.layout.spawn_position,
	]
	var hero: Player = Players.all(get_tree())[0]
	for spot: Vector2 in spots:
		hero.global_position = spot
		for i: int in SETTLE_FRAMES / CHECK_EVERY:
			await wait_physics_frames(CHECK_EVERY)
			var shown: Rect2 = _shown()
			assert_true(room.encloses(shown), "near %s the camera shows %s" % [spot, shown])


func test_ac62_the_camera_never_shows_outside_the_room_at_16_9() -> void:
	await _open_town(VIEW_16_9)
	await _walk_everywhere()


func test_ac62_the_camera_never_shows_outside_the_room_at_16_10() -> void:
	await _open_town(VIEW_16_10)
	await _walk_everywhere()


func test_ac62_from_the_door_you_see_at_least_4_buildings() -> void:
	await _open_town(VIEW_16_9)
	await wait_physics_frames(SETTLE_FRAMES)
	var shown: Rect2 = _shown()
	var seen: int = 0
	for spot: TownSpot in town.layout.spots:
		if shown.encloses(spot.rect):
			seen += 1
	assert_gte(seen, 4, "buildings fully on screen from the door")
	for spot: TownSpot in town.layout.spots:
		var distance: float = town.layout.distance_from_door(spot)
		assert_lte(distance, town.layout.max_building_distance, String(spot.id))
