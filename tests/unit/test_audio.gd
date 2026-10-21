extends GutTest


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


func test_music_stays_in_range_and_loops_seamlessly() -> void:
	var music: MusicPlayer = MusicPlayer.new()
	music.use_track(&"title")
	var bpm: float = MusicPlayer.TRACKS[&"title"][0]
	var loop_seconds: float = 16.0 * 60.0 / bpm
	var t: float = 0.0
	while t < loop_seconds:
		var value: float = music.sample_at(t)
		assert_true(absf(value) <= 1.5, "in range at %.2f" % t)
		assert_almost_eq(music.sample_at(t + loop_seconds), value, 0.001, "loops at %.2f" % t)
		t += 0.37
	music.free()
