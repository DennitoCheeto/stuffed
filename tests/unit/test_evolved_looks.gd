extends GutTest
## Evolved weapons' own shot looks (spec 02 §20, AC-30): every evolved weapon has a ShotLook with
## its own felt part, bigger shots, a glitter trail and a hit flash; base weapons have none; all
## colours stay soft and away from enemy red/orange (hard rule 9).

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
## Hues (degrees) that belong to enemy danger: red, orange and red-pink.
const DANGER_HUES: Vector2 = Vector2(330.0, 50.0)
## Below this saturation a colour is a pale tint, not a danger colour.
const PALE: float = 0.3


func _is_danger_colour(color: Color) -> bool:
	var hue: float = color.h * 360.0
	var reddish: bool = hue >= DANGER_HUES.x or hue <= DANGER_HUES.y
	return reddish and color.s >= PALE


func test_ac30_every_evolved_weapon_has_its_own_shot_look() -> void:
	var parts: Dictionary[StringName, FeltPiece] = ProjectileLook.make_parts()
	var used_parts: Array[StringName] = []
	for evolution: EvolutionDef in POOL.evolutions:
		var stats: WeaponStats = evolution.evolved
		var look: ShotLook = stats.shot_look
		assert_not_null(look, "%s has a shot look" % stats.id)
		if look == null:
			continue
		assert_true(parts.has(look.part), "%s: its part is a real felt part" % stats.id)
		assert_does_not_have(used_parts, look.part, "%s: a part of its own" % stats.id)
		used_parts.append(look.part)
		assert_gt(look.size, 1.0, "%s: bigger shots" % stats.id)
		assert_gt(look.trail_amount, 0, "%s: a glitter trail" % stats.id)
		assert_gt(look.trail_seconds, 0.0)
		assert_gt(look.flash_radius, 0.0, "%s: a hit flash" % stats.id)
		assert_gt(look.flash_seconds, 0.0)
	for piece: FeltPiece in parts.values():
		piece.free()


func test_ac30_base_weapons_keep_their_normal_look() -> void:
	for evolution: EvolutionDef in POOL.evolutions:
		var base: UpgradeDef = POOL.find(evolution.weapon)
		assert_null(base.weapon.shot_look, "%s has no evolved look" % base.id)


func test_ac30_evolved_looks_stay_quieter_than_enemy_danger() -> void:
	var shot_colours: Array[Color] = [
		ProjectileLook.SPLIT_PEEL_COLOR,
		ProjectileLook.VOLLEY_SHAFT_COLOR,
		ProjectileLook.VOLLEY_HEAD_COLOR,
		ProjectileLook.STORM_NEEDLE_COLOR,
		ProjectileLook.STORM_EYE_COLOR,
		ProjectileLook.BOMB_COLOR,
		ProjectileLook.BOMB_STRAND_COLOR,
	]
	for colour: Color in shot_colours:
		assert_false(_is_danger_colour(colour), "shot colour %s is not red/orange" % colour)
	assert_true(_is_danger_colour(ProjectileLook.BULLET_COLOR), "the check does catch bullets")
	for evolution: EvolutionDef in POOL.evolutions:
		var look: ShotLook = evolution.evolved.shot_look
		if look == null:
			continue
		for colour: Color in [look.trail_color, look.flash_color]:
			assert_false(_is_danger_colour(colour), "%s: not red/orange" % evolution.evolved.id)
			assert_lt(colour.a, 0.7, "%s: see-through, enemy bullets read first" % look.part)
