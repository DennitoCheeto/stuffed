// A plushie hero's baked picture (PlushiePuppet, spec 08 §6): the zombies' dark ink outline
// around the whole silhouette (#172), the puppets' felt grain and the white hit flash. The
// picture comes from a SubViewport, so its colours are premultiplied.
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform vec4 outline_color : source_color = vec4(0.11, 0.1, 0.14, 1.0);
// Outline width in texels of the picture.
uniform float outline_texels = 4.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.1;
uniform float grain_scale = 0.22;

varying vec2 local_position;
varying vec4 tint;

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
	tint = COLOR;
}

void fragment() {
	vec4 picture = texture(TEXTURE, UV);
	float around = 0.0;
	for (int i = 0; i < 12; i++) {
		float turn = float(i) * 0.5235988;
		vec2 step = vec2(cos(turn), sin(turn)) * TEXTURE_PIXEL_SIZE;
		around = max(around, texture(TEXTURE, UV + step * outline_texels).a);
		around = max(around, texture(TEXTURE, UV + step * outline_texels * 0.5).a);
	}
	vec2 p = local_position * grain_scale;
	float grain = value_noise(p) * 0.6 + value_noise(p * 2.7) * 0.4;
	vec3 felt = picture.rgb * (1.0 - grain_strength * (grain - 0.5) * 2.0);
	felt = mix(felt, vec3(picture.a), flash);
	float ink = around * outline_color.a;
	vec4 result = vec4(felt, picture.a) + vec4(outline_color.rgb * ink, ink) * (1.0 - picture.a);
	COLOR = vec4(result.rgb * tint.rgb, result.a) * tint.a;
}
