extends ScoreManager

func _api_url(path: String) -> String:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://test-server.json"))
	return str(data.origin) + "/api/v1" + path
