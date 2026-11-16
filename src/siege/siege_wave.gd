class_name SiegeWave
extends Resource
## One wave of the night siege (spec 07 §5): which zombie types come and how often, how many
## elites and whether the night's boss comes. Tune it in data/siege/siege_rules.tres.

## Zombies per second while the wave spawns (the first siege; later ones bring more).
@export var rate: float = 1.0
## The zombie types of this wave ...
@export var enemies: Array[EnemyStats] = []
## ... and how often each comes (same order, any scale).
@export var weights: PackedFloat32Array = []
## Elites in this wave (their types picked like the others), spread evenly over the wave.
@export var elites: int = 0
## The night's boss (null = none) and how many seconds into the wave he comes.
@export var boss: BossDef
@export var boss_at: float = 10.0


## A random zombie type of this wave, by its weight.
func pick(rng: RandomNumberGenerator) -> EnemyStats:
	if enemies.is_empty():
		return null
	var total: float = 0.0
	for i: int in enemies.size():
		total += _weight(i)
	var roll: float = rng.randf() * total
	for i: int in enemies.size():
		roll -= _weight(i)
		if roll < 0.0:
			return enemies[i]
	return enemies[enemies.size() - 1]


## Seconds into the wave when elite `index` (0 = the first) comes.
func elite_at(index: int, wave_seconds: float) -> float:
	return wave_seconds * (index + 1) / float(elites + 1)


func _weight(index: int) -> float:
	return weights[index] if index < weights.size() else 1.0
