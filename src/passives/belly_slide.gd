class_name BellySlide
extends Node2D
## Robbar's passive (spec 08 §3, AC-88): his dash is a long belly slide (`dash_distance` /
## `dash_duration` in robbar.tres). Every zombie on the way takes a small hit, once per slide, and
## the slide leaves a short wet streak on the floor. He can't be hurt while sliding (like any
## dash). Numbers in the hero's .tres ("Belly Slide").

const TRAIL_WIDTH: float = 14.0

var player: Player
## Zombies hit by the current slide (each only once).
var hit: Array[Zombie] = []
## How many zombies the slides hit in this run (tests).
var hits: int = 0

## The streak: floor points and their age in seconds.
var _trail: PackedVector2Array = []
var _ages: PackedFloat32Array = []


func setup(owner_player: Player) -> void:
	player = owner_player
	player.dashed.connect(_on_dashed)
	# The streak lies on the floor, in world space.
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.FLOOR_MARKS


func _on_dashed(_from_position: Vector2, _direction: Vector2) -> void:
	hit.clear()


func _physics_process(delta: float) -> void:
	_age_trail(delta)
	if not player.armed or not player.is_dashing():
		return
	_trail.append(player.global_position + HeroMarker.FEET * 0.5)
	_ages.append(0.0)
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager == null:
		return
	var stats: HeroStats = player.stats
	for zombie: Zombie in manager.query_circle(player.global_position, stats.belly_slide_reach):
		if zombie.dead or hit.has(zombie):
			continue
		hit.append(zombie)
		hits += 1
		manager.damage_from(WeaponTally.BELLY_SLIDE, zombie, stats.belly_slide_damage)


## How many points the streak has right now (tests).
func trail_size() -> int:
	return _trail.size()


func _age_trail(delta: float) -> void:
	var keep: float = player.stats.belly_slide_trail_seconds
	for i: int in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] > keep:
		_ages.remove_at(0)
		_trail.remove_at(0)
	queue_redraw()


func _draw() -> void:
	var color: Color = player.stats.belly_slide_trail_color
	var keep: float = maxf(player.stats.belly_slide_trail_seconds, 0.001)
	for i: int in range(1, _trail.size()):
		var fade: float = 1.0 - _ages[i] / keep
		draw_line(_trail[i - 1], _trail[i], Color(color, color.a * fade), TRAIL_WIDTH * fade, true)
