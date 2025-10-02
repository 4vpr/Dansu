extends Node3D

@onready var railContainer: Node3D = $"../Ground/RailContainor"
@onready var sprite = $Sprite

var chart
var stand_rail: Node3D
# 점프관련 , 안씀
var is_jumping: bool = false
var jump_duration: float = 0.3
var jump_duration_current: float = 0.0
var jump_height: float = 0.3
var ground_height: float

# 기본 애니메이션 효과
var groove: float = 0.2
var scale_value
var groove_rst: float = 0.2

var default_dance_i = 0 # 기본 춤 재생 인덱스
var scene
var rails = []
var sprites_current = [] # 재생중인 스프라이트 목록
var sprites_current_index = 0 # 재생중인 스프라이트 현재 인덱스
var sprites_current_update_time = 0 # 재생중인 스프라이트 다음 업데이트 시간
var sprites_current_update = 0 # 재생중인 스프라이트 업데이트

func _ready() -> void:
	await get_parent().ready
	chart = CM.sc
	if chart.use_default_skin:
		chart = Game._use_default_skin()
	set_idle()
	play_animation()
	scene = get_parent()
	ground_height = position.y
	rails = railContainer.get_children()
	if rails.size() > 0:
		stand_rail = closest_rail()
	var texture_size = sprite.texture.get_size()
	var target_size = Vector2(200,Game.settings["gameplay"]["playerheight"])
	var scale_factor = Vector2(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)
	scale = Vector3(scale_factor.y, scale_factor.y, 1)
	var tex_size = sprite.texture.get_size()
	var world_height = tex_size.y * sprite.pixel_size
	sprite.position.y = world_height * scale_factor.y / (target_size.y / texture_size.y) / 2
	scale_value = scale

func reset() -> void:
	default_dance_i = 0
	set_idle()
	rails = []
	position.x = 0
	stand_rail = null
	pass

func _process(delta: float) -> void:
	rails = railContainer.get_children()
	play_animation()
	if stand_rail == null or !stand_rail.active:
		stand_rail = closest_rail()

	if groove < groove_rst:
		scale.y = scale_value.y + (groove_rst - groove) / groove_rst / 6 * scale_value.y
		groove += delta
	else:
		scale = scale_value
		pass
	if is_jumping:
		jump_duration_current -= delta
		if Input.is_action_just_pressed("move_down") or jump_duration_current < 0:
			is_jumping = false
		position.y = lerp(position.y, jump_height + ground_height, delta * 20)
	else:
		position.y = lerp(position.y, ground_height, delta * 20)
	if stand_rail != null:
		position.x = lerp(position.x, stand_rail.position.x, delta * 20)

func closest_rail() -> Node3D:
	if rails.is_empty():
		return stand_rail
	var current_x = position.x
	var c_rail
	var min_distance = INF
	for rail in rails:
		if rail.active:
			var distance = abs(rail.position.x - current_x)
			if distance < min_distance:
				min_distance = distance
				c_rail = rail
	return c_rail

func move(direction: int):
	stand_rail = move_rail(direction)

func move_rail(direction: int) -> Node3D:
	if rails.is_empty():
		return stand_rail
	if stand_rail != null:
		var current_x = stand_rail.position.x
		var c_rail = stand_rail
		var min_distance = INF
		for rail in rails:
			if (rail.position.x - current_x) * direction > 0 and rail.active:
				var distance = abs(rail.position.x - current_x)
				if distance < min_distance:
					min_distance = distance
					c_rail = rail
		return c_rail
	return stand_rail

func set_idle():
	set_animation(chart.player_animation.get("idle", 0))

func set_animation(id):
	for animation in chart.animations:
		if animation["id"] == id:
			sprites_current = animation["frames"]
			sprites_current_index = 0
			sprites_current_update = Game.currentTime
			sprites_current_update_time = 1000 / animation["fps"]

func next_default_dance() -> int:
	var default_dances = chart.player_animation.get("defaultdance", [])
	if default_dances.is_empty():
		return 0

	if default_dance_i >= default_dances.size():
		default_dance_i = 0

	var id = default_dances[default_dance_i]
	default_dance_i += 1
	return id

func play_animation():
	if sprites_current_update + sprites_current_update_time * (sprites_current_index + 1) < Game.currentTime:
		sprites_current_index += 1
	
	if sprites_current.size() > sprites_current_index:
		sprite.texture = sprites_current[sprites_current_index]
	else:
		set_idle()
