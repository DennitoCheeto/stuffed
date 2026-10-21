// Felt look for plushie pieces: a fuzzy grain that sticks to each piece (so it moves with it),
// plus a white hit flash.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.14;
uniform float grain_scale = 0.15;

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
}

void fragment() {
	vec2 p = local_position * grain_scale;
	float grain = value_noise(p) * 0.6 + value_noise(p * 2.7) * 0.4;
	COLOR.rgb *= 1.0 - grain_strength * (grain - 0.5) * 2.0;
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
