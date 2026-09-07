extends Node

var root: Window:
	get: return get_tree().root
var process_frame: Signal:
	get: return get_tree().process_frame

func create_timer(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(seconds)

static func server() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://test-server.json"))

class TestCatalogue extends ChartCatalogue:
	var capture_redirect := false
	var redirect_url := ""
	var redirect_headers := PackedStringArray()
	func _start_download(url: String, headers: PackedStringArray) -> void:
		if capture_redirect:
			redirect_url = url
			redirect_headers = headers
		else:
			super._start_download(url, headers)
	func _api_url(path: String) -> String:
		return _origin() + "/api/v1" + path
	func _resource_url(path: String) -> String:
		return _origin() + path
	static func _origin() -> String:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://test-server.json"))
		return str(data.origin)

class TestPublisher extends ChartPublisher:
	func _api_url(path: String) -> String:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://test-server.json"))
		return str(data.origin) + "/api/v1" + path

var failures := 0
var checks := 0

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func until(condition: Callable, seconds: float = 10.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return condition.call()

func _run() -> void:
	var packaged_chartsets := FileSystem.packaged_chartsets()
	check(packaged_chartsets.get("62496c1b-8a1c-b42c-c9b2-9613baba2779") == "Oshama Scramble", "Built-in chartsets load from JSON")
	check(ServerURLs.BASE_URL == "https://dansu.h4ya.net", "Production origin is fixed")
	check(ServerURLs.api("/auth/steam/token") == "https://dansu.h4ya.net/api/v1/auth/steam/token", "Auth URL")
	check(ServerURLs.resolve("/res/chartsets/1/preview.mp3") == "https://dansu.h4ya.net/res/chartsets/1/preview.mp3", "Resource path avoids API prefix")
	for path in ["//evil.test/a", "https://dansu.h4ya.net.evil.test/a", "/\\evil.test/a"]:
		check(ServerURLs.resolve(path).is_empty(), "Reject foreign URL " + path)
	check(ServerURLs.query({"q": "a & 미쿠", "reverse": false}).contains("reverse=false"), "Boolean query values")
	for path in ["../escape", "a/../../escape", "C:/evil", "/absolute", "a\\b", "CON.txt", "a/../b"]:
		check(not ChartPackageInstaller.safe_relative(path), "Reject unsafe package path " + path)
	check(ChartPackageInstaller.download_folder_name({"id": 42, "charts": [{"title": "Test Song"}]}) == "[42] Test Song", "Downloaded chartset folder uses its id and title")
	var chart := Chart.new()
	chart.rating = 10
	chart.play_time_ms = 60000
	chart.play_count = 1
	check(SongFilters.matches_local(chart, {"min_rating": 10, "max_length_ms": 60000, "played": true}), "Inclusive local filter bounds")
	check(not SongFilters.matches_local(chart, {"max_rating": 9}), "Local difficulty exclusion")
	check(not SongFilters.matches_local(chart, {"played": false}), "Local history exclusion")
	DirAccess.make_dir_recursive_absolute("user://charts/upload-fixture")
	for file in DirAccess.get_files_at("res://test-fixture"):
		DirAccess.copy_absolute(ProjectSettings.globalize_path("res://test-fixture/" + file), ProjectSettings.globalize_path("user://charts/upload-fixture/" + file))
	var scene: PackedScene = load("res://scenes/mainmenu/mainmenu.tscn")
	var menu := scene.instantiate() as DansuMainMenu
	var catalogue := menu.get_node("Catalogue") as ChartCatalogue
	var publisher_node := menu.get_node("Publisher") as ChartPublisher
	catalogue.set_script(TestCatalogue)
	publisher_node.set_script(TestPublisher)
	catalogue.preview_player = catalogue.get_node("PreviewPlayer")
	catalogue.search_debounce = catalogue.get_node("SearchDebounce")
	publisher_node.dialog = publisher_node.get_node("PublishDialog")
	root.add_child(menu)
	check(menu._filter_popup == menu.get_node("SongFilterPopup"), "Filter popup is pre-placed in the scene")
	check(not menu.has_node("Charts/CatalogueBar"), "Browse count and refresh controls are omitted")
	check(menu._publisher.dialog == menu.get_node("Publisher/PublishDialog"), "Publish dialog is pre-placed in the scene")
	check(menu.chart_info_panel.shine_rect == menu.get_node("ChartInfo/Panel/Shine"), "ChartInfo shine is pre-placed in the scene")
	check(menu.get_node("AccountPanel/Layer/Margin/Content/AvatarFrame/Avatar") is TextureRect, "Account controls are pre-placed in the scene")
	check(await until(func(): return root.get_node("Game").stage == 1), "Local library loading completes")
	check(root.get_node("Auth").login_count == 1, "Sign-in starts after chart loading")
	check(not menu.browse_button.visible, "Browse is hidden while offline")
	check(not menu.account_panel.visible, "Account panel is hidden while offline")
	await menu.begin_song_select(false)
	check(menu.chart_scroll.visible_items.size() == 1, "Existing local list is populated")
	check(not menu._publish_button.visible, "Upload is hidden outside Edit mode")
	check(menu._publish_button.get_parent() == menu.get_node("ChartInfo"), "Upload is pre-placed in ChartInfo")
	menu._apply_song_select_mode(true)
	check(menu._publish_button.visible, "Upload is visible in Edit mode")
	check(menu._publish_button.size.is_equal_approx(menu.new_difficulty_button.size), "Upload matches New Difficulty size")
	check(menu._publish_button.position.y < menu.new_difficulty_button.position.y, "Upload is above New Difficulty")
	menu._apply_song_select_mode(false)
	check(menu.filter_button.text == "Filter", "Search button is Filter")
	menu._show_filters()
	await create_timer(0.3).timeout
	check(menu._filter_popup.visible and menu.chart_scroll.input_blocked, "Filter modal blocks chart scrolling")
	menu._filter_popup._fields.max_length_ms.text = "0.5"
	menu._filter_popup._apply()
	await create_timer(0.2).timeout
	check(menu.chart_scroll.visible_items.is_empty(), "Applying duration filter changes the real local list")
	menu._on_filters_applied(SongFilters.defaults(false))
	check(menu.chart_scroll.visible_items.size() == 1, "Reset restores local songs")
	await menu.return_to_main_menu()
	await menu.begin_song_select(false, true)
	check(await until(func(): return not menu._catalogue.loading), "Online search finishes")
	check(menu.chart_scroll.visible_items.size() == 20, "Browse loads the first result batch")
	if menu.chart_scroll.visible_items.is_empty():
		print(menu._catalogue.status)
		_finish(menu)
		return
	var online: ChartSet = menu.chart_scroll.visible_items[0].chartset
	check(online.charts.size() == 2, "Every online difficulty is mapped")
	check(menu.bottom_play_button.button_text == "Download", "Uninstalled set shows Download")
	check(await until(func(): return online.charts[0].cover_image != null), "Cover loads from resource endpoint")
	check(online.charts[0].cover_image.get_width() == 256, "Catalogue list uses the 256px cover")
	check(await until(func(): return online.charts[0].detail_cover_image != null), "Selected cover loads from the detail resource")
	check(online.charts[0].detail_cover_image.get_width() == 1024, "Selected cover uses the 1024px resource")
	check(menu.chart_info_panel.thumb.texture == online.charts[0].detail_cover_image, "ChartInfo displays the detail cover")
	check(await until(func(): return menu._catalogue.preview_player.playing), "Selection plays a real MP3 preview")
	var insert_request := HTTPRequest.new()
	root.add_child(insert_request)
	insert_request.request(str(server().origin) + "/__test/insert-chartset", PackedStringArray(), HTTPClient.METHOD_POST)
	await insert_request.request_completed
	insert_request.queue_free()
	menu.chart_scroll.target_scroll = float(menu.chart_scroll.data_count - 5) * menu.chart_scroll.step
	menu.chart_scroll._request_more_if_near_end()
	check(await until(func(): return menu._catalogue.page == 2 and not menu._catalogue.loading), "Scrolling near the end loads the next page")
	var loaded_uuids := {}
	for item in menu.chart_scroll.visible_items:
		loaded_uuids[item.chartset.uuid] = true
	check(menu.chart_scroll.visible_items.size() == 25, "Infinite scroll appends unique results")
	check(loaded_uuids.size() == menu.chart_scroll.visible_items.size(), "Items repeated after a page-boundary update are hidden")
	check(menu.chart_scroll.target_scroll > 0.0, "Appending a page preserves the scroll position")
	var browse_scroll_before_rescan: float = menu.chart_scroll.target_scroll
	var browse_selection_before_rescan: Chart = root.get_node("CM").selected_chart
	menu.chart_scroll._on_chart_update([])
	check(is_equal_approx(menu.chart_scroll.target_scroll, browse_scroll_before_rescan), "Local rescans do not move the Browse scroll")
	check(root.get_node("CM").selected_chart == browse_selection_before_rescan, "Local rescans do not replace the Browse selection")
	menu._on_search_text_changed("no such song")
	menu._on_search_text_changed("Online test song")
	check(await until(func(): return not menu._catalogue.loading), "Debounced search finishes")
	check(menu.chart_scroll.visible_items.size() == 1, "Latest search wins")
	menu._catalogue.set_filters({"sort": "newest", "played": true})
	check(menu._catalogue.status.contains("Sign in"), "Played filter requires login")
	menu._catalogue.set_filters(SongFilters.defaults(true))
	await until(func(): return not menu._catalogue.loading)
	root.get_node("Auth").signed_in = true
	root.get_node("Auth").user = {
		"id": int(server().user_id),
		"groups": 1,
		"steam_persona_name": "Integration test",
		"avatar_url": str(server().origin) + "/__test/avatar.jpg",
		"stats": {"sr_total": 30.5},
		"rank": 35,
	}
	root.get_node("Auth").state_changed.emit()
	await process_frame
	check(menu.browse_button.visible, "Browse appears after sign-in")
	check(menu.account_panel.visible, "Account panel appears after loading and sign-in")
	check(menu.account_panel.rating_label.text == "30.50 SR", "Account panel displays rating")
	check(menu.account_panel.rank_label.text == "#35", "Account panel displays global rank")
	check(await until(func(): return menu.account_panel.avatar.texture != null), "Account panel downloads the profile image")
	if OS.get_environment("DANSU_TEST_SCREENSHOT") != "":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			OS.get_environment("DANSU_TEST_SCREENSHOT").get_base_dir().path_join("account-panel.png")
		)
	var selected_download_uuid: String = root.get_node("CM").selected_chartset.uuid
	menu.activate_song_action()
	check(await until(func(): return not menu._catalogue.downloading, 20), "Download and indexing finish")
	check(root.get_node("CM").selected_chartset != null and root.get_node("CM").selected_chartset.uuid == selected_download_uuid, "Download indexing restores the selected Browse chartset")
	online = menu.chart_scroll.visible_items[0].chartset
	check(menu._catalogue.is_installed(online), "Downloaded chartset is indexed by UUID")
	check(menu.bottom_play_button.button_text == "Play", "Download becomes Play")
	var installed: Chart = menu._catalogue.local_chart(online.charts[0])
	check(installed.folder_name == ChartPackageInstaller.download_folder_name(online.online_metadata), "Installed chartset keeps the readable download folder name")
	var installed_manifest := ChartPackageInstaller.read_revision_manifest(installed.folder_path)
	check(not installed_manifest.is_empty(), "Downloaded chartset stores its installed revisions")
	check(not menu._catalogue.revision_update_available(online), "Matching installed revisions do not update again")
	var remote_revision := int(online.charts[0].online_metadata.get("chart_revision", 0))
	online.charts[0].online_metadata["chart_revision"] = remote_revision + 1
	check(menu._catalogue.revision_update_available(online), "A changed chart revision requests an update")
	online.charts[0].online_metadata["chart_revision"] = remote_revision
	check(installed.online_metadata.get("id") == online.charts[0].online_metadata.get("id"), "Installed chart retains online score metadata")
	var hit := Note.new()
	hit.type = Note.NoteType.HIT
	var spike := Note.new()
	spike.type = Note.NoteType.SPIKE
	var spike_score := Score.new()
	spike_score.add_note_result(hit, Score.GREAT, 50.0)
	spike_score.add_spike_dodge(spike)
	spike_score.high_combo = 2
	check(spike_score.perfect_plus == 1 and spike_score.great == 1, "Spike dodge shares the Perfect+ judgement count")
	check(is_equal_approx(spike_score.score, 75.0) and is_equal_approx(spike_score.max_score, 125.0), "Spike dodge keeps its distinct 25-point weight")
	check(is_equal_approx(spike_score.total_score, 60.0), "Client mixed spike score uses weighted raw points")
	check(root.get_node("Scores").submit_play(installed, spike_score), "Authenticated online score is queued")
	check(await until(func(): return spike_score.submitted or not spike_score.submission_error.is_empty()), "Score submission finishes")
	check(spike_score.submitted and spike_score.submission_error.is_empty(), "Mixed spike score is accepted by the server")
	if spike_score.submitted:
		check(is_equal_approx(float(spike_score.submission_response.score.total_score), 60.0), "Server stores the same mixed spike score")
	DirAccess.remove_absolute(installed.file_path)
	check(not menu._catalogue.is_installed(online), "A missing difficulty requires another download")
	menu.activate_song_action()
	check(await until(func(): return not menu._catalogue.downloading, 20), "An incomplete installation can be replaced")
	check(menu._catalogue.is_installed(online), "Replacement restores the missing difficulty")
	check(not DirAccess.dir_exists_absolute(ChartTransfer.ROOT), "Successful replacement removes its transfer files")
	menu.activate_song_action()
	check(root.get_node("Transition").last_scene == "res://scenes/gameplay/gameplay.tscn", "Play resolves a local playable chart")
	await menu.return_to_main_menu()
	await menu.begin_song_select(false)
	var local: ChartSet = root.get_node("CM").chartsets_by_uuid.get(str(server().local_uuid))
	root.get_node("CM").select_chartset(local)
	root.get_node("CM").select_chart(local.charts[0])
	var publisher: ChartPublisher = menu._publisher
	check(await until(func(): return not publisher.checking), "Upload UUID preflight finishes")
	check(publisher.button_text() == "Upload", "New local set shows Upload")
	publisher.show_publish(menu.settings_popup.theme)
	check(await until(func(): return publisher._thread == null and not publisher.checking), "Package preparation finishes")
	check(not publisher.dialog.get_ok_button().disabled, "Prepared package is reviewable")
	if OS.get_environment("DANSU_TEST_SCREENSHOT") != "":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("DANSU_TEST_SCREENSHOT").get_base_dir().path_join("upload-review.png"))
	publisher._submit()
	check(await until(func(): return not publisher.busy, 20), "Multipart upload succeeds")
	await until(func(): return not publisher.checking)
	check(publisher.button_text() == "Update", "Published UUID now shows Update")
	publisher.show_publish(menu.settings_popup.theme)
	await until(func(): return publisher._thread == null and not publisher.checking)
	publisher._submit()
	check(await until(func(): return not publisher.busy, 20), "Owner can update an unranked set")
	await until(func(): return not publisher.checking)
	publisher.show_publish(menu.settings_popup.theme)
	await until(func(): return publisher._thread == null and not publisher.checking)
	var request := HTTPRequest.new()
	root.add_child(request)
	request.request(str(server().origin) + "/__test/lock/" + str(server().local_uuid), PackedStringArray(), HTTPClient.METHOD_POST)
	await request.request_completed
	request.queue_free()
	publisher._submit()
	await until(func(): return publisher._upload == null)
	check(str(publisher._package.get("error", "")).contains("cannot be updated"), "Server rechecks status changed after preflight")
	publisher.dialog.hide()
	publisher._cancel_preparation()
	publisher._lookup()
	await until(func(): return not publisher.checking)
	check(publisher.restriction().contains("cannot be updated"), "Approved set is locked in the UI")
	await menu.return_to_main_menu()
	await menu.begin_song_select(false, true)
	await until(func(): return not menu._catalogue.loading)
	root.remove_child(menu)
	root.get_node("Auth").state_changed.emit()
	await process_frame
	root.add_child(menu)
	await process_frame
	check(await until(func(): return not menu._catalogue.loading), "Cached menu resumes catalogue requests on return")
	check(menu.menu_audio_switcher.current_audio.stream_paused, "Returning to Browse keeps local menu music paused")
	var redirect_request := HTTPRequest.new()
	redirect_request.max_redirects = 0
	root.add_child(redirect_request)
	redirect_request.request(str(server().origin) + "/__test/redirect")
	var redirect_reply: Array = await redirect_request.request_completed
	redirect_request.queue_free()
	menu._catalogue.capture_redirect = true
	menu._catalogue._on_download(redirect_reply[0], redirect_reply[1], redirect_reply[2], redirect_reply[3])
	check(menu._catalogue.redirect_url == "https://storage.invalid/package?signature=test", "Signed redirects are handled with automatic redirects disabled")
	check(menu._catalogue.redirect_headers.is_empty(), "API bearer is never forwarded to signed storage URL")
	if OS.get_environment("DANSU_TEST_SCREENSHOT") != "":
		menu._filter_popup.show_popup(true, SongFilters.defaults(true), true)
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("DANSU_TEST_SCREENSHOT"))
	_finish(menu)

func _finish(menu: Node) -> void:
	print("Catalogue integration: %d checks, %d failures" % [checks, failures])
	menu.queue_free()
	await process_frame
	get_tree().quit(0 if failures == 0 else 1)
