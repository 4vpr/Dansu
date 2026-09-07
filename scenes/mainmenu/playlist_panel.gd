extends Control
class_name PlaylistPanel

signal visibility_set(blocked: bool)
signal chartset_chosen(metadata: Dictionary)

@export var close_button: Button
@export var playlist_select: OptionButton
@export var add_button: Button
@export var remove_button: Button
@export var delete_button: Button
@export var share_button: Button
@export var name_input: LineEdit
@export var create_button: Button
@export var share_code_input: LineEdit
@export var open_shared_button: Button
@export var status_label: Label
@export var items: ItemList
@export var request: HTTPRequest

var _playlists: Array[Dictionary] = []
var _item_metadata: Array[Dictionary] = []
var _current_chartset: Dictionary = {}
var _current_playlist: Dictionary = {}
var _operation := ""
var _shared_view := false


func _ready() -> void:
	close_button.pressed.connect(close)
	playlist_select.item_selected.connect(_select_playlist)
	add_button.pressed.connect(_add_current_chartset)
	remove_button.pressed.connect(_remove_selected_chartset)
	delete_button.pressed.connect(_delete_playlist)
	share_button.pressed.connect(_share_playlist)
	create_button.pressed.connect(_create_playlist)
	name_input.text_submitted.connect(func(_value: String): _create_playlist())
	open_shared_button.pressed.connect(_open_shared_playlist)
	share_code_input.text_submitted.connect(func(_value: String): _open_shared_playlist())
	items.item_selected.connect(func(_index: int): _update_controls())
	items.item_activated.connect(_activate_item)
	visibility_changed.connect(func(): visibility_set.emit(visible))
	_update_controls()


func open(chartset_metadata: Dictionary = {}) -> void:
	if not Auth.is_authenticated():
		Notification.notice("Sign in to use playlists.", Notification.Type.WARNING)
		return
	_current_chartset = chartset_metadata.duplicate(true)
	visible = true
	_request_playlists()


func close() -> void:
	if not visible:
		return
	request.cancel_request()
	_operation = ""
	visible = false


func is_open() -> bool:
	return visible


func _request_playlists(select_id: int = 0) -> void:
	if not _send("list:" + str(select_id), "/playlists"):
		return
	status_label.text = "Loading playlists…"


func _select_playlist(index: int) -> void:
	if index < 0 or index >= _playlists.size():
		return
	_shared_view = false
	_current_playlist = _playlists[index]
	if str(_current_playlist.get("kind", "")) == "recent":
		if _send("recent", "/plays/recent?limit=200"):
			status_label.text = "Loading recent plays…"
		return
	_request_detail(int(_current_playlist.get("id", 0)))


func _request_detail(playlist_id: int) -> void:
	if playlist_id <= 0 or not _send("detail", "/playlists/%d?limit=100" % playlist_id):
		return
	status_label.text = "Loading songs…"


func _create_playlist() -> void:
	var playlist_name := name_input.text.strip_edges()
	if playlist_name.is_empty():
		status_label.text = "Enter a playlist name."
		return
	if _send("create", "/playlists", HTTPClient.METHOD_POST, {"name": playlist_name}):
		status_label.text = "Creating playlist…"


func _delete_playlist() -> void:
	var playlist_id := int(_current_playlist.get("id", 0))
	if playlist_id > 0 and _send("delete", "/playlists/" + str(playlist_id), HTTPClient.METHOD_DELETE):
		status_label.text = "Deleting playlist…"


func _add_current_chartset() -> void:
	var playlist_id := int(_current_playlist.get("id", 0))
	var chartset_id := int(_current_chartset.get("id", 0))
	if playlist_id <= 0 or chartset_id <= 0:
		return
	if _send(
		"add",
		"/playlists/%d/chartsets/%d" % [playlist_id, chartset_id],
		HTTPClient.METHOD_PUT
	):
		status_label.text = "Adding song…"


func _remove_selected_chartset() -> void:
	var selected := items.get_selected_items()
	if selected.is_empty():
		return
	var index := selected[0]
	if index < 0 or index >= _item_metadata.size():
		return
	var playlist_id := int(_current_playlist.get("id", 0))
	var chartset_id := int(_item_metadata[index].get("id", 0))
	if playlist_id > 0 and chartset_id > 0 and _send(
		"remove",
		"/playlists/%d/chartsets/%d" % [playlist_id, chartset_id],
		HTTPClient.METHOD_DELETE
	):
		status_label.text = "Removing song…"


func _share_playlist() -> void:
	var playlist_id := int(_current_playlist.get("id", 0))
	if playlist_id <= 0:
		return
	if _send(
		"share",
		"/playlists/" + str(playlist_id),
		HTTPClient.METHOD_PATCH,
		{"visibility": "unlisted"}
	):
		status_label.text = "Creating share code…"


func _open_shared_playlist() -> void:
	var code := share_code_input.text.strip_edges()
	if code.is_empty():
		return
	if _send("shared", "/playlists/shared/" + code.uri_encode() + "?limit=100", HTTPClient.METHOD_GET, {}, false):
		status_label.text = "Opening shared playlist…"


