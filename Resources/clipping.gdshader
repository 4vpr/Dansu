shader_type spatial;

render_mode blend_mix, depth_draw_never, cull_back, unshaded;

uniform float fade_start : hint_range(0.0, 100.0) = 8.0;
uniform float fade_end : hint_range(0.0, 100.0) = 12.0;

void fragment() {
	// VIEW 공간에서 카메라는 (0, 0, 0), VERTEX 길이로 거리 계산
	float distance = length(VERTEX);

	// 부드러운 알파 페이드
	float alpha = 1.0;
	if (distance > fade_start) {
		alpha = 1.0 - clamp((distance - fade_start) / (fade_end - fade_start), 0.0, 1.0);
	}

	ALBEDO = vec3(1.0); // 원하는 색상
	ALPHA = alpha;

	// 알파 너무 낮으면 렌더링 스킵 (퍼포먼스 최적화)
	if (ALPHA < 0.01) {
		discard;
	}
}