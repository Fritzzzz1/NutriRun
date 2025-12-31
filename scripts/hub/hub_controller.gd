## Hub screen controller (stub).
extends Control


func _ready() -> void:
	if has_node("%StatusLabel"):
		var status := get_node("%StatusLabel") as Label
		status.text = "Character: %s  |  Harvest Points: %d" % [GameState.selected_character_id, GameState.harvest_points]


func _on_start_run_pressed() -> void:
	GameState.reset_run_state()
	EventBus.run_started.emit()
	SceneManager.go_to_gameplay()


func _on_save_pressed() -> void:
	EventBus.save_requested.emit()
	EventBus.push_notification("Save requested.")


func _on_back_to_menu_pressed() -> void:
	SceneManager.go_to_main_menu()


