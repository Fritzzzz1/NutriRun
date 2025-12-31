## Minimal main menu controller.
extends Control


func _ready() -> void:
	if has_node("%VersionLabel"):
		var version_label := get_node("%VersionLabel") as Label
		version_label.text = "v" + GameState.SAVE_VERSION


func _on_start_pressed() -> void:
	SceneManager.go_to_character_select()


func _on_quit_pressed() -> void:
	get_tree().quit()


