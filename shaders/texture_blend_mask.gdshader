shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform sampler2D overlay_texture : source_color, filter_linear_mipmap;
uniform sampler2D mask_texture : hint_default_black, filter_linear_mipmap;

// --- Rainbow and Hue Control Uniforms ---
uniform bool enable_rainbow_cycle = false;       // Toggle for running rainbow cycle
uniform float cycle_speed : hint_range(0.0, 5.0) = 1.0;

uniform bool enable_static_hue_shift = false;    // Toggle for fixed hue shift
uniform float static_hue_value : hint_range(0.0, 1.0) = 0.0; // The fixed hue color (0.0 to 1.0)

// Helper function to convert RGB to HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Helper function to convert HSV back to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec4 base_color = texture(base_texture, UV);
    vec4 overlay_color = texture(overlay_texture, UV);
    float mask = texture(mask_texture, UV).r;
    
    // Modify only the overlay texture color
    vec3 final_overlay_rgb = overlay_color.rgb;
    
    if (enable_rainbow_cycle || enable_static_hue_shift) {
        // Convert to HSV to manipulate the color hue safely
        vec3 hsv = rgb2hsv(final_overlay_rgb);
        
        if (enable_rainbow_cycle) {
            // Cycle continuously over time
            hsv.x = fract(hsv.x + (TIME * cycle_speed));
        } else if (enable_static_hue_shift) {
            // Apply fixed hue target offset
            hsv.x = fract(hsv.x + static_hue_value);
        }
        
        // Convert back to RGB
        final_overlay_rgb = hsv2rgb(hsv);
    }
    
    // Interpolate between the base texture and the potentially modified overlay texture
    ALBEDO = mix(base_color.rgb, final_overlay_rgb, mask);
}
