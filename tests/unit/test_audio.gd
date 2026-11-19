extends GutTest

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const WEAPONS_DIR: String = "res://data/weapons/"
const ROSTER: HeroRoster = preload("res://data/heroes/hero_roster.tres")
## Sounds that warn of enemy danger: always louder than the player's own weapons (vision §6).
const DANGER: Array[StringName] = [&"puff", &"spit", &"burst", &"elite", &"stomp", &"boss_banner"]


func _peak(wav: AudioStreamWAV) -> int:
	var peak: int = 0
	for i: int in range(0, wav.data.size() - 1, 2):
		peak = maxi(peak, absi(wav.data.decode_s16(i)))
	return peak


func test_every_sound_is_made_in_code_and_not_silent() -> void:
	for sound: StringName in SfxBank.LENGTHS:
		var wav: AudioStreamWAV = SfxBank.make(sound)
		var seconds: float = wav.data.size() / 2.0 / wav.mix_rate
		assert_almost_eq(seconds, SfxBank.LENGTHS[sound], 0.01, "%s length" % sound)
		assert_gt(_peak(wav), 2000, "%s is audible" % sound)
		assert_lt(_peak(wav), 32001, "%s does not clip" % sound)


func test_the_spec_sound_list_is_covered() -> void:
	var needed: Array[StringName] = [&"throw", &"pin", &"hit", &"pop", &"pickup", &"dash", &"slip"]
	needed.append_array([&"hurt", &"quack", &"death", &"goal"])
	for sound: StringName in needed:
		assert_true(SfxBank.LENGTHS.has(sound), String(sound))


func test_sweep_reaches_the_target_pitch() -> void:
	var step: float = 0.001
	var step_end: float = Synth.sweep(1.0 + step, 200.0, 800.0, 0.5)
	var late: float = step_end - Synth.sweep(1.0, 200.0, 800.0, 0.5)
	assert_almost_eq(late / step, 800.0, 1.0, "after the sweep it holds the end pitch")


## Average loudness (root mean square of the samples).
func _loudness(sound: StringName) -> float:
	var wav: AudioStreamWAV = SfxBank.make(sound)
	var energy: float = 0.0
	for i: int in range(0, wav.data.size() - 1, 2):
		var value: float = wav.data.decode_s16(i)
		energy += value * value
	return sqrt(energy / (wav.data.size() / 2.0))


func _weapons() -> Array[WeaponStats]:
	var result: Array[WeaponStats] = []
	for file: String in DirAccess.get_files_at(WEAPONS_DIR):
		if file.ends_with(".tres"):
			result.append(load(WEAPONS_DIR + file) as WeaponStats)
	return result


func test_spec_02_sound_list_is_covered() -> void:
	var needed: Array[StringName] = [&"puff", &"spit", &"burst", &"elite", &"gift_open"]
	needed.append_array([&"evolution", &"boss_banner", &"boss_hit", &"boss_down"])
	for sound: StringName in needed:
		assert_true(SfxBank.LENGTHS.has(sound), String(sound))


func test_every_weapon_has_its_own_sound() -> void:
	var owners: Dictionary[StringName, StringName] = {}
	for stats: WeaponStats in _weapons():
		assert_true(SfxBank.LENGTHS.has(stats.sound), "%s has a sound" % stats.id)
		assert_false(owners.has(stats.sound), "%s shares %s" % [stats.id, stats.sound])
		owners[stats.sound] = stats.id
	assert_eq(owners.size(), _weapons().size())


func test_weapons_are_quieter_than_enemy_danger() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	for stats: WeaponStats in _weapons():
		var loudness: float = _loudness(stats.sound)
		assert_lt(loudness, quietest_danger, "%s is softer than danger" % stats.id)


func test_evolved_weapons_sound_fuller_than_before() -> void:
	for evolution: EvolutionDef in POOL.evolutions:
		var base: WeaponStats = POOL.find(evolution.weapon).weapon
		var evolved: WeaponStats = evolution.evolved
		assert_gt(_loudness(evolved.sound), _loudness(base.sound), "%s" % evolved.id)


func test_an_evolution_is_bigger_than_a_gift_box() -> void:
	assert_gt(_loudness(&"evolution"), _loudness(&"gift_open"), "louder")
	assert_gt(SfxBank.LENGTHS[&"evolution"], SfxBank.LENGTHS[&"gift_open"], "longer")


## Spec 03 §11: everything in town and on the jars is soft, never close to enemy danger.
func test_town_sounds_are_softer_than_enemy_danger() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	var town: Array[StringName] = [&"rebuild", &"upgrade", &"new_building", &"nope", &"coin"]
	town.append_array([&"page", &"hello", &"rescued", &"way_home"])
	for sound: StringName in town:
		assert_true(SfxBank.LENGTHS.has(sound), "%s exists" % sound)
		assert_lt(_loudness(sound), quietest_danger, "%s is softer than danger" % sound)


