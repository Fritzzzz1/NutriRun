## Global run + meta-progression state (autoload).
##
## This is intentionally small for now; grow it as systems come online.
extends Node

const SAVE_VERSION := "0.1"

# Meta progression
var harvest_points: int = 0

# Run state (placeholder)
var current_room: int = 0
var selected_character_id: String = "kid"


func reset_run_state() -> void:
	current_room = 0


