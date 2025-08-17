class_name BeatmapManager
extends Node

signal beatmap_loaded(beatmap_set: BeatmapSet)

var _loader_thread := Thread.new()
var _folders_to_load := []
var _stop := false

func start_loading(folders: Array):
	_folders_to_load = folders.duplicate()
	_stop = false
	if not _loader_thread.is_started():
		_loader_thread.start(_thread_func)

func stop():
	_stop = true

func _thread_func():
	while _folders_to_load.size() > 0 and not _stop:
		var folder = _folders_to_load.pop_front()
		var set := BeatmapSet.new()
		set.load_from_folder(folder)
		if set.beatmaps.size() > 0:
			call_deferred("_emit_loaded", set)
	OS.delay_msec(10) # 과도한 디스크 점유 방지

func _emit_loaded(set: BeatmapSet):
	Game.loaded_beatmaps.append(set)
	print("beatmap_loaded")
	emit_signal("beatmap_loaded", set)
