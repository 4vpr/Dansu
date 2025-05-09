shader_type canvas_item;

uniform float radius = 10.0;
uniform float strength = 2.0;
uniform float darken = 1.0; // 1.0은 원래 밝기, 0.5면 반쯤 어두움

uniform sampler2D current_tex;
uniform sampler2D previous_tex;
uniform float mix_amount = 1.0; // 0.0이면 이전 텍스처, 1.0이면 현재 텍스처

void fragment() {
	
	vec4 current = texture(current_tex, UV);
    vec4 previous = texture(previous_tex, UV);
    COLOR = mix(previous, current, mix_amount);
    ivec2 i_size = textureSize(TEXTURE, 0);
    vec2 size = vec2(float(i_size.x), float(i_size.y));
    vec2 uv = UV;

    vec4 sum = vec4(0.0);
    float weight_sum = 0.0;

    for (int i = -int(radius); i <= int(radius); i++) {
        for (int j = -int(radius); j <= int(radius); j++) {
            vec2 offset = vec2(float(i), float(j)) / size * strength;
            float weight = exp(-(float(i*i + j*j)) / (2.0 * radius * radius));
            sum += texture(TEXTURE, uv + offset) * weight;
            weight_sum += weight;
        }
    }

    vec4 blurred = sum / weight_sum;
    blurred.rgb *= 1.1;    // 약간 밝기 강화 (부드러움 강조)
    blurred.rgb *= darken; // 여기에 어두움 적용 (0.0 ~ 1.0)

    blurred.a = 1.0;
    COLOR = blurred;
}