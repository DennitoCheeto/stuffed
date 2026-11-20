class_name RunPatterns
extends RefCounted
## Sewing patterns in a run (spec 09 §4, AC-96): the first Big Ted / Sock Puppet King kill drops
## its pattern envelope where it fell, elites drop the Raincoat pattern at its data chance, until
## the town owns them. Touching an envelope puts the pattern into the run's haul (kept whole even
## from a lost run) and saves at once. A run's helper (run.gd is near gdlint's line limit).

var run: Run
var rules: GearRules
## Separate randomness for elite drops, so they don't change the zombies or the cards.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## False in the night siege: patterns only drop on expeditions.
var enabled: bool = true
## Envelopes lying on the floor, by gear id (one per pattern at most).
var envelopes: Dictionary[String, PatternEnvelope] = {}
## For the run log (`patterns_found`): {"pattern": gear id, "time": run seconds}.
var found: Array[Dictionary] = []


func _init(owner_run: Run, gear_rules: GearRules = GearRules.current()) -> void:
	run = owner_run
	rules = gear_rules


## Seeds the gear dice from the run's seed: elite pattern drops and the Lucky Button's golden
## buttons (`run.pickups.golden_rng`), so a seed plays out the same.
func seed_dice(seed_value: int) -> void:
	rng.seed = seed_value * 29 + 17
	if run.pickups != null:
		run.pickups.golden_rng.seed = seed_value * 37 + 19


## True while `piece` can still drop: the town doesn't own it, this run didn't find it and no
## envelope with it is lying on the floor.
func can_drop(piece: GearDef) -> bool:
	var id: String = String(piece.id)
	if run.perks.patterns.has(id) or run.haul.patterns.has(id):
		return false
	return not (envelopes.has(id) and is_instance_valid(envelopes[id]))


## A zombie died: a boss drops its pattern, an elite may drop the elite pattern(s).
func zombie_killed(zombie: Zombie) -> void:
	if not enabled:
		return
	if zombie.is_boss():
		var boss_id: String = zombie.boss.resource_path.get_file().get_basename()
		for piece: GearDef in rules.pieces_from(GearDef.Source.BOSS, boss_id):
			if can_drop(piece):
				drop(piece, zombie.position + rules.envelope_offset)
	elif zombie.is_elite():
		for piece: GearDef in rules.pieces_from(GearDef.Source.ELITE):
			if can_drop(piece) and rng.randf() < piece.drop_chance:
				drop(piece, zombie.position + rules.envelope_offset)


## Puts `piece`'s pattern envelope on the floor near `at` (inside the room, off the furniture).
func drop(piece: GearDef, at: Vector2) -> PatternEnvelope:
	var envelope: PatternEnvelope = PatternEnvelope.new()
	envelope.setup(piece, rules.envelope_touch_radius)
	var area: Rect2 = run.arena.play_rect().grow(-rules.envelope_touch_radius)
	var spot: Vector2 = at.clamp(area.position, area.end)
	envelope.position = run.enemies.obstacles.push_out(spot, rules.envelope_touch_radius)
	envelope.touched.connect(_on_touched)
	run.floor_items.add_child(envelope)
	envelopes[String(piece.id)] = envelope
	return envelope


## The next pattern a boss or elite could still drop (developer menu), or null.
func next_drop() -> GearDef:
	for kind: GearDef.Source in [GearDef.Source.BOSS, GearDef.Source.ELITE]:
		for piece: GearDef in rules.pieces_from(kind):
			if can_drop(piece):
				return piece
	return null


func _on_touched(envelope: PatternEnvelope, _player: Player) -> void:
	var id: String = String(envelope.piece.id)
	envelopes.erase(id)
	if run.haul.patterns.has(id):
		return
	run.haul.patterns.append(id)
	found.append({"pattern": id, "time": run.elapsed})
	var one: Array[GearDef] = [envelope.piece]
	var news: PackedStringArray = rules.pattern_news(one)
	run.hud.show_banner(news[0], news[1], rules.pattern_banner_seconds, PatternEnvelope.GLOW_COLOR)
	Sfx.play(rules.pattern_sound)
	# Saved right away: closing the game now still brings it home.
	run.checkpoint_due.emit()


## Puts this run's gear facts into `result` (spec 09 §10): the patterns found and what every
## player wore (end screen tags, log `gear`). Here because run.gd is at gdlint's line limit.
func fill_result(result: RunResult) -> void:
	result.patterns_found = found.duplicate(true)
	for player: Player in Players.all(run.get_tree()):
		result.gear.append_array(player.gear.to_list(player.player_index))
