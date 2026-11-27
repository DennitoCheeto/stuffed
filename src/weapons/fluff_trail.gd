class_name FluffTrail
extends Node2D
## The fluff puffs one Comfy Cloud leaves behind its walking hero (spec 11 §4.3), and the mend:
## each zombie the weapon pops heals its own hero (`ComfyFluff.mend_per_kill`, capped per second).
## Puffs are a few pooled sprites of one felt part (they batch into one draw call); the mend
## sparkles are drawn by this node. Under the zombies, on the own-shots layer.

const NAME: StringName = &"FluffTrail"

## The Comfy Cloud whose trail this is (its numbers, its hero, its tally row).
var weapon: Weapon
## Zombie hits from puffs so far, puffs dropped, and health mended (for tests).
var hits: int = 0
var dropped: int = 0
var mended: float = 0.0

## One entry per puff on the floor, oldest first.
var _spots: PackedVector2Array = []
var _ages: PackedFloat32Array = []
var _sprites: Array[Sprite2D] = []
var _walked: float = 0.0
var _last_at: Vector2 = Vector2.INF
var _mend_left: float = -1.0
var _manager: EnemyManager
## Mend sparkles: seconds since each one started.
var _sparkles: PackedFloat32Array = []
var _drawn_sparkles: bool = false


func _init() -> void:
	name = NAME
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


func count() -> int:
	return _spots.size()


## Where the puffs are, oldest first (for tests).
func spots() -> PackedVector2Array:
	return _spots.duplicate()


## Drops a puff at `at` (the oldest one goes when there are too many).
func drop(at: Vector2) -> void:
	var fluff: ComfyFluff = _fluff()
	if fluff == null:
		return
	_spots.append(at)
	_ages.append(0.0)
	dropped += 1
	while _spots.size() > fluff.max_puffs:
		_spots.remove_at(0)
		_ages.remove_at(0)
	_show_puffs(fluff)


## Hurts every zombie inside any puff once (called on the cloud's beat).
func hurt_all() -> void:
	var fluff: ComfyFluff = _fluff()
	var manager: EnemyManager = weapon.enemies() if weapon != null else null
	if fluff == null or manager == null or _spots.is_empty():
		return
	var damage: float = fluff.puff_damage * weapon.damage_scale()
	var done: Dictionary[int, bool] = {}
	for at: Vector2 in _spots:
		for zombie: Zombie in manager.query_circle(at, fluff.puff_radius):
			var id: int = zombie.get_instance_id()
			if zombie.dead or done.has(id):
				continue
			done[id] = true
			hits += 1
			manager.damage(zombie, damage, Vector2.ZERO, weapon)


func _fluff() -> ComfyFluff:
	return weapon.stats.comfy_fluff if weapon != null and weapon.stats != null else null


func _physics_process(delta: float) -> void:
	var fluff: ComfyFluff = _fluff()
	if fluff == null or weapon.player == null:
		return
	_listen()
	if _mend_left < 0.0:
		_mend_left = fluff.mend_per_second
	_mend_left = minf(_mend_left + fluff.mend_per_second * delta, fluff.mend_per_second)
	for i: int in range(_spots.size() - 1, -1, -1):
		_ages[i] += delta
		if _ages[i] >= fluff.puff_seconds:
			_spots.remove_at(i)
			_ages.remove_at(i)
	_walk(fluff, delta)
	_show_puffs(fluff)


## Counts the time the hero walks and drops a puff where they are every `drop_every` seconds.
func _walk(fluff: ComfyFluff, delta: float) -> void:
	var at: Vector2 = weapon.player.global_position
	var moved: float = 0.0 if _last_at == Vector2.INF else at.distance_to(_last_at)
	_last_at = at
	if delta <= 0.0 or moved / delta < fluff.walk_speed or weapon.player.is_dead():
		return
	_walked += delta
	if _walked >= fluff.drop_every:
		_walked -= fluff.drop_every
		drop(at)


## Hears the weapon's kills (the run's enemies may not exist yet when the weapon is made).
func _listen() -> void:
	if _manager != null:
		return
	_manager = weapon.enemies()
	if _manager != null:
		_manager.killed_by.connect(_on_killed)


func _on_killed(by: Weapon, _zombie: Zombie) -> void:
	var fluff: ComfyFluff = _fluff()
	if by != weapon or fluff == null or weapon.player.is_dead():
		return
	if _mend_left < fluff.mend_per_kill:
		return
	_mend_left -= fluff.mend_per_kill
	mended += fluff.mend_per_kill
	weapon.player.heal(fluff.mend_per_kill)
	_sparkles.append(0.0)


func _show_puffs(fluff: ComfyFluff) -> void:
	while _sprites.size() < _spots.size():
		var sprite: Sprite2D = Sprite2D.new()
		ProjectileLook.apply(sprite, ProjectileLook.COMFY_PUFF)
		sprite.set_meta(&"base", sprite.scale)
		add_child(sprite)
		_sprites.append(sprite)
	var size: float = fluff.puff_radius / ProjectileLook.CLOUD_RADIUS
	for i: int in _sprites.size():
		var sprite: Sprite2D = _sprites[i]
		sprite.visible = i < _spots.size()
		if not sprite.visible:
			continue
		var age: float = _ages[i]
		var grow: float = lerpf(fluff.grow_from, 1.0, minf(age / fluff.grow_seconds, 1.0))
		var left: float = fluff.puff_seconds - age
		var fade: float = clampf(left / maxf(fluff.fade_seconds, 0.001), 0.0, 1.0)
		sprite.position = _spots[i]
		sprite.scale = (sprite.get_meta(&"base") as Vector2) * size * grow
		sprite.self_modulate.a = fluff.puff_opacity * fade


func _process(delta: float) -> void:
	modulate.a = GameSettings.own_effects
	var fluff: ComfyFluff = _fluff()
	if fluff == null or (_sparkles.is_empty() and not _drawn_sparkles):
		return
	for i: int in range(_sparkles.size() - 1, -1, -1):
		_sparkles[i] += delta
		if _sparkles[i] >= fluff.mend_seconds:
			_sparkles.remove_at(i)
	_drawn_sparkles = not _sparkles.is_empty()
	queue_redraw()


## Mend sparkles: little stitch crosses floating up from the hero and fading.
func _draw() -> void:
	var fluff: ComfyFluff = _fluff()
	if fluff == null or _sparkles.is_empty() or weapon.player == null:
		return
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []
	var hero: Vector2 = weapon.player.global_position
	for i: int in _sparkles.size():
		var share: float = _sparkles[i] / fluff.mend_seconds
		var side: float = -14.0 if i % 2 == 0 else 14.0
		var at: Vector2 = hero + Vector2(side, -20.0 - fluff.mend_rise * share)
		var color: Color = fluff.mend_color
		color.a *= 1.0 - share
		var arm: float = fluff.mend_size
		points.append_array([at + Vector2(-arm, 0), at + Vector2(arm, 0)])
		points.append_array([at + Vector2(0, -arm), at + Vector2(0, arm)])
		colors.append_array([color, color])
	draw_multiline_colors(points, colors, 2.0)
