extends Node3D

@onready var mesh = $Mesh
@onready var notes = $NoteContainer
var id
var start
var end
var pos
var offset = -0.7
var moves = []
var move_i = 0
var RAIL_ACTIVATE_DISTANCE = 85
var active = false
var initial_position = Vector3.ZERO
var length = 0
func get_pos() -> float:
	return  Game.panelSize -((start - Game.currentTime) * Game.settings["gameplay"]["velocity"] / 1000)
func _ready() -> void:
	initial_position = position
	mesh.scale.z = 0
	mesh.position.z = get_pos() - mesh.scale.z / 2
func _process(_delta: float) -> void:
	if moves.size() > 0:
		if move_i < moves.size():
			var move = moves[move_i]
			if move["time"] <= Game.currentTime and Game.currentTime < move["endtime"]:
				move_rail(move, Game.currentTime)
			elif Game.currentTime >= move["endtime"]:
				move_i += 1
				initial_position = position
	mesh.position.z = get_pos() - mesh.scale.z / 2
	length = (end - start) * Game.panelSize / Game.travelTime
	if length > get_pos():
		length = get_pos()
	mesh.scale.z = length

	if start - Game.currentTime < RAIL_ACTIVATE_DISTANCE:
		active = true
	if end < Game.currentTime:
		active = false
	if end < Game.currentTime - 500:
		visible = false
		if notes.get_child_count() == 0:
			queue_free()
func move_rail(move, current_time):
	var progress = float(current_time - move["time"]) / (move["endtime"] - move["time"])
	position.x = lerp(initial_position.x, move["position"], progress)
