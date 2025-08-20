extends TextureRect

var chart
var groove: float = 0.2
var scaleVel
var groove_rst: float = 0.2
var default_dance_i = 0 #다음에 재생할 기본 춤동작;
var sprites_current = [] #현재 재생중인 스프라이트 목록;
var sprites_current_index = 0 #현재 스프라이트 인덱스;
var sprites_current_update_time = 0 #재생중인시간;
var sprites_current_update = 0 #재생이끝나는시간;
var time = 0
var playable = false

func _ready() -> void:
	CM.connect("chart_loaded", Callable(self, "_loaded"))
	CM.connect("chart_selected", Callable(self, "_reset"))
	await get_parent().ready
func _reset(c):
	if c != null:
		chart = c
		print(chart.meta_title)
	else:
		chart = Game._use_default_skin()
	groove = 0.2
	groove_rst = 0.2
	default_dance_i = 0
	sprites_current.clear()
	sprites_current_index = 0
	sprites_current_update_time = 0
	sprites_current_update = 0
	chart = c
	pivot_offset = Vector2(size.x / 2, size.y)
	if chart.use_default_skin:
		chart = Game._use_default_skin()
	else:
		var file = FileAccess.open(chart.json_path, FileAccess.READ)
		if not file:
			return
		var json = JSON.parse_string(file.get_as_text())
		chart.load_player_resources(json)
	setPlayerIdle()
	playAnimation()
	scaleVel = scale
	playable = true

func _process(delta: float) -> void:
	if playable:
		time += delta
		playAnimation()
		if groove < groove_rst:
			scale.y = scaleVel.y + (groove_rst - groove) / groove_rst / 6
			groove += delta
		else:
			scale = scaleVel
			pass
func setPlayerIdle():
	setAnimation(chart.player_animation.get("idle", 0))
func setAnimation(id):
	for animation in chart.animations:
		if animation["id"] == id:
			sprites_current = animation["frames"]
			sprites_current_index = 0
			sprites_current_update = time
			sprites_current_update_time = 1 / animation["fps"]
func getNextDefaultDance() -> int:
	var default_dances = chart.player_animation.get("defaultdance", [])
	if default_dances.is_empty():
		return 0

	if default_dance_i >= default_dances.size():
		default_dance_i = 0

	var id = default_dances[default_dance_i]
	default_dance_i += 1
	return id

func playAnimation():
	if sprites_current_update + sprites_current_update_time * (sprites_current_index + 1) < time:
		sprites_current_index += 1
	if sprites_current.size() > sprites_current_index:
		texture = sprites_current[sprites_current_index]
	else:
		setPlayerIdle()
