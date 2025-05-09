extends Node
class_name SfxPool

const MAX_SOURCES = 16
var pool: Array[AudioStreamPlayer] = []

func _ready():
	for i in MAX_SOURCES:
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)

func play_sound(stream: AudioStream):
	for p in pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(Game.volume_sfx)
			p.play()
			return
