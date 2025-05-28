extends TextureRect
@onready var audio_bus_index: int = AudioServer.get_bus_index("Master")
var scale_min: float = 0.9
var scale_max: float = 1.3
var current_scale: float = 1.0

func _ready() -> void:
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	var rms = AudioServer.get_bus_peak_volume_left_db(audio_bus_index, 0)
	var linear_rms = db_to_linear(rms)
	
	# 민감도를 낮추기 위해 루트값으로 보정 (지수 0.5나 더 낮게)
	var adjusted_rms = pow(linear_rms, 0.1)  # 0.3~0.5 사이 값으로 민감도 낮추기
	
	# 크기 보간
	var target_scale = lerp(scale_min, scale_max, adjusted_rms)
	
	# 부드럽게 따라가기
	current_scale = move_toward(current_scale, target_scale, delta)
	# rect_scale로 자연스럽게 반영 (2D UI 객체는 rect_scale로 크기 조절)
	scale = Vector2.ONE * target_scale
