shader_type spatial;

uniform sampler2D mask_texture : source_color;

void fragment()
{
	vec2 test_uv = vec2(0.5, 0.5);

	float mask = texture(mask_texture, test_uv).r;

	ALBEDO = vec3(mask);
}

/*
shader_type spatial;

uniform sampler2D texture_a;
uniform sampler2D texture_b;
uniform sampler2D mask_texture;

void fragment()
{
	vec3 normal_texture = texture(texture_a, UV).rgb;
	vec3 secondary_texture = texture(texture_b, UV).rgb;

	float mask = texture(mask_texture, UV).r;

	ALBEDO = mix(
		normal_texture,
		secondary_texture,
		mask
	);
}
*/