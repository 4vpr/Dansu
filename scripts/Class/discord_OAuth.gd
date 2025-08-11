extends Node

var discord_id: String = ""
var username: String = ""
var http_request: HTTPRequest
const SAVE_PATH = "user://user.json"

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

	load_login_info()
	if is_logged_in():
		print("User already logged in:", discord_id, username)
	else:
		print("User not logged in, fetching info from server...")
		fetch_user_info()

func login():
	OS.shell_open("http://127.0.0.1:5000/login")
	
	# 5초 후에 서버에 로그인 정보 다시 요청하는 타이머 실행 (사용자 인증 시간 고려)
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 5.0
	add_child(timer)
	timer.connect("timeout", Callable(self, "fetch_user_info"))
	timer.start()

func fetch_user_info():
	print("Requesting user info from server...")
	var url = "http://127.0.0.1:5000/get_user"
	http_request.request(url)

func _on_request_completed(result, response_code, headers, body):
	print("HTTP Request completed. Result:", result, "Code:", response_code)
	if response_code == 200:
		var json = JSON.new()
		var err = json.parse(body.get_string_from_utf8())
		if err == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
			var data = json.get_data()
			if data.has("discord_id") and data["discord_id"] != "":
				discord_id = data["discord_id"]
				username = data["username"]
				print("Discord login success! ID:", discord_id, "Username:", username)
				save_login_info()
			else:
				print("User not logged in (empty discord_id).")
		else:
			print("JSON parse error")
	else:
		print("Failed to get user info, HTTP code:", response_code)

func save_login_info():
	var data = {
		"discord_id": discord_id,
		"username": username
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Login info saved locally.")
	else:
		print("Failed to save login info.")

func load_login_info():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var err = json.parse(content)
		if err == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
			var data = json.get_data()
			discord_id = data.get("discord_id", "")
			username = data.get("username", "")
			if is_logged_in():
				print("Loaded saved login info:", discord_id, username)
			else:
				print("No valid login info found in file.")
		else:
			print("Login info JSON parse error or invalid format.")
	else:
		print("No saved login info file found.")

func is_logged_in() -> bool:
	return discord_id != ""

func logout():
	discord_id = ""
	username = ""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()
		print("Logged out and cleared saved login info.")
