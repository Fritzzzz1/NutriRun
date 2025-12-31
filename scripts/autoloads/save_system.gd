## Simple JSON save/load (autoload).
extends Node

const SAVE_PATH := "user://nutrirun_save.json"


func _ready() -> void:
	EventBus.save_requested.connect(_on_save_requested)
	_load()


func save() -> bool:
	var data := {
		"version": GameState.SAVE_VERSION,
		"harvest_points": GameState.harvest_points,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		EventBus.save_completed.emit(false)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	EventBus.save_completed.emit(true)
	return true


func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var dict := parsed as Dictionary
	GameState.harvest_points = int(dict.get("harvest_points", 0))
	return true


func _on_save_requested() -> void:
	save()
