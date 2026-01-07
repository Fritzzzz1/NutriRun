## Character select (stub).
extends Control


func _ready() -> void:
	if has_node("%SelectedLabel"):
		(_get_selected_label()).text = "Selected: " + GameState.selected_character_id


func _on_kid_pressed() -> void:
	_select("kid")


func _on_monster_pressed() -> void:
	_select("monster")


func _on_snowman_pressed() -> void:
	_select("lizardman")


func _on_continue_pressed() -> void:
	SceneManager.go_to_hub()


func _on_back_pressed() -> void:
	SceneManager.go_to_main_menu()


func _select(character_id: String) -> void:
	GameState.selected_character_id = character_id
	if has_node("%SelectedLabel"):
		(_get_selected_label()).text = "Selected: " + GameState.selected_character_id


func _get_selected_label() -> Label:
	return get_node("%SelectedLabel") as Label


