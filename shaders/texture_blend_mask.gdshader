shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform sampler2D overlay_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D mask_texture : hint_default_black, filter_linear_mipmap;

// Overlay tiling: number of texture repeats per unit of object-space distance.
// Smaller values = larger tiles. Larger values = smaller tiles.
uniform float overlay_tiles_per_unit : hint_range(0.01, 10.0) = 1.0;

// Rainbow and hue controls
uniform bool enable_rainbow_cycle = false;
uniform float cycle_speed : hint_range(0.0, 5.0) = 1.0;

uniform bool enable_static_hue_shift = false;
uniform float static_hue_value : hint_range(0.0, 1.0) = 0.0;

varying vec3 object_position;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;

    return vec3(
        abs(q.z + (q.w - q.y) / (6.0 * d + e)),
        d / (q.x + e),
        q.x
    );
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
    // Vertex position in the mesh's local coordinate space.
    object_position = VERTEX;
}

void fragment() {
    vec4 base_color = texture(base_texture, UV);

    // Triplanar-style projection using object-space position.
    // Each face uses the two coordinates that span its plane.
    vec3 p = object_position * overlay_tiles_per_unit;

    vec3 n = abs(normalize(NORMAL));
    n /= max(n.x + n.y + n.z, 0.0001);

    vec2 uv_x = p.zy;
    vec2 uv_y = p.xz;
    vec2 uv_z = p.xy;

    vec3 overlay_x = texture(overlay_texture, uv_x).rgb;
    vec3 overlay_y = texture(overlay_texture, uv_y).rgb;
    vec3 overlay_z = texture(overlay_texture, uv_z).rgb;

    vec3 final_overlay_rgb =
        overlay_x * n.x +
        overlay_y * n.y +
        overlay_z * n.z;

    // Preserve the original hue effects.
    if (enable_rainbow_cycle || enable_static_hue_shift) {
        vec3 hsv = rgb2hsv(final_overlay_rgb);

        if (enable_rainbow_cycle) {
            hsv.x = fract(hsv.x + TIME * cycle_speed);
        } else if (enable_static_hue_shift) {
            hsv.x = fract(hsv.x + static_hue_value);
        }

        final_overlay_rgb = hsv2rgb(hsv);
    }

    // Keep the original mask and base-texture UVs.
    float mask = texture(mask_texture, UV).r;

    ALBEDO = mix(base_color.rgb, final_overlay_rgb, mask);
}