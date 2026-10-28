class_name Player
extends CharacterBody2D
## A hero controlled by one player: walks, dashes and takes contact damage.

signal health_changed(current: float, maximum: float)
signal hurt(amount: float)
signal dashed(from_position: Vector2, direction: Vector2)
signal died(player: Player)
## A level-up moment: Banane quacks with sunglasses on.
signal celebrated
## Weapons or items were added or levelled up (the HUD redraws its icons).
signal loadout_changed
## A weapon evolved (the gift box moment shows it).
signal evolved(weapon: Weapon)

const GROUP: StringName = &"players"
## Thick Felt never makes the hero take less than this share of a hit.
const MIN_DAMAGE_TAKEN: float = 0.2
## An evolved weapon counts as its old weapon past every level, so that is never offered again.
const EVOLVED_LEVEL: int = 99

@export var stats: HeroStats
@export var xp_rules: XpRules
## 0 = player 1. Decides which input actions this hero listens to.
@export var player_index: int = 0
## False in town: no starting weapon (nothing to fight there).
@export var armed: bool = true

var health: float = 0.0
var max_health: float = 0.0
## Last non-zero move direction; a dash while standing still goes this way.
var facing: Vector2 = Vector2.RIGHT
## Name of whatever hit the hero last (shown on the end screen later).
var last_hit_by: String = ""
## Developer menu: nothing can hurt the hero.
var invincible: bool = false
## Multiplies how fast all weapons attack (Quick Hands raises it).
var attack_speed: float = 1.0
## XP buttons closer than this fly to the hero (Magnet Pocket raises it).
var pickup_range: float = 0.0
## Level and XP in this run.
var progress: LevelProgress
## Multiplies the hero's move speed (Quick Feet raises it).
var move_speed_multiplier: float = 1.0
## Multiplies all weapon damage (Sharp Scissors raises it).
var damage_multiplier: float = 1.0
## Multiplies weapon reach and duration (Long Thread raises it).
var range_multiplier: float = 1.0
## Multiplies weapon areas and shot size (Big Spool raises it).
var area_multiplier: float = 1.0
## Multiplies damage the hero takes (Thick Felt lowers it).
var damage_taken_multiplier: float = 1.0
## Goes up whenever a weapon bonus changes, so weapons know to recompute their numbers.
var bonus_version: int = 0
## Items picked this run, in the order they were first picked.
var items: Array[UpgradeDef] = []
## Level of each item picked this run, by id (weapons keep their own level).
var item_levels: Dictionary[StringName, int] = {}
## The weapon this hero starts the run with (null = the hero's own; set before adding the hero).
var starting_weapon: WeaponStats
## The starting weapon's level (Head Start trick: 2) and more weapons to start with (Second Toy
## trick); set before adding the hero.
var starting_weapon_level: int = 1
var extra_weapons: Array[WeaponStats] = []
## Town bonuses for this run (Snack Bar health, Watchtower range as a share of the hero's
## own); set before adding the hero.
var bonus_max_health: float = 0.0
var bonus_pickup_share: float = 0.0
## Ids of the town's building tricks this hero has (spec 06; every hero gets all of them).
var tricks: PackedStringArray = []
## True once this hero's first level-up of the run is done (Show-and-Tell trick).
var first_level_up_done: bool = false
## Every card picked this run, in order, e.g. "Quick Feet 2" (for the end screen and run log).
var picked_upgrades: PackedStringArray = []
## Rerolls, skips and banishes left this run (the run sets it up when it spawns the player).
var card_controls: CardControls

var _controls: PlayerInput
var _dash_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_cooldown_left: float = 0.0
var _hurt_invulnerable_left: float = 0.0

@onready var _hitbox: CollisionShape2D = $Hitbox
@onready var _weapons: Node2D = $Weapons


