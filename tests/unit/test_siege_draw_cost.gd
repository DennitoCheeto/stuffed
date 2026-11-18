extends GutTest
## The siege stays cheap to draw (spec 07 §11): a building ring's stitches go out in one line
## list, and the building bars share one layer above the town and the zombies, under the enemy
## bullets (danger stays on top).

const RADIUS: float = 230.0


func test_a_ring_draws_all_its_stitches_as_one_line_list() -> void:
	var lines: PackedVector2Array = SiegeRing.stitch_lines(RADIUS)
	assert_eq(lines.size(), SiegeRing.STITCHES * SiegeRing.STITCH_BENDS * 2, "line pairs")
	for point: Vector2 in lines:
		assert_almost_eq(point.length(), RADIUS, 0.01, "on the ring")


func test_building_bars_share_a_layer_under_the_enemy_bullets() -> void:
	var target: SiegeTarget = SiegeTarget.new(Rect2(0, 0, 100, 100), 50.0, 1.0)
	var bar: BuildingHealthBar = BuildingHealthBar.new(target, Vector2(50, 0))
	autofree(bar)
	assert_gt(bar.z_index, 0, "above the town and the zombies")
	assert_lt(bar.z_index, ProjectileManager.HOSTILE_Z, "under the enemy bullets")
