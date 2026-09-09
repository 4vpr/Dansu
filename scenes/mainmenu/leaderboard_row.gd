extends PanelContainer
class_name ChartLeaderboardRow

signal replay_requested

@onready var avatar: TextureRect = $Margin/Columns/ProfileImage
@onready var replay_button: Button = $Margin/Columns/Replay
var _avatar_request: HTTPRequest


func _ready() -> void:
	replay_button.disabled = true
	replay_button.pressed.connect(func(): replay_requested.emit())


func set_online_entry(item: Dictionary) -> void:
	replay_button.disabled = not bool(item.get("replay_available", false))
	replay_button.tooltip_text = "Watch replay" if not replay_button.disabled else "Replay unavailable"
	var url := str(item.get("avatar_url", ""))
	if not (url.begins_with("https://") or url.begins_with("http://127.0.0.1:") or url.begins_with("http://localhost:")):
		return
	_avatar_request = HTTPRequest.new()
	_avatar_request.timeout = 15.0
	_avatar_request.body_size_limit = 4 * 1024 * 1024
	add_child(_avatar_request)
	_avatar_request.request_completed.connect(_on_avatar_loaded)
	if _avatar_request.request(url) != OK:
		_avatar_request.queue_free()


func _on_avatar_loaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_avatar_request.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.is_empty():
		return
	var image := Image.new()
	var error := image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_webp_from_buffer(body)
	if error == OK:
		avatar.texture = ImageTexture.create_from_image(image)

@export_group("Node References")
@export var rank_label: Label
@export var name_label: Label
@export var accuracy_label: Label
@export var combo_label: Label


func set_entry(rank_text: String, display_name: String, accuracy: float, combo_text: String, highlighted: bool = false) -> void:
	rank_label.text = rank_text
	name_label.text = display_name
	accuracy_label.text = "%.2f%%" % accuracy
	combo_label.text = combo_text
	self_modulate = Color(1.0, 0.91, 0.55) if highlighted else Color.WHITE
