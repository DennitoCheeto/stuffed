class_name BearHug
extends Node
## Böbö's passive (spec 08 §3, AC-88): his dash is a shoulder charge. Every zombie it touches is
## shoved away from his path and takes a little damage, once per dash. (He also takes less damage
## from everything: `HeroStats.damage_taken`.) Numbers in the hero's .tres ("Bear Hug").

var player: Player
## Zombies shoved by the current dash (each only once).
var shoved: Array[Zombie] = []
## How many zombies the charges shoved in this run (tests).
var shoves: int = 0


func setup(owner_player: Player) -> void:
	player = owner_player
	player.dashed.connect(_on_dashed)


func _on_dashed(_from_position: Vector2, _direction: Vector2) -> void:
	shoved.clear()


func _physics_process(_delta: float) -> void:
	if not player.armed or not player.is_dashing():
		return
	var manager: EnemyManager = get_tree().get_first_node_in_group(EnemyManager.GROUP)
	if manager == null:
		return
	var stats: HeroStats = player.stats
	var at: Vector2 = player.global_position
	for zombie: Zombie in manager.query_circle(at, stats.bear_hug_reach):
		if zombie.dead or shoved.has(zombie):
			continue
		shoved.append(zombie)
		shoves += 1
		var away: Vector2 = at.direction_to(zombie.position)
		if away == Vector2.ZERO:
			away = player.facing
		manager.damage_from(
			WeaponTally.BEAR_HUG, zombie, stats.bear_hug_damage, away * stats.bear_hug_shove
		)
