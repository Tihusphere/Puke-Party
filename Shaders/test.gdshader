shader_type spatial;

uniform sampler2D texture_a : source_color;
uniform sampler2D texture_b : source_color;
uniform sampler2D mask_texture : source_color;

uniform float mask_strength : hint_range(0.0, 1.0) = 1.0;

void fragment()
{
	vec4 tex_a = texture(texture_a, UV);
	vec4 tex_b = texture(texture_b, UV);

	float mask = texture(mask_texture, UV).r;
	mask *= mask_strength;

	ALBEDO = mix(
		tex_a.rgb,
		tex_b.rgb,
		mask
	);

	ALPHA = mix(
		tex_a.a,
		tex_b.a,
		mask
	);
}