extends Node

const API_BASE := "http://127.0.0.1:8000"

var access_token := ""
var refresh_token := ""
var user: Dictionary = {}

func _map_method(method: String) -> int:
	match method.to_upper():
		"POST":
			return HTTPClient.METHOD_POST
		"PUT":
			return HTTPClient.METHOD_PUT
		"PATCH":
			return HTTPClient.METHOD_PATCH
		"DELETE":
			return HTTPClient.METHOD_DELETE
		_:
			return HTTPClient.METHOD_GET

func request(method: String, path: String, payload: Variant = null, use_auth := false) -> Dictionary:
	var url := API_BASE + path
	var headers := PackedStringArray(["Content-Type: application/json"])
	if use_auth and access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)

	var body := ""
	if payload != null:
		body = JSON.stringify(payload)

	var http := HTTPRequest.new()
	add_child(http)

	var method_enum := _map_method(method)
	var err := http.request(url, headers, method_enum, body)
	if err != OK:
		push_error("HTTP request failed: %d" % err)
		http.queue_free()
		return {}

	var result: Array = await http.request_completed
	http.queue_free()

	var status_code: int = result[1]
	var text := (result[3] as PackedByteArray).get_string_from_utf8()

	if status_code >= 200 and status_code < 300:
		if text.is_empty():
			return {}
		return JSON.parse_string(text)

	push_warning("HTTP %s %s => %d" % [method, path, status_code])
	if text.is_empty():
		return {}
	return JSON.parse_string(text)
