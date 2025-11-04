extends Node

func register(name: String, password: String, email := "") -> Dictionary:
	var payload := {
		"name": name,
		"password": password,
		"email": email if email != "" else null,
		"country": OS.get_locale()
	}
	return await api._request_json("POST", "/users/", payload)

func login(name: String, password: String) -> bool:
	var payload := {"name": name, "password": password}
	var response := await api.request("POST", "/users/auth/login", payload)
	if response.has("access_token"):
		api.access_token = response["access_token"]
		api.refresh_token = response.get("refresh_token", "")
		api.user = response.get("user", {})
		return true
	return false

func refresh() -> bool:
	if api.refresh_token == "":
		return false
	var payload := {"refresh_token": api.refresh_token}
	var response := await api.request("POST", "/users/auth/refresh", payload)
	if response.has("access_token"):
		api.access_token = response["access_token"]
		api.refresh_token = response.get("refresh_token", api.refresh_token)
		api.user = response.get("user", api.user)
		return true
	return false

func me() -> Dictionary:
	if api.access_token == "":
		return {}
	var response := await api.request("GET", "/users/me", null, true)
	if response.has("id"):
		api.user = response
	return response

func logout():
	await api.request("POST","/users/logout",null,true)
	api.access_token = ""
	api.refresh_token = ""
	api.user = {}
