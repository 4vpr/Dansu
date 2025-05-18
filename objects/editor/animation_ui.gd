extends Control
var animation
@onready var root = $"../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel/Label.text = animation["name"]
	$Panel/Label2.text = "id: " + str(animation["id"])
	$Panel/Edit.pressed.connect(_on_edit_pressed)
	$Panel/Del.pressed.connect(_on_del_pressed)

func _on_edit_pressed():
	root.selected_animation = animation
	$"../../Panel"._update()
	
func _on_del_pressed():
	root.animations.erase(animation)
	$"../../Panel"._update()
	self.queue_free()

func _update() -> void:
	$Panel/Label.text = animation["name"]
