extends Node

@onready var player_a := $CurrentPlayer
@onready var player_b := $NextPlayer

var fade_duration: float = 0.3
var target_volume_db: float = 0.0

var current_player: AudioStreamPlayer
var next_player: AudioStreamPlayer
var crossfade_tween: Tween = null
var is_crossfading: bool = false

func _ready() -> void:
	current_player = player_a
	next_player = player_b
	current_player.volume_db = target_volume_db
	next_player.volume_db = -80
	Game.connect("beatmap_selected", Callable(self, "_on_beatmap_selected"))

func _on_beatmap_selected(beatmap: Beatmap) -> void:
	if is_crossfading:
		if crossfade_tween:
			crossfade_tween.kill()
		_finish_crossfade()
	beatmap.load_song(next_player)
	if next_player.stream:
		next_player.play()
		var middle = 0.5 * next_player.stream.get_length()
		next_player.seek(middle)
	_crossfade()

func _crossfade() -> void:
	is_crossfading = true
	crossfade_tween = create_tween()
	crossfade_tween.tween_property(current_player, "volume_db", -80, fade_duration)
	crossfade_tween.tween_property(next_player, "volume_db", target_volume_db, fade_duration)
	crossfade_tween.tween_callback(Callable(self, "_finish_crossfade"))

func _finish_crossfade() -> void:
	current_player.stop()
	var temp = current_player
	current_player = next_player
	next_player = temp
	next_player.volume_db = -80
	is_crossfading = false
