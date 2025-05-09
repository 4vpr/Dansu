extends Node3D
@onready var railContainer: Node3D = $"../Ground/RailContainor"
@onready var sprite = $Sprite
var scene
var rails: Array = []
var standRail: Node3D # 플레이어가 서 있는 레일
var isJumping: bool = false
var jumpDuration: float = 0.3
var jumpDurationCurrent: float = 0
var jumpHeight: float = 0.3
var groundHeight: float
var groove = 0.2
var scaleVel
var groove_rst = 0.2
var user_dir = OS.get_user_data_dir()

var sprites = []
var sprites_current = []
var sprites_current_index
var sprites_current_update_time
var sprites_current_update
var player_animation = {}
var animations = []
var default_dance_i = 0

var rightPress:float = 0
var leftPress:float = 0
var PressInput:float = 0.1


func _groove():
	groove = 0

func _ready() -> void:
	await get_parent().ready
	setPlayerIdle()
	playAnimation()
	var texture_size = sprite.texture.get_size()
	var target_size = Vector2(200,Game.playerSize)
	var scale_factor = Vector2(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)
	scale = Vector3(scale_factor.y, scale_factor.y, 1)
	var tex_size = sprite.texture.get_size()
	var world_height = tex_size.y * sprite.pixel_size
	sprite.position.y = world_height * scale_factor.y / (target_size.y / texture_size.y) / 2
	scene = get_parent()
	groundHeight = position.y
	rails = railContainer.get_children()
	if rails.size() > 0:
		standRail = closest_rail()

	scaleVel = scale

var texture_cache = {} # 파일명을 키로, Texture2D를 값으로 저장
func get_texture(file_name):
	if file_name in texture_cache:
		return texture_cache[file_name] # 캐싱된 텍스처 반환
	var texture_path = user_dir.path_join("Songs/" + Game.select_folder + "/sprite/" + file_name)
	var image = Image.new()
	if image.load(texture_path) == OK:
		var texture = ImageTexture.create_from_image(image)
		texture_cache[file_name] = texture
		return texture
func parse_data(json_data):
	if "animations" in json_data:
		for animation in json_data["animations"]:
			var frames = animation.get("frames", []) 
			var texture_frames = []
			# 캐싱된 Texture2D 가져오기
			for frame in frames:
				var texture = get_texture(frame)
				if texture:
					texture_frames.append(texture)
					animations.append({
				"id": animation.get("id", -1),
				"frames": texture_frames,
				"fps": animation.get("fps", 1),
				"effect": animation.get("effect", "none")
				})
	if "player" in json_data:
		var animation = json_data["player"]
		player_animation = {
			"idle": animation.get("idle", 0),
			"left": animation.get("left", 0),
			"right": animation.get("right", 0),
			"jump": animation.get("jump", 0),
			"land": animation.get("land", 0),
			"defaultdance": animation.get("defaultdance", []
			)}

func _process(delta: float) -> void:
	playAnimation()
	rails = railContainer.get_children()
	if standRail == null:
		standRail = closest_rail()
	elif standRail.active == false:
		standRail = closest_rail()
	
	if groove < groove_rst:
		scale.y = scaleVel.y + (groove_rst - groove) / groove_rst / 6
		groove += delta
	else:
		scale = scaleVel
	
	#점프 구현부$"
	if isJumping:
		jumpDurationCurrent -= delta
		if Input.is_action_just_pressed("move_down") || jumpDurationCurrent < 0:
			isJumping = false
		position.y = lerp(position.y, jumpHeight + groundHeight, delta * 20)
	else:
		position.y = lerp(position.y, groundHeight, delta * 20)

	#이동 구현부

	if standRail != null:
		position.x = lerp(position.x, standRail.position.x, delta * 20)
		if Input.is_action_pressed("move_right"):
			#rightPress += delta
			pass
		else:
			rightPress = 0
		if Input.is_action_pressed("move_left"):
			#leftPress += delta
			pass
		else:
			leftPress = 0
		if Input.is_action_just_pressed("move_left") || leftPress > PressInput:
			leftPress = 0
			scene.playerMove(2, standRail)
			standRail = move_rail(-1)
		if Input.is_action_just_pressed("move_right") || rightPress > PressInput:
			rightPress = 0
			scene.playerMove(4, standRail)
			standRail = move_rail(1)
		if Input.is_action_just_pressed("move_up") && !isJumping:
			isJumping = true
			jumpDurationCurrent = jumpDuration
		if Input.is_action_just_pressed("action_1") || Input.is_action_just_pressed("action_2"):
			scene.playerAction()

#가장 가까운 레일로 이동
func closest_rail() -> Node3D:
	if rails.size() == 0:
		return standRail
	var current_x = position.x
	var c_rail = null
	var min_distance = INF
	for rail in rails:
		if rail.active:
			var distance = abs(rail.position.x - current_x)
			if distance < min_distance:
				min_distance = distance
				c_rail = rail
	return c_rail
	

#이동방향에서 가장 가까운 레일 찾기
func move_rail(direction: int) -> Node3D:
	if rails.size() == 0:
		return standRail
	var current_x = standRail.position.x
	var closest_rail = standRail
	var min_distance = INF

	for rail in rails:
		if (rail.position.x - current_x) * direction > 0 && rail.active:
			var distance = abs(rail.position.x - current_x)
			if distance < min_distance:
				min_distance = distance
				closest_rail = rail
	return closest_rail


#애니메이션 구현부
func getNextDefaultDance() -> int:
	var id = 0
	if default_dance_i >= player_animation.get("defaultdance").size():
		id = player_animation.get("defaultdance")[0]
		default_dance_i = 0
	else:
		id = player_animation.get("defaultdance")[default_dance_i]
	default_dance_i += 1
	return id
func setPlayerIdle():
	setAnimation(player_animation.get("idle"))
func setAnimation(id):
	for animation in animations:
		_groove()
		if animation["id"] == id :
				sprites_current = animation["frames"]
				sprites_current_index = 0
				sprites_current_update = Game.currentTime
				sprites_current_update_time = 1000 / animation["fps"]
func playAnimation():
	if sprites_current_update + sprites_current_update_time * (sprites_current_index + 1) < Game.currentTime:
		sprites_current_index += 1
	if sprites_current.size() > sprites_current_index:
		sprite.texture = sprites_current[sprites_current_index]
	else:
		setPlayerIdle()
