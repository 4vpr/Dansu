extends Node
var config_file_path = "user://settings.cfg"
var settings = {}
const panelSize = 11.3
var score = Score.new()


func _init():
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		settings.resolution = config.get_value("graphics", "resolution", "1280x720")
		settings.fullscreen = config.get_value("graphics", "fullscreen",false)
		settings.volume_master = config.get_value("audio", "volume", 0.5)
		settings.volume_song = config.get_value("audio", "volume", 0.25)
		settings.volume_sfx = config.get_value("audio","volume",0.5)
		settings.velocity = config.get_value("gameplay", "velocity", 10.0)
		settings.playerheight = config.get_value("gameplay","playerheight",450)
		settings.offset = config.get_value("audio","offset",AudioServer.get_output_latency())
	else:
		settings.resolution = "1280x720"
		settings.fullscreen = false
		settings.volume_master = 0.5
		settings.volume_song = 0.25
		settings.volume_sfx = 0.5
		settings.velocity = 10.0
		settings.playerheight = 450
		settings.offset = AudioServer.get_output_latency()

func save_setting(section: String, key: String, value):
	var config = ConfigFile.new()
	config.load(config_file_path)  # 기존 값 유지
	config.set_value(section, key, value)
	config.save(config_file_path)

func save_settings():
	var config = ConfigFile.new()


var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()

var currentTime: float = 0.0


var select_map
var select_folder
var travelTime
#Settings
func setVelocity(v:float) -> void:
	settings.velocity = v
	travelTime = panelSize * 1000 / settings.velocity
	save_setting("gameplay", "velocity", settings.velocity)
	pass
var SongSlider