func _ready() -> void:
	add_to_group(GROUP)
	_controls = PlayerInput.new(player_index)
	max_health = stats.max_health + bonus_max_health
	health = max_health
	pickup_range = stats.pickup_range * (1.0 + bonus_pickup_share)
	progress = LevelProgress.new(xp_rules)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = stats.hitbox_radius
	_hitbox.shape = shape
	if stats.slippery:
		var slippery: Slippery = Slippery.new()
		slippery.name = "Slippery"
		add_child(slippery)
		slippery.setup(self)
	if starting_weapon == null:
		starting_weapon = stats.starting_weapon
	if armed and starting_weapon != null:
		var first: Weapon = add_weapon(starting_weapon)
		first.level = clampi(starting_weapon_level, 1, starting_weapon.max_level())
	if armed:
		for extra: WeaponStats in extra_weapons:
			add_weapon(extra)


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_hurt_invulnerable_left = maxf(_hurt_invulnerable_left - delta, 0.0)
	if is_dead():
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = _controls.move_vector()
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	if not is_dashing() and _controls.is_just_pressed("dash"):
		try_dash()
	if is_dashing():
		_move_dash(delta)
	else:
		velocity = direction * move_speed()
		move_and_slide()


func _input(event: InputEvent) -> void:
	_controls.observe(event)


## Where this player aims (the mouse cursor for player 1, else straight ahead), in the world.
func aim_point() -> Vector2:
	return _controls.aim_point(get_viewport(), global_position + facing * 200.0)


## True in the frame this player pressed `action_name` (e.g. "interact" = E for player 1).
func just_pressed(action_name: String) -> bool:
	return _controls.is_just_pressed(action_name)


func move_speed() -> float:
	return stats.move_speed * move_speed_multiplier


## Plays the level-up moment on the puppet.
func celebrate() -> void:
	celebrated.emit()


## Adds collected XP. Returns how many levels were gained.
func add_xp(amount: int) -> int:
	return progress.add_xp(amount)


func heal(amount: float) -> void:
	if is_dead():
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


## Current level of every upgrade the hero has (weapons and items), for rolling cards.
func upgrade_levels() -> Dictionary[StringName, int]:
	var levels: Dictionary[StringName, int] = item_levels.duplicate()
	for owned: Weapon in weapons():
		levels[owned.stats.id] = owned.level
		if owned.stats.evolved_from != &"":
			levels[owned.stats.evolved_from] = EVOLVED_LEVEL
	return levels


## Applies a picked level-up card.
func apply_upgrade(offer: UpgradeOffer) -> void:
	var upgrade: UpgradeDef = offer.upgrade
	match upgrade.kind:
		UpgradeDef.Kind.WEAPON:
			var owned: Weapon = weapon(upgrade.weapon.id)
			if owned == null:
				add_weapon(upgrade.weapon)
			else:
				owned.level_up()
		UpgradeDef.Kind.ITEM:
			if not item_levels.has(upgrade.id):
				items.append(upgrade)
			item_levels[upgrade.id] = item_levels.get(upgrade.id, 0) + 1
			_apply_item(upgrade)
		UpgradeDef.Kind.SNACK:
			heal(max_health * upgrade.amount)
	picked_upgrades.append("%s %d" % [upgrade.display_name, offer.next_level])
	loadout_changed.emit()


## Gives this hero a weapon (level 1). It attacks on its own from now on.
func add_weapon(weapon_stats: WeaponStats) -> Weapon:
	var weapon: Weapon = weapon_stats.behaviour.new() as Weapon
	weapon.setup(weapon_stats, self)
	_weapons.add_child(weapon)
	loadout_changed.emit()
	return weapon


