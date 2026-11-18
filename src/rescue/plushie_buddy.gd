class_name PlushieBuddy
extends Node2D
## Plushie Buddy (spec 06 §3, §3.1): the plushie rescued last comes along in the run. It trots
## after its hero and sends the XP buttons near it to that hero. Drawn small with its town look
## (PlushieLook, danger colours calmed) on a soft light halo, so it never looks like a zombie or
## an enemy shot. It can't be hurt (no body, no hitbox) and doesn't attack. Numbers in
## rescue_rules.tres.

## It sent `count` buttons to `player` (only when count > 0).
signal fetched(count: int, player: Player)

## It hops this often (per second) while walking, this high (share of its size).
const HOP_SPEED: float = 3.2
const HOP_HEIGHT: float = 0.35
## It walks at least this much faster than its hero, so it never falls behind for good.
const CATCH_UP: float = 1.2

var plushie: PlushieDef
var rules: RescueRules
## Buttons this close to it (pixels) fly to its hero (Plushie Buddy's number).
var reach: float = 0.0
var pickups: PickupManager
## True while it walks (it hops), false while it waits next to its hero.
var walking: bool = false
## The baked look (`PlushiePicture`: rendered once) and the sprite that shows it and hops.
var look: PlushiePicture
var picture: SubViewport
var sprite: Sprite2D

var _hop_time: float = 0.0


func setup(who: PlushieDef, rescue_rules: RescueRules, fetch_reach: float) -> void:
	plushie = who.calmed()
	rules = rescue_rules
	reach = fetch_reach


func _ready() -> void:
	look = PlushiePicture.new()
	look.setup(plushie, rules.buddy_size, rules.buddy_halo)
	add_child(look)
	picture = look.picture
	sprite = look.sprite


## The hero it follows: player 1, or the nearest hero still standing if player 1 is down.
func hero() -> Player:
	var best: Player = null
	var best_distance: float = INF
	for player: Player in Players.all(get_tree()):
		if player.is_dead():
			continue
		if player.player_index == 0:
			return player
		var distance: float = player.global_position.distance_squared_to(global_position)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


## How high it is in its hop right now (pixels, 0 = on the floor).
func lift() -> float:
	return absf(sin(_hop_time * TAU * HOP_SPEED / 2.0)) * rules.buddy_size * HOP_HEIGHT


func _physics_process(delta: float) -> void:
	var leader: Player = hero()
	if leader == null:
		walking = false
		return
	var goal: Vector2 = leader.global_position
	var gap: float = global_position.distance_to(goal) - rules.buddy_follow_distance
	walking = gap > 0.0
	if walking:
		var speed: float = maxf(rules.buddy_speed, leader.move_speed() * CATCH_UP)
		global_position = global_position.move_toward(goal, minf(speed * delta, gap))
		_hop_time += delta
	else:
		_hop_time = 0.0
	sprite.position.y = -lift()
	if pickups != null:
		var count: int = pickups.attract_near(global_position, reach, leader)
		if count > 0:
			fetched.emit(count, leader)
