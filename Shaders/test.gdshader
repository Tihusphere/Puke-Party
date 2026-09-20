shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D texture_a : source_color;  // Base texture (Black areas)
uniform sampler2D texture_b : source_color;  // Overlay texture (White areas)
uniform sampler2D mask_texture : hint_default_white;

void fragment() {
    vec4 color_a = texture(texture_a, UV);
    vec4 color_b = texture(texture_b, UV);
    float mask = texture(mask_texture, UV).r;
    
    // Smoothly mix between Texture A and Texture B based on the mask
    ALBEDO = mix(color_a.rgb, color_b.rgb, mask);
}

