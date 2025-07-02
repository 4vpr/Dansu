extends Node3D
@onready var mesh = $Mesh
@onready var notes = $NoteContainer
var id
var start
var end
var size = 11.6
var offset = -0.7
var moves = []
var move_i = 0
var fix = 200
var initial_position = Vector3.ZERO


func _ready() -> void:
	initial_position = position
	mesh.scale.z = 0


func _process(delta: float) -> void:
	if moves.size() > 0:

		if move_i < moves.size():
			var move = moves[move_i]

			if move["time"] <= Game.currentTime and Game.currentTime < move["endtime"]:
				move_rail(move, Game.currentTime)
				pass
			elif Game.currentTime >= move["endtime"]:
				move_i += 1
				initial_position = position



	if start > Game.currentTime:
		mesh.scale.z = (Game.travelTime - (start - Game.currentTime)) / (Game.travelTime)
		mesh.position.z = (mesh.scale.z * size / 2) - size / 2 + offset
	else:
		mesh.scale.z = 1
		mesh.position.z = offset
	if end < Game.currentTime + Game.travelTime && end != -1:
		mesh.scale.z = (end - Game.currentTime) / (Game.travelTime)
		mesh.position.z = (mesh.scale.z * size / -2) + size / 2 + offset
		pass


	if start - Game.currentTime < fix:
		set_meta("Active",true)


	

	if end < Game.currentTime:
		visible = false
		if notes.get_child_count() == 0:
			queue_free()

func move_rail(move, current_time):
	var progress = float(current_time - move["time"]) / (move["endtime"] - move["time"])
	position.x = lerp(initial_position.x, move["position"], progress)
