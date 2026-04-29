// cartoon_outline.gdshader
// Fat outline + palette clamp + emissive accent
// Assign to a CanvasItemMaterial (or ShaderMaterial) on any sprite.
// Parameters:
//   outline_color    — border color (default opaque black)
//   outline_width    — pixels in screen space (4–6 for mobile portrait)
//   palette_strength — 0 = full color, 1 = fully palette-clamped
//   emissive_color   — glow color multiplied at high brightness
//   emissive_thresh  — luminance threshold above which emissive kicks in

shader_type canvas_item;

uniform sampler2D TEXTURE : source_color, hint_default_white;
uniform vec4  outline_color   : source_color = vec4(0.05, 0.02, 0.0, 1.0);
uniform float outline_width   : hint_range(0.0, 8.0, 0.5) = 4.0;
uniform float palette_strength: hint_range(0.0, 1.0) = 0.6;
uniform vec4  emissive_color  : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float emissive_thresh : hint_range(0.0, 1.0) = 0.88;

// Palette clamp: quantise each channel to N steps (cartoon flat shading)
uniform int palette_steps : hint_range(2, 16) = 5;

vec4 palette_clamp(vec4 col) {
	float steps = float(palette_steps);
	vec3 clamped = floor(col.rgb * steps + 0.5) / steps;
	return vec4(mix(col.rgb, clamped, palette_strength), col.a);
}

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = UV;
	vec4 col = texture(TEXTURE, uv);

	// ── Outline pass (sample 8 neighbours) ──────────────────────────────────
	vec2 texel = outline_width * TEXTURE_PIXEL_SIZE;
	float a = 0.0;
	a += texture(TEXTURE, uv + vec2( texel.x,  0.0     )).a;
	a += texture(TEXTURE, uv + vec2(-texel.x,  0.0     )).a;
	a += texture(TEXTURE, uv + vec2( 0.0,      texel.y )).a;
	a += texture(TEXTURE, uv + vec2( 0.0,     -texel.y )).a;
	a += texture(TEXTURE, uv + vec2( texel.x,  texel.y )).a * 0.7;
	a += texture(TEXTURE, uv + vec2(-texel.x,  texel.y )).a * 0.7;
	a += texture(TEXTURE, uv + vec2( texel.x, -texel.y )).a * 0.7;
	a += texture(TEXTURE, uv + vec2(-texel.x, -texel.y )).a * 0.7;

	// Where base pixel is transparent but neighbour is opaque → outline
	float outline_mask = clamp(a, 0.0, 1.0) * (1.0 - col.a);
	vec4 outlined = mix(col, outline_color, outline_mask);

	// ── Palette clamp ────────────────────────────────────────────────────────
	vec4 result = palette_clamp(outlined);

	// ── Emissive accent ──────────────────────────────────────────────────────
	float lum = luminance(result.rgb);
	float emissive_mask = smoothstep(emissive_thresh - 0.05, emissive_thresh + 0.05, lum);
	result.rgb = mix(result.rgb, result.rgb * emissive_color.rgb, emissive_mask * emissive_color.a);

	COLOR = result;
}
