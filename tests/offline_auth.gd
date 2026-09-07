extends Node
signal state_changed
var user := {}
var status_message := "Test offline"
var signed_in := false
var login_count := 0
func is_authenticated() -> bool:
	return signed_in
func is_admin() -> bool:
	return signed_in and (int(user.get("groups", 0)) & (1 << 1)) != 0
func is_busy() -> bool:
	return false
func is_username_setup_pending() -> bool:
	return false
func is_username_setup_submitting() -> bool:
	return false
func submit_username(_value: String) -> void:
	pass
func login() -> void:
	login_count += 1
func logout() -> void:
	signed_in = false
	state_changed.emit()
func authorization_headers() -> PackedStringArray:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://test-server.json"))
	return PackedStringArray(["Authorization: Bearer " + str(data.token)]) if signed_in else PackedStringArray()
func apply_score_submission(response: Dictionary) -> void:
	if not signed_in or not response.has("sr_total"):
		return
	var stats: Dictionary = user.get("stats", {}).duplicate(true)
	stats["sr_total"] = float(response.sr_total)
	user["stats"] = stats
	state_changed.emit()
