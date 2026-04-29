// wetness_gloss.gdshader
// Animated gloss highlight for wet surfaces (porcelain throne, sewer walls, slime)
// Driven by a scrolling specular mask — no separate normal map needed.

shader_type canvas_item;

uniform sampler2D TEXTURE : source_color, hint_default_white;
uniform float wet_strength  : hint_range(0.0, 1.0) = 0.45;
uniform float gloss_speed   : hint_range(0.0, 3.0) = 0.6;
uniform vec2  gloss_dir             = vec2(0.3, -0.8);
uniform vec4  gloss_color  : source_color = vec4(1.0, 0.98, 0.9, 1.0);
uniform float gloss_sharpness: hint_range(0.5, 8.0) = 3.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Scrolling gloss band
	vec2 dir = normalize(gloss_dir);
	float proj = dot(UV, dir) + TIME * gloss_speed * 0.05;
	float band = fract(proj);
	float highlight = pow(max(0.0, sin(band * PI)), gloss_sharpness);

	vec3 wet = mix(col.rgb, col.rgb * gloss_color.rgb + highlight * gloss_color.rgb * wet_strength,
	               col.a * wet_strength);

	COLOR = vec4(wet, col.a);
}
