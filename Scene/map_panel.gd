extends ScrollContainer

var velocity := 0.0
var target_offset := 0.0
var elasticity := 200.0
var damping := 10.0

func _process(delta):
	# 자연스럽게 목표 위치로 감속 이동
	var current_offset = get_v_scroll()
	var difference = target_offset - current_offset
	velocity += difference * elasticity * delta
	velocity *= pow(0.1, delta * damping)
	
	current_offset += velocity * delta
	set_v_scroll(current_offset)

	# 상한, 하한 제한 + 오버스크롤 허용
	var max_scroll = get_v_scroll_bar().max_value
	if target_offset < -100:
		target_offset = -100  # 위로 최대 오버스크롤
	elif target_offset > max_scroll + 100:
		target_offset = max_scroll + 100  # 아래로 최대 오버스크롤

func _gui_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		target_offset -= event.relative.y  # 드래그 시 스크롤 조정
