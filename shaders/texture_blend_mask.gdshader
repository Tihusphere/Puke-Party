shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform sampler2D overlay_texture : source_color, filter_linear_mipmap;
uniform sampler2D mask_texture : hint_default_black, filter_linear_mipmap;

void fragment() {
	vec4 base_color = texture(base_texture, UV);
	vec4 overlay_color = texture(overlay_texture, UV);
	float mask = texture(mask_texture, UV).r;
	
	// Interpolate between the base texture and overlay texture using the mask value
	ALBEDO = mix(base_color.rgb, overlay_color.rgb, mask);
}