extends VBoxContainer
var posY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	posY = position.y
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	position.y = lerp(position.y,posY,delta * 20)
	if posY > 25:
		posY = lerp(posY,25.0,delta * 20)
	if posY < (size.y/2 - 1080) * -1:
		if size.y/2 > 1080.0:
			posY = lerp(posY,1080.0 - size.y/2 ,delta * 20)
		else:
			posY = lerp(posY,25.0,delta * 20)
		pass
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			posY += 50
			#print(str(posY) + "/" + str(size.y))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			posY -= 50
			#print(str(posY) + "/" + str(size.y))
