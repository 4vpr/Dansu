extends Node

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			print("터치 시작 위치: ", event.position)
		else:
			print("터치 해제 위치: ", event.position)
	elif event is InputEventScreenDrag:
		print("터치 드래그 위치: ", event.position)
func ts_keyevent(i):
		var ev := InputEventAction.new()
		ev.action = i
		ev.pressed = true
		Input.parse_input_event(ev)

var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var playerSize = 450
var currentTime: float = 0.0
var velocity: float = 10
const panelSize = 11.3

var select_map
var select_folder
var travelTime = panelSize * 1000 / velocity
#Settings
var volume = 0.1
var volume_sfx = 0.2
func setVelocity(velo:float) -> void:
	velocity = velo
	travelTime = panelSize * 1000 / velocity
	pass
var audio_start_ms
var playback; var playback_prev; var SongSlider
var lastmix; var last_mix_time
