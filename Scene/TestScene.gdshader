shader_type canvas_item;

uniform vec2 fill_tex_offset = vec2(0.0);
uniform vec2 fill_tex_scale = vec2(1.0);
uniform sampler2D fill_tex;
uniform vec4 base_color: hint_color = vec4(1.0,1.0,0.0,1.0);
uniform vec4 fill_brighten_color: hint_color = vec4(0.0,0.0,1.0,0.2);
uniform float cutoff: hint_range(0.0,1.0) = 0.5;
uniform vec4 outline_color: hint_color = vec4(1.0,0.0,0.0,1.0);

void fragment() {
	vec4 fill_tex_color = texture(fill_tex, (UV + fill_tex_offset) * fill_tex_scale);
	
	vec4 fill_tex_color_new = vec4(mix(fill_tex_color,fill_brighten_color,fill_brighten_color.a));
	vec4 not_working_tex_color = texture(TEXTURE, UV);
	vec4 own_texture_color = vec4(COLOR.rgb,not_working_tex_color.a); //workaround because DynamicFonts are weird -> need to use COLOR instead of TEXTURE
	float own_texture_color_cutoff = step(own_texture_color.r,cutoff);
	
	vec4 colored_fill = vec4(own_texture_color.rgb * fill_tex_color.a * base_color.rgb,own_texture_color.a);
	vec4 new_colored_fill = vec4(mix(colored_fill.rgb,fill_brighten_color.rgb,fill_brighten_color.a),colored_fill.a);
	vec3 merged_color = mix(colored_fill.rgb + new_colored_fill.rgb, outline_color.rgb, own_texture_color_cutoff);
	COLOR = vec4(merged_color,colored_fill.a);
}
