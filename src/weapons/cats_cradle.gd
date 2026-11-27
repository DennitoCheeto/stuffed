class_name CatsCradle
extends BouncyYarnBall
## Evolved Bouncy Yarn Ball (+ Magnet Pocket, spec 11 §4.1): more balls that bounce further, and
## every ball unwinds: each bounce stretches a yarn thread that hurts the zombies touching it
## (`threads`). The balls also snag XP buttons and send them to the hero.

var threads: CradleThreads


func _ready() -> void:
	threads = CradleThreads.new()
	threads.weapon = self
	add_child(threads)


func _ball_kind() -> GDScript:
	return CradleProjectile
