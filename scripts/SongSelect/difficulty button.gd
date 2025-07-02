extends Button

var beatmap: Beatmap
var hovered = false

@onready var tween

func _ready() -> void:
	pressed.connect(_press)
	mouse_entered.connect(_enter)
	mouse_exited.connect(_exit)
	if beatmap:
		text = str(int(beatmap.diff_value))
		if beatmap.diff_value < 10:
			text = "0" + text
		modulate = get_color_from_number(beatmap.diff_value)
func _select() -> void:
	animate_size(55)
	var scoreboard = get_tree().get_root().get_node("MainMenu/ScoreBoard")
	scoreboard._update()
	pass
func _unselect() -> void:
	animate_size(35)
	pass

func _press() -> void:
	Game.select_beatmap(beatmap,self)
	Game.lastSelectDiff = beatmap.diff_value

func _enter() -> void:
	if Game.selected_beatmap != beatmap:
		animate_size(45)

func _exit() -> void:
	if Game.selected_beatmap != beatmap:
		animate_size(35)

func animate_size(target_height: float) -> void:
	tween = create_tween()
	var current_size = custom_minimum_size
	var target_size = Vector2(current_size.x, target_height)
	tween.tween_property(self, "custom_minimum_size", target_size, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
var color_map = {
	0: Color("a0a0a0"),   # 회색
	5: Color("1AC9E6"),   # 하늘
	10: Color("1DE45D"),  # 초록
	15: Color("EAB835"),  # 노랑 
	20: Color("DE542C"),  # 주황 
	25: Color("C02323"),  # 빨강 
	30: Color("DE4CB2"),  # 핑크 
	35: Color("8b00ff"),   # 보라 
}
func get_color_from_number(value: float) -> Color:
	var keys = color_map.keys()
	keys.sort()

	if value <= keys[0]:
		return color_map[keys[0]]
	if value >= keys[-1]:
		return color_map[keys[-1]]

	for i in range(keys.size() - 1):
		var a = keys[i]
		var b = keys[i + 1]
		if value >= a and value <= b:
			var t = (value - a) / float(b - a)
			return color_map[a].lerp(color_map[b], t)

	return color_map[keys[0]]
