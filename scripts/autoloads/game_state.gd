extends Node

const SAVE_VERSION := "0.1"

var harvest_points: int = 0

var current_room: int = 0
var selected_character_id: String = "kid"


func reset_run_state() -> void:
	current_room = 0


