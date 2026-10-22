class_name Zombie
extends Node2D
## One zombie plushie: its health, how it reacts to hits and how it looks. The EnemyManager moves
## all zombies together (that is much faster than each zombie moving itself).

const KNOCKBACK_DECAY: float = 8.0

var stats: EnemyStats
## Set for elites (bigger, tougher, own attack, drops a gift box); null for normal zombies.
var elite: EliteRules
## Set for the mini-boss and the boss (own patterns, health bar, drops a gift box).
var boss: BossDef
## The boss's patterns (bosses only).
var brain: BossBrain
## Shown on the end screen as what hit Banane (e.g. "Elite Shambler").
var display_name: String = ""
## Its ranged attack (a spitter's spit or an elite's ring); null = it only hurts by touching.
var attack: SpitAttack
## Bigger for elites (body radius and drawing).
var size: float = 1.0
var health: float = 0.0
var max_health: float = 0.0
var contact_damage: float = 0.0
var move_speed: float = 0.0
## Extra push from hits, fades out quickly.
var knockback: Vector2 = Vector2.ZERO
## Direction it is walking (zero when standing).
var heading: Vector2 = Vector2.ZERO
## Which way round it walks the furniture in its way (1 or -1; 0 = nothing in the way).
var detour: int = 0
## Seconds it can't move (banana peel).
var stun_left: float = 0.0
## Sticky yarn (Yarn Bomb): seconds it stays slowed, and by how much (0.5 = half speed).
var slow_left: float = 0.0
var slow_amount: float = 0.0
var dead: bool = false
var puppet: ZombiePuppet
## Ranged zombies (`attack`): seconds left in the wind-up, while it puffs up; below 0 = not
## winding up.
var windup_left: float = -1.0
## Seconds until it may start its next wind-up.
var attack_cooldown: float = 0.0
## Volleys spat so far (picks the next one from the attack pattern).
var volleys: int = 0
## Damage of one of its stuffing balls (endless mode scales it like touching).
var spit_damage: float = 0.0
## Frozen by a Snow Globe: it stands still in its pose with an icy tint (set by the manager).
var frozen: bool = false
## 0..1 while frozen: how hard it shakes because the ice is cracking (the freeze ends soon).
var thaw_shake: float = 0.0

var _time: float = 0.0
var _since_hit: float = INF
var _stars: StunStars


## `phase` (0..1) keeps zombies from shambling in perfect sync. `elite_rules` makes it an elite,
## `boss_def` a boss (its body is `boss_def.enemy`, `enemy_stats` is ignored).
func setup(
	enemy_stats: EnemyStats,
	health_scale: float,
	damage_scale: float,
	phase: float,
	elite_rules: EliteRules = null,
	boss_def: BossDef = null
) -> void:
	stats = boss_def.enemy if boss_def != null else enemy_stats
	elite = elite_rules
	boss = boss_def
	display_name = stats.display_name
	attack = stats.attack
	max_health = stats.max_health * health_scale
	contact_damage = stats.contact_damage * damage_scale
	move_speed = stats.move_speed
	if elite != null:
		display_name = elite.name_prefix + display_name
		attack = elite.attack
		size = elite.size
		max_health *= elite.health_multiplier
		contact_damage *= elite.contact_damage_multiplier
		move_speed *= elite.move_speed_multiplier
	if boss != null:
		size = boss.size
		brain = boss.make_brain()
		brain.telegraph = BossTelegraph.new()
		add_child(brain.telegraph)
	health = max_health
	if attack != null:
		attack_cooldown = attack.first_delay_seconds
		spit_damage = attack.bullet_damage * damage_scale
	puppet = ZombiePuppet.new()
	add_child(puppet)
	puppet.build(ZombieLook.for_look(stats.look), phase, size)
	if elite != null:
		puppet.add_elite_marks()


## Takes damage and a push. Returns true if this hit killed it.
func take_damage(amount: float, push: Vector2) -> bool:
	if dead:
		return false
	health -= amount
	knockback += push * knockback_taken()
	_since_hit = 0.0
	if health <= 0.0:
		dead = true
	return dead


func radius() -> float:
	return stats.radius * size


## 1 = normal knockback, 0 = can't be pushed.
func knockback_taken() -> float:
	var taken: float = stats.knockback_taken
	return taken * elite.knockback_multiplier if elite != null else taken


func is_elite() -> bool:
	return elite != null


func is_boss() -> bool:
	return boss != null


## Which XP button it drops when killed.
func xp_button() -> EnemyStats.XpSize:
	return elite.xp_button if elite != null else stats.xp_button


## Can't move for `seconds` (slipped on a banana peel): it spins and sees stars.
func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)
	if _stars == null:
		_stars = StunStars.new()
		_stars.position = Vector2(0.0, -48.0)
		add_child(_stars)
	_stars.visible = true


## Moves `amount` slower (0.5 = half speed) for `seconds`; the strongest slow wins.
func slow(amount: float, seconds: float) -> void:
	slow_amount = maxf(slow_amount, clampf(amount, 0.0, 1.0))
	slow_left = maxf(slow_left, seconds)


## Walking speed right now (slowed by sticky yarn).
func current_speed() -> float:
	return move_speed * (1.0 - slow_amount)


func is_stunned() -> bool:
	return stun_left > 0.0


func is_winding_up() -> bool:
	return windup_left >= 0.0


## How far the wind-up is: 0 = not puffed up, 1 = about to spit.
func windup_progress() -> float:
	if not is_winding_up() or attack == null:
		return 0.0
	return clampf(1.0 - windup_left / maxf(attack.windup_seconds, 0.001), 0.0, 1.0)


## Advances its timers and animation by one frame.
func tick(delta: float) -> void:
	if not frozen:
		_time += delta
	_since_hit += delta
	puppet.chill(frozen, thaw_shake)
	stun_left = maxf(stun_left - delta, 0.0)
	slow_left = maxf(slow_left - delta, 0.0)
	if slow_left <= 0.0:
		slow_amount = 0.0
	knockback = knockback.lerp(Vector2.ZERO, minf(KNOCKBACK_DECAY * delta, 1.0))
	puppet.animate(_time, heading != Vector2.ZERO, _since_hit, heading.x < 0.0)
	if brain != null:
		puppet.puff(brain.puff_amount())
	elif attack != null:
		puppet.puff(windup_progress())
	if _stars != null:
		_stars.visible = is_stunned()
		puppet.spin(stun_left)
