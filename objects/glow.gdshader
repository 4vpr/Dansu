shader_type spatial;
render_mode unshaded;

uniform vec4 glow_color = vec4(0.0, 1.0, 1.0, 1.0); // 원하는 HEX 색상으로 설정 (예: Cyan)
uniform float glow_intensity = 2.0;
uniform float noise_scale = 5.0;
uniform float speed = 1.5;

void fragment() {
    vec3 pos = VERTEX * noise_scale;
    float time = TIME * speed;

    // 간단한 노이즈 계산
    float noise = sin(dot(pos.xy, vec2(12.9898, 78.233)) + time) * 43758.5453;
    noise = fract(noise);

    // 전기적 펄스 효과
    float pulse = sin(time * 3.0 + VERTEX.y * 5.0) * 0.5 + 0.5;

    // 최종 Emission 컬러 계산
    vec3 final_color = glow_color.rgb * (noise * pulse * glow_intensity);

    ALBEDO = glow_color.rgb;
    EMISSION = final_color;
    ALPHA = glow_color.a;
}