## Replaces the weapon of `evolution` by its evolved form, in the same HUD slot. Returns the
## new weapon, or null if the hero doesn't have the old one.
func evolve(evolution: EvolutionDef) -> Weapon:
	var old: Weapon = weapon(evolution.weapon)
	if old == null:
		return null
	var slot: int = old.get_index()
	_weapons.remove_child(old)
	old.queue_free()
	var new_weapon: Weapon = add_weapon(evolution.evolved)
	_weapons.move_child(new_weapon, slot)
	picked_upgrades.append("Evolved: %s" % evolution.display_name())
	RecipeBook.mark_seen(evolution.evolved.id)
	loadout_changed.emit()
	evolved.emit(new_weapon)
	return new_weapon


## The weapon with this id, or null if the hero doesn't have it.
func weapon(id: StringName) -> Weapon:
	return _weapons.get_node_or_null(NodePath(String(id))) as Weapon


func weapons() -> Array[Weapon]:
	var result: Array[Weapon] = []
	for child: Node in _weapons.get_children():
		result.append(child as Weapon)
	return result


## Starts a dash in the facing direction. Returns false while the dash is cooling down.
func try_dash() -> bool:
	if not can_dash():
		return false
	_dash_left = stats.dash_distance
	_dash_direction = facing
	_dash_cooldown_left = stats.dash_cooldown
	dashed.emit(global_position, _dash_direction)
	return true


func can_dash() -> bool:
	return not is_dead() and not is_dashing() and _dash_cooldown_left <= 0.0


func is_dashing() -> bool:
	return _dash_left > 0.0


## 0 right after a dash, 1 when the next dash is ready.
func dash_ready_ratio() -> float:
	if stats.dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - _dash_cooldown_left / stats.dash_cooldown


func is_invulnerable() -> bool:
	return is_dashing() or _hurt_invulnerable_left > 0.0


## Seconds of after-hit invulnerability left (0 when Banane can be hurt again).
func hurt_invulnerable_left() -> float:
	return _hurt_invulnerable_left


func is_dead() -> bool:
	return health <= 0.0


## True if this hero has the building trick `id` (spec 06).
func has_trick(id: StringName) -> bool:
	return tricks.has(String(id))


## Damage from a zombie or a bullet (Thick Felt makes it smaller). Ignored while dashing or right
## after another hit. Returns true if it hurt.
func take_hit(amount: float, source: String) -> bool:
	if is_dead() or is_invulnerable() or invincible:
		return false
	amount *= damage_taken_multiplier
	health = maxf(health - amount, 0.0)
	last_hit_by = source
	_hurt_invulnerable_left = stats.hurt_invulnerability
	hurt.emit(amount)
	health_changed.emit(health, max_health)
	if is_dead():
		died.emit(self)
	return true


func _apply_item(upgrade: UpgradeDef) -> void:
	match upgrade.effect:
		UpgradeDef.Effect.MOVE_SPEED:
			move_speed_multiplier += upgrade.amount
		UpgradeDef.Effect.MAX_HEALTH:
			max_health += upgrade.amount
			heal(upgrade.amount)
		UpgradeDef.Effect.PICKUP_RANGE:
			pickup_range += stats.pickup_range * upgrade.amount
		UpgradeDef.Effect.ATTACK_SPEED:
			attack_speed += upgrade.amount
		UpgradeDef.Effect.DAMAGE:
			damage_multiplier += upgrade.amount
		UpgradeDef.Effect.DURATION_AND_RANGE:
			range_multiplier += upgrade.amount
		UpgradeDef.Effect.AREA:
			area_multiplier += upgrade.amount
		UpgradeDef.Effect.DAMAGE_TAKEN:
			damage_taken_multiplier = maxf(
				damage_taken_multiplier - upgrade.amount, MIN_DAMAGE_TAKEN
			)
	bonus_version += 1


func _move_dash(delta: float) -> void:
	var dash_speed: float = stats.dash_distance / maxf(stats.dash_duration, 0.001)
	var step: float = minf(dash_speed * delta, _dash_left)
	_dash_left -= step
	velocity = _dash_direction * (step / delta)
	move_and_slide()
	if is_on_wall():
		_dash_left = 0.0
	if not is_dashing():
		velocity = Vector2.ZERO