## Spec 03 §11: coins landing in the jars are quieter than XP and much quieter than danger.
func test_jar_coins_are_quieter_than_xp() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	assert_lt(_loudness(&"coin"), _loudness(&"pickup"), "quieter than an XP plip")
	assert_lt(_loudness(&"coin"), quietest_danger * 0.5, "much quieter than danger")


## Spec 04 §7: the menu sounds exist and stay soft, never close to enemy danger.
func test_menu_sounds_are_softer_than_enemy_danger() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	var menu: Array[StringName] = [&"ui_hover", &"ui_press", &"ui_nope", &"ui_open", &"sticker"]
	menu.append(&"star")
	for sound: StringName in menu:
		assert_true(SfxBank.LENGTHS.has(sound), "%s exists" % sound)
		assert_lt(_loudness(sound), quietest_danger, "%s is softer than danger" % sound)
	assert_lt(_loudness(&"ui_hover"), _loudness(&"ui_press"), "hover is the softest touch")


## Spec 06 §7: the trick sounds (Magnet Whistle, Spare Stuffing) stay softer than enemy danger.
func test_trick_sounds_are_softer_than_enemy_danger() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	for sound: StringName in [RunTricks.WHISTLE_SOUND, RunTricks.SPARE_SOUND]:
		assert_lt(_loudness(sound), quietest_danger, "%s is softer than danger" % sound)


## Spec 10 §4.2: every hero has their own level-up voice, softer than enemy danger.
func test_every_hero_has_their_own_level_up_voice() -> void:
	var quietest_danger: float = INF
	for sound: StringName in DANGER:
		quietest_danger = minf(quietest_danger, _loudness(sound))
	var voices: Dictionary[StringName, StringName] = {}
	for hero: HeroStats in ROSTER.heroes:
		var voice: StringName = hero.level_up_sound
		assert_true(SfxBank.LENGTHS.has(voice), "%s has a voice" % hero.id)
		assert_false(voices.has(voice), "%s shares %s" % [hero.id, voice])
		voices[voice] = hero.id
		assert_lt(_loudness(voice), quietest_danger, "%s is softer than danger" % voice)
	assert_eq(ROSTER.heroes[0].level_up_sound, &"quack", "Banane keeps the quack")


## Spec 10 §4.2: the frequent sounds have the felt thump under them and vary more.
func test_frequent_sounds_get_the_felt_thump_and_vary() -> void:
	var frequent: Array[StringName] = [&"hit", &"pop", &"pickup", &"dash", &"coin", &"hurt"]
	for stats: WeaponStats in _weapons():
		if stats.evolved_from == &"":
			frequent.append(stats.sound)
	for sound: StringName in frequent:
		assert_true(_varies(sound), "%s varies" % sound)
	for sound: StringName in [&"hit", &"pop", &"pickup", &"dash", &"coin", &"hurt"]:
		assert_true(SfxBank.FELT_THUMP.has(sound), "%s has the felt thump" % sound)
		assert_gt(_low_share(sound), _low_share_without_thump(sound), "%s is warmer" % sound)


func _varies(sound: StringName) -> bool:
	return Sfx.RULES.varied.has(sound) and Sfx.RULES.volume_drop(sound) > 0.0


## Share of the sound's energy that sits below ~200 Hz (a simple one-pole low-pass).
func _low_share(sound: StringName) -> float:
	return _low_share_of(SfxBank.make(sound))


func _low_share_without_thump(sound: StringName) -> float:
	var wav: AudioStreamWAV = SfxBank.make(sound)
	var count: int = wav.data.size() / 2
	var data: PackedByteArray = wav.data.duplicate()
	var amount: float = SfxBank.FELT_THUMP[sound]
	for i: int in count:
		var t: float = float(i) / Synth.RATE
		var value: float = data.decode_s16(i * 2) / 32000.0 - amount * SfxBank.felt_thump(t)
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32000.0))
	var plain: AudioStreamWAV = AudioStreamWAV.new()
	plain.data = data
	plain.mix_rate = wav.mix_rate
	return _low_share_of(plain)


func _low_share_of(wav: AudioStreamWAV) -> float:
	var smooth: float = 0.0
	var low: float = 0.0
	var all: float = 0.0
	var k: float = 1.0 - exp(-TAU * 200.0 / wav.mix_rate)
	for i: int in range(0, wav.data.size() - 1, 2):
		var value: float = wav.data.decode_s16(i)
		smooth += k * (value - smooth)
		low += smooth * smooth
		all += value * value
	return low / maxf(all, 1.0)


## Spec 10 §4.2: voice limits and a couple of starts per frame keep a crowd from stacking up.
func test_voice_limits_live_in_data() -> void:
	assert_gt(Sfx.max_voices(&"pop"), Sfx.RULES.starts_per_frame, "a crowd rolls over frames")
	assert_lte(Sfx.max_voices(&"evolution"), 1)
	assert_between(Sfx.RULES.starts_per_frame, 1, 3)
	assert_lt(Sfx.RULES.pitch_range(&"pickup"), 0.06, "the XP chain steps stay clear")
