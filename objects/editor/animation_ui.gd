extends Control
var _name:String
var _fps:float
var frames = []
var effect:String
var id:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Label.text = _name
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
