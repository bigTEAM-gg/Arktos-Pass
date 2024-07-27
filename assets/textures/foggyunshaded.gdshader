shader_type spatial;
render_mode depth_draw_always, unshaded;

uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
global uniform vec3 player_position;
global uniform vec4 fog_color : source_color;
global uniform float fog_density;

varying vec3 world_vertex;

const float LOG2 = 1.442695;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Calculate the distance between the fragment and the character
	float chardistance = length(player_position - world_vertex);
	
	float fog_amount = 1.0 - exp2(-fog_density * fog_density * chardistance * chardistance * LOG2);
	fog_amount = clamp(fog_amount, 0.0, 1.0);
	    
	// Calculate the alpha value based on the distance
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo_tex.rgb;
	ALBEDO = mix(ALBEDO.rgb, fog_color.rgb, fog_amount);
}