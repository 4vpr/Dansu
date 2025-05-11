extends RefCounted
class_name Beatmap

var notes = []
var rails = []
var animations = []
var player_animation = []

var meta_title:String = "?"
var meta_artist:String = "unknown"
var meta_creator:String = "unknown"

var file_song:String = "song.mp3"
var file_bg:String = "bg.jpg"

var diff_name:String = "?"
var diff_value:float = 0
var song_bpmstart:float = 0
var song_lerp:float = 0
var song_bpm:float = 100
var is_built_in = false