func _activate_item(index: int) -> void:
	if index < 0 or index >= _item_metadata.size():
		return
	chartset_chosen.emit(_item_metadata[index].duplicate(true))
	close()


func _send(
	operation: String,
	path: String,
	method: HTTPClient.Method = HTTPClient.METHOD_GET,
	body: Dictionary = {},
	authorized: bool = true
) -> bool:
	if not _operation.is_empty():
		return false
	_operation = operation
	var headers: PackedStringArray = Auth.authorization_headers() if authorized else PackedStringArray()
	var content := ""
	if not body.is_empty():
		headers.append("Content-Type: application/json")
		content = JSON.stringify(body)
	var error := request.request(ServerURLs.api(path), headers, method, content)
	if error != OK:
		_operation = ""
		status_label.text = "Could not start the request."
		_update_controls()
		return false
	_update_controls()
	return true


func _on_request_completed(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var operation := _operation
	_operation = ""
	var data = JSON.parse_string(body.get_string_from_utf8()) if not body.is_empty() else null
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		status_label.text = "Request failed. Check your connection and retry."
		_update_controls()
		return
	match operation.get_slice(":", 0):
		"list": _show_playlist_list(data, int(operation.get_slice(":", 1)))
		"detail", "shared": _show_playlist_detail(data, operation == "shared")
		"recent": _show_recent_plays(data)
		"create":
			name_input.clear()
			_request_playlists(int(data.get("id", 0)) if data is Dictionary else 0)
		"delete":
			_current_playlist.clear()
			_request_playlists()
		"add", "remove": _request_detail(int(_current_playlist.get("id", 0)))
		"share": _share_completed(data)
	_update_controls()


func _show_playlist_list(data, select_id: int) -> void:
	if not data is Array:
		status_label.text = "The server returned an invalid playlist list."
		return
	_playlists.clear()
	playlist_select.clear()
	_playlists.append({"id": -1, "name": "Recent Plays", "kind": "recent", "item_count": 0})
	playlist_select.add_item("Recent Plays")
	for entry in data:
		if not entry is Dictionary:
			continue
		_playlists.append(entry)
		playlist_select.add_item("%s (%d)" % [str(entry.get("name", "Playlist")), int(entry.get("item_count", 0))])
	if _playlists.is_empty():
		_current_playlist.clear()
		_show_items([])
		status_label.text = "No playlists."
		return
	var index := 0
	for candidate in _playlists.size():
		var matches_default := select_id <= 0 and str(_playlists[candidate].get("kind", "")) == "loved"
		if matches_default or int(_playlists[candidate].get("id", 0)) == select_id:
			index = candidate
			break
	playlist_select.select(index)
	_select_playlist(index)


func _show_recent_plays(data) -> void:
	if not data is Array:
		status_label.text = "The server returned invalid play history."
		return
	var metadata: Array[Dictionary] = []
	for entry in data:
		if entry is Dictionary and entry.get("chartset") is Dictionary:
			metadata.append(entry.chartset)
	_show_items(metadata)
	status_label.text = "Recent Plays · %d songs" % metadata.size()


func _show_playlist_detail(data, shared: bool) -> void:
	if not data is Dictionary or not data.get("items") is Array:
		status_label.text = "The server returned an invalid playlist."
		return
	_shared_view = shared
	_current_playlist = data
	var metadata: Array[Dictionary] = []
	for entry in data.items:
		if entry is Dictionary and entry.get("chartset") is Dictionary:
			metadata.append(entry.chartset)
	_show_items(metadata)
	status_label.text = "%s · %d songs%s" % [
		str(data.get("name", "Playlist")),
		metadata.size(),
		" · shared" if shared else "",
	]


func _show_items(metadata: Array[Dictionary]) -> void:
	_item_metadata = metadata
	items.clear()
	for chartset in metadata:
		var title := "Untitled"
		var artist := ""
		var charts = chartset.get("charts", [])
		if charts is Array and not charts.is_empty() and charts[0] is Dictionary:
			title = str(charts[0].get("title", title))
			artist = str(charts[0].get("artist", ""))
		items.add_item(title if artist.is_empty() else "%s  —  %s" % [title, artist])
	_update_controls()


func _share_completed(data) -> void:
	if not data is Dictionary:
		status_label.text = "The server returned an invalid share code."
		return
	_current_playlist = data
	var code := str(data.get("share_code", ""))
	if code.is_empty():
		status_label.text = "The playlist could not be shared."
		return
	share_code_input.text = code
	DisplayServer.clipboard_set(code)
	status_label.text = "Share code copied to clipboard."
	Notification.notice("Playlist share code copied.")


func _update_controls() -> void:
	var busy := not _operation.is_empty()
	var owned := not _shared_view and int(_current_playlist.get("id", 0)) > 0
	var custom := owned and str(_current_playlist.get("kind", "")) == "custom"
	playlist_select.disabled = busy
	create_button.disabled = busy
	open_shared_button.disabled = busy
	add_button.disabled = busy or not owned or int(_current_chartset.get("id", 0)) <= 0
	remove_button.disabled = busy or not owned or items.get_selected_items().is_empty()
	delete_button.disabled = busy or not custom
	share_button.disabled = busy or not custom


func _exit_tree() -> void:
	request.cancel_request()
