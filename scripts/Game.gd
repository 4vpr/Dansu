extends Node

const perfect_plus: float = 24
const perfect_plus_score: float = 100
const perfect: float = 48
const perfect_score = 99
const great: float = 72
const great_score = 50
const ok: float = 144
const ok_score = 25
const bad: float = 288
const bad_score = 0

var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var playerSize = 450
var currentTime: float = 0.0
var velocity: float = 10
const panelSize = 11.3
var select_map
var select_folder
func GetSprite(s):
	return OS.get_user_data_dir().path_join("Songs/" + select_folder + "/sprite/" + s)
func GetFile(i):
	var r
	if select_folder:
		if i == "path":
			r = OS.get_user_data_dir().path_join("Songs/" + select_folder)
		if i == "song":
			r = OS.get_user_data_dir().path_join("Songs/" + select_folder + "/song.mp3")
		if i == "map":
			r = OS.get_user_data_dir().path_join("Songs/" + select_folder + "/" + select_map)
	return r
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
