extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const HUB_SCENE := "res://scenes/hub/hub_screen.tscn"
const GAMEPLAY_SCENE := "res://scenes/gameplay/gameplay_root.tscn"


func go_to_main_menu() -> void:
	print("SceneManager: Changing to main menu scene: ", MAIN_MENU_SCENE)
	var error = get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Failed to change scene to main menu: " + str(error))


func go_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func go_to_hub() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func go_to_gameplay() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)


