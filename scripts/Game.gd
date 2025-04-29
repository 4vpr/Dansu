extends Node

const perfect_plus: float = 24
const perfect_plus_score: float = 100
const perfect: float = 52
const perfect_score = 99
const great: float = 68
const great_score = 50
const ok: float = 142
const ok_score = 25
const bad: float = 160
const bad_score = 0

var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var playerSize = 500
var currentTime: float = 0.0
var velocity: float = 10
const panelSize = 11.3
var selected = "el sonidito"
var travelTime = panelSize * 1000 / velocity
#Settings
var volume = 0.1
func setVelocity(velo:float) -> void:
	velocity = velo
	travelTime = panelSize * 1000 / velocity
	pass
