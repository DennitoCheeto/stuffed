extends GutTest
## Music made in code (spec 10 §4.1, AC-108): every place has a track in data, tracks loop without
## a click, layers join at the run's times and crowd, the siege gets busier per wave, endless is
## the run at full intensity and a little faster, stingers play once, and nothing clips.

const RULES: MusicRules = preload("res://data/audio/music/music_rules.tres")
const PLACES: Array[StringName] = [&"title", &"town", &"run", &"boss", &"siege", &"endless"]
const STINGERS: Array[StringName] = [
	&"goal",
	&"hero_died",
	&"siege_won",
	&"siege_lost",
	&"evolution",
]


func _peak(samples: PackedFloat32Array) -> float:
	var peak: float = 0.0
	for value: float in samples:
		peak = maxf(peak, absf(value))
	return peak


func _sum(stems: Array[PackedFloat32Array]) -> PackedFloat32Array:
	return MusicRender.mix(stems)


func test_every_place_and_stinger_has_its_music_in_data() -> void:
	for id: StringName in PLACES:
		var track: MusicTrack = RULES.track(id)
		assert_not_null(track, "%s has a track" % id)
		if track == null:
			continue
		assert_true(track.loops, "%s loops" % id)
		assert_gt(track.layers.size(), 1, "%s has several layers" % id)
		assert_eq(track.resource_path, "res://data/audio/music/%s.tres" % id, "%s is data" % id)
	for id: StringName in STINGERS:
		var stinger: MusicTrack = RULES.stinger(id)
		assert_not_null(stinger, "%s has a stinger" % id)
		if stinger != null:
			assert_false(stinger.loops, "%s plays once" % id)
			assert_lt(stinger.seconds(), 4.0, "%s is short" % id)


func test_tracks_are_never_silent_and_never_clip() -> void:
	for id: StringName in PLACES:
		var track: MusicTrack = RULES.track(id)
		var stems: Array[PackedFloat32Array] = MusicRender.render_track(track)
		for i: int in stems.size():
			assert_gt(_peak(stems[i]), 0.02, "%s layer %d makes sound" % [id, i])
		var all: float = _peak(_sum(stems)) * RULES.loudness
		assert_lt(all, 1.0, "%s at full intensity stays under clipping (%.2f)" % [id, all])


func test_a_loop_has_no_click_where_it_starts_again() -> void:
	var track: MusicTrack = RULES.track(&"run")
	var stems: Array[PackedFloat32Array] = MusicRender.render_track(track)
	assert_eq(stems[0].size(), MusicRender.length_of(track))
	assert_almost_eq(
		float(stems[0].size()), track.seconds() * Synth.RATE, 1.0, "one loop is the bars' length"
	)
	for i: int in stems.size():
		var stem: PackedFloat32Array = stems[i]
		var jump: float = absf(stem[0] - stem[stem.size() - 1])
		assert_lt(jump, 0.25, "layer %d joins its own start smoothly" % i)
	# A note near the end rings on at the start (wraps round), not cut off.
	var lead: MusicLayer = MusicLayer.new()
	lead.instrument = MusicLayer.Instrument.CHORDS
	lead.steps = "...............x"
	var test_track: MusicTrack = MusicTrack.new()
	test_track.roots = [60]
	test_track.layers = [lead]
	var wrapped: PackedFloat32Array = MusicRender.render_layer(test_track, lead)
	assert_gt(_peak(wrapped.slice(0, 2000)), 0.01, "the last chord rings on at the loop's start")


func test_run_layers_join_at_the_times_and_the_crowd() -> void:
	var run: MusicTrack = RULES.track(&"run")
	assert_eq(run.top_level(), 2, "the run has three steps")
	assert_eq(RULES.run_level(0.0, 0), 0, "calm at the start")
	assert_eq(RULES.run_level(RULES.run_drums_seconds - 1.0, 0), 0)
	assert_eq(RULES.run_level(RULES.run_drums_seconds, 0), 1, "drums after 2:00")
	assert_eq(RULES.run_level(30.0, RULES.run_drums_crowd), 1, "or with a big crowd")
	assert_eq(RULES.run_level(RULES.run_full_seconds, 0), 2, "everything after 5:00")
	assert_eq(RULES.run_drums_seconds, 120.0)
	assert_eq(RULES.run_drums_crowd, 150)
	assert_eq(RULES.run_full_seconds, 300.0)
	var drums: Array[int] = []
	for layer: MusicLayer in run.layers:
		if layer.is_drum():
			drums.append(layer.level)
	assert_false(drums.has(0), "no drums while calm")
	assert_true(drums.has(1), "drums join on the second level")


func test_siege_gets_busier_each_wave_and_endless_is_the_full_run_faster() -> void:
	var siege: MusicTrack = RULES.track(&"siege")
	assert_eq(siege.top_level(), 2)
	assert_eq(RULES.siege_level(0), 0)
	assert_eq(RULES.siege_level(1), 1)
	assert_eq(RULES.siege_level(4), 2)
	var run: MusicTrack = RULES.track(&"run")
	var endless: MusicTrack = RULES.track(&"endless")
	assert_eq(endless.top_level(), 0, "every endless layer plays from the start")
	assert_eq(endless.layers.size(), run.layers.size(), "the run's layers")
	assert_gt(endless.bpm, run.bpm, "a little faster")
	assert_lt(RULES.track(&"town").bpm, run.bpm, "town is calmer than the run")


func test_a_deck_fades_layers_towards_the_intensity() -> void:
	var track: MusicTrack = RULES.track(&"run")
	var deck: MusicDeck = MusicDeck.new(track)
	add_child_autofree(deck)
	var clips: Array[AudioStreamWAV] = []
	while clips.size() < track.layers.size():
		clips.append(MusicRender.to_wav(PackedFloat32Array([0.0, 0.0]), true))
	deck.start(clips, 0)
	deck.fade = 1.0
	assert_eq(deck.layer_volume(0), 1.0, "a calm layer plays")
	var drum: int = 3
	assert_eq(track.layers[drum].level, 1, "layer 3 is the kick")
	assert_eq(deck.layer_volume(drum), 0.0, "drums wait")
	deck.update(1, 0.5, 0.5)
	assert_almost_eq(deck.layer_volume(drum), 0.5, 0.001, "half way in")
	deck.update(1, 0.5, 0.5)
	assert_eq(deck.layer_volume(drum), 1.0, "in")
	assert_eq(deck.layer_volume(track.layers.size() - 1), 0.0, "full layers still wait")
	assert_true(deck.players[0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "clips loop")
