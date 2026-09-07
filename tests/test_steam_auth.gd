extends SceneTree
## Run through run_steam_auth_tests.ps1; the runner supplies an isolated Config autoload.

class TestAuth extends SteamAuthManager:
	var test_url := "http://127.0.0.1:1/api/v1"
	func _api_url() -> String:
		return test_url
	func _request_user_profile(attempt: int) -> void:
		state = State.SIGNING_IN

class FakeSteam extends RefCounted:
	var cancelled: Array[int] = []
	var identity := ""
	var next_handle := 100
	func loggedOn() -> bool:
		return true
	func getAuthTicketForWebApi(value: String) -> int:
		identity = value
		next_handle += 1
		return next_handle
	func cancelAuthTicket(handle: int) -> void:
		cancelled.append(handle)
	func run_callbacks() -> void:
		pass

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var username_pattern := RegEx.new()
	check(username_pattern.compile("^[A-Za-z][A-Za-z0-9_]{2,23}$") == OK, "Username pattern compiles")
	check(username_pattern.search("댄수유저") == null, "Username pattern rejects non-ASCII letters")
	var auth := TestAuth.new()
	var steam := FakeSteam.new()
	auth._steam = steam
	auth._steam_initialized = true
	root.add_child(auth)
	await process_frame
	check(auth.state == auth.State.OFFLINE, "Authentication waits for chart loading")
	auth.login()
	check(auth.state == auth.State.REQUESTING_TICKET, "Loading flow requests a ticket")
	check(steam.identity == "dansuapi", "Server identity matches")
	var handle: int = auth._ticket_handle
	auth.login()
	check(auth._ticket_handle == handle, "Duplicate login is ignored")
	auth._on_web_api_ticket(handle - 1, 1, 2, PackedByteArray([170, 187]))
	check(auth.state == auth.State.REQUESTING_TICKET, "Stale ticket is ignored")
	auth._on_web_api_ticket(handle, 1, 3, PackedByteArray([170, 187]))
	check(auth.state == auth.State.ERROR, "Invalid ticket size fails")
	check(steam.cancelled.has(handle), "Failed ticket is cancelled")
	auth.login()
	auth._ticket_deadline_msec = 0
	auth._process(0)
	check(auth.state == auth.State.ERROR, "Ticket timeout fails")
	auth.login()
	auth._on_web_api_ticket(auth._ticket_handle, 1, 2, PackedByteArray([170, 187, 204]))
	check(auth.state == auth.State.SIGNING_IN, "Valid ticket starts HTTP exchange")
	check(auth._request.max_redirects == 0, "Ticket request cannot follow redirects")
	var attempt: int = auth._attempt
	var response := JSON.stringify({
		"access_token": "test-jwt", "token_type": "bearer", "expires_in": 3600,
		"user": {"id": 1, "steam_persona_name": "Test player"},
		"username_required": false,
	}).to_utf8_buffer()
	auth._on_token_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), response, attempt)
	check(auth.state == auth.State.SIGNING_IN, "Player profile is loaded before sign-in completes")
	var profile_response := JSON.stringify({
		"id": 1,
		"username": "test-player",
		"steam_persona_name": "Test player",
		"avatar_url": "https://example.invalid/avatar.jpg",
		"groups": 2,
		"stats": {"sr_total": 30.5},
		"rank": 35,
	}).to_utf8_buffer()
	auth._on_profile_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), profile_response, attempt)
	check(auth.is_authenticated(), "Successful response authenticates")
	check(auth.user.get("steam_persona_name") == "Test player", "Profile is exposed")
	check(auth.user.get("stats", {}).get("sr_total") == 30.5, "Player rating is exposed")
	check(auth.user.get("rank") == 35, "Player rank is exposed")
	check(auth.is_admin(), "Admin group is exposed")
	check(auth.authorization_headers() == PackedStringArray(["Authorization: Bearer test-jwt"]), "JWT header")
	auth.logout()
	auth.login()
	attempt = auth._attempt
	var first_login_response := JSON.stringify({
		"access_token": "first-login-jwt", "token_type": "bearer", "expires_in": 3600,
		"user": {"id": 1, "username": "76561198000000001", "steam_persona_name": "Test player"},
		"username_required": true,
	}).to_utf8_buffer()
	auth.state = auth.State.SIGNING_IN
	auth._on_token_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), first_login_response, attempt)
	auth._on_profile_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), profile_response, attempt)
	check(auth.is_username_setup_pending(), "First login waits for username setup")
	check(not auth.authorization_headers().is_empty(), "Setup request can use the issued JWT")
	auth.submit_username("New_Player")
	check(auth.is_username_setup_submitting(), "Username submission starts")
	var username_response := JSON.stringify({
		"id": 1,
		"username": "New_Player",
		"steam_persona_name": "Test player",
		"avatar_url": "https://example.invalid/avatar.jpg",
	}).to_utf8_buffer()
	auth._on_username_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), username_response, attempt)
	check(auth.is_authenticated(), "Username setup completes sign-in")
	check(auth.user.get("username") == "New_Player", "Chosen username is exposed")
	auth._expires_at_msec = 0
	check(auth.authorization_headers().is_empty(), "Expired JWT is never returned")
	auth._process(0)
	check(auth.state == auth.State.OFFLINE and auth.user.is_empty(), "Expiry clears profile")
	auth.login()
	auth.state = auth.State.SIGNING_IN
	auth._on_token_response(HTTPRequest.RESULT_SUCCESS, 403, PackedStringArray(), response, auth._attempt)
	check(auth.state == auth.State.ERROR and auth.authorization_headers().is_empty(), "Banned response fails")
	auth.login()
	auth.state = auth.State.SIGNING_IN
	auth._on_token_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "{}".to_utf8_buffer(), auth._attempt)
	check(auth.state == auth.State.ERROR, "Malformed response fails")
	auth.login()
	attempt = auth._attempt
	auth.logout()
	auth._on_token_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), response, attempt)
	check(auth.state == auth.State.OFFLINE, "Logout invalidates old HTTP responses")
	auth.login()
	auth.test_url = "http://localhost:9999/api/v1"
	auth._process(0)
	check(auth.state == auth.State.OFFLINE, "Server change cancels login")
	check(not auth._valid_api_url("http://example.com/api/v1"), "Remote HTTP is rejected")
	check(not auth._valid_api_url("http://localhost.evil.test/api/v1"), "Loopback lookalike is rejected")
	auth.queue_free()
	await process_frame
	print("Steam auth checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
