extends Node3D

@onready var railContainer: Node3D = $"../Ground/RailContainor"
@onready var sprite = $Sprite
@onready var tc_leftbutton = $"../UI/TouchScreen/Left"
@onready var tc_rightbutton = $"../UI/TouchScreen/Right"
var beatmap: Beatmap
var standRail: Node3D
var isJumping: bool = false
var jumpDuration: float = 0.3
var jumpDurationCurrent: float = 0.0
var jumpHeight: float = 0.3
var groundHeight: float
var groove: float = 0.2
var scaleVel
var groove_rst: float = 0.2
var default_dance_i = 0
var scene
var rails = []
var sprites_current = []
var sprites_current_index = 0
var sprites_current_update_time = 0
var sprites_current_update = 0

func _ready() -> void:
	await get_parent().ready
	beatmap = Game.select_map
	setPlayerIdle()
	playAnimation()
	scene = get_parent()
	groundHeight = position.y
	rails = railContainer.get_children()
	if rails.size() > 0:
		standRail = closest_rail()
	var texture_size = sprite.texture.get_size()
	var target_size = Vector2(200,Game.settings.playerheight)
	var scale_factor = Vector2(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)
	scale = Vector3(scale_factor.y, scale_factor.y, 1)
	var tex_size = sprite.texture.get_size()
	var world_height = tex_size.y * sprite.pixel_size
	sprite.position.y = world_height * scale_factor.y / (target_size.y / texture_size.y) / 2
	scaleVel = scale
func _process(delta: float) -> void:
	rails = railContainer.get_children()
	playAnimation()
	if standRail == null or !standRail.active:
		standRail = closest_rail()

	if groove < groove_rst:
		scale.y = scaleVel.y + (groove_rst - groove) / groove_rst / 6
		groove += delta
	else:
		scale = scaleVel
		pass

	if isJumping:
		jumpDurationCurrent -= delta
		if Input.is_action_just_pressed("move_down") or jumpDurationCurrent < 0:
			isJumping = false
		position.y = lerp(position.y, jumpHeight + groundHeight, delta * 20)
	else:
		position.y = lerp(position.y, groundHeight, delta * 20)

	if standRail != null:
		position.x = lerp(position.x, standRail.position.x, delta * 20)

		if Input.is_action_just_pressed("move_left"):
			scene.playerMove(2, standRail)
			standRail = move_rail(-1)
		if Input.is_action_just_pressed("move_right"):
			scene.playerMove(4, standRail)
			standRail = move_rail(1)
		if Input.is_action_just_pressed("move_up") and !isJumping:
			isJumping = true
			jumpDurationCurrent = jumpDuration
		if Input.is_action_just_pressed("action_1") or Input.is_action_just_pressed("action_2"):
			scene.playerAction()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch && standRail != null && event.pressed:
		if event.position.x > 1920 / 2:
			if event.position.x < 1550:
				scene.playerMove(2, standRail)
				standRail = move_rail(-1)
			else:
				scene.playerMove(4, standRail)
				standRail = move_rail(1)
func closest_rail() -> Node3D:
	if rails.is_empty():
		return standRail
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

func move_rail(direction: int) -> Node3D:
	if rails.is_empty():
		return standRail
	
	var current_x = standRail.position.x
	var c_rail = standRail
	var min_distance = INF
	for rail in rails:
		if (rail.position.x - current_x) * direction > 0 and rail.active:
			var distance = abs(rail.position.x - current_x)
			if distance < min_distance:
				min_distance = distance
				c_rail = rail
	return c_rail

func setPlayerIdle():
	setAnimation(beatmap.player_animation.get("idle", 0))

func setAnimation(id):
	for animation in beatmap.animations:
		if animation["id"] == id:
			sprites_current = animation["frames"]
			sprites_current_index = 0
			sprites_current_update = Game.currentTime
			sprites_current_update_time = 1000 / animation["fps"]

func getNextDefaultDance() -> int:
	var default_dances = beatmap.player_animation.get("defaultdance", [])
	if default_dances.is_empty():
		return 0

	if default_dance_i >= default_dances.size():
		default_dance_i = 0

	var id = default_dances[default_dance_i]
	default_dance_i += 1
	return id

func playAnimation():
	if sprites_current_update + sprites_current_update_time * (sprites_current_index + 1) < Game.currentTime:
		sprites_current_index += 1

	if sprites_current.size() > sprites_current_index:
		sprite.texture = sprites_current[sprites_current_index]
	else:
		setPlayerIdle()
