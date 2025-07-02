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
	var adjusted_rms = pow(linear_rms, 0.1) 
	var target_scale = lerp(scale_min, scale_max, adjusted_rms)
	current_scale = move_toward(current_scale, target_scale, delta)
	scale = Vector2.ONE * target_scale
