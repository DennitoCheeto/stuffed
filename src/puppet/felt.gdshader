// Felt look for plushie pieces: a fuzzy grain that sticks to each piece (so it moves with it),
// plus a white hit flash.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.14;
uniform float grain_scale = 0.15;
// Town buildings only (spec 05 §3.4): flags and bunting flutter. A baked building mesh stores
// how far each corner may move in UV.x (0 = fixed, 1 = the cloth's loose end). 0 pixels = off,
// so sprites (whose UV is a texture position) never move.
uniform float flutter_pixels = 0.0;
uniform float flutter_speed = 6.0;

varying vec2 local_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	local_position = VERTEX;
	float wave = TIME * flutter_speed + (VERTEX.x + VERTEX.y) * 0.09;
	VERTEX += vec2(sin(wave) * 0.5, cos(wave * 1.3)) * flutter_pixels * UV.x;
}

void fragment() {
	vec2 p = local_position * grain_scale;
	float grain = value_noise(p) * 0.6 + value_noise(p * 2.7) * 0.4;
	COLOR.rgb *= 1.0 - grain_strength * (grain - 0.5) * 2.0;
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
