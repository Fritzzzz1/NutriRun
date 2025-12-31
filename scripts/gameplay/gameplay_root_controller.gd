## Gameplay root controller (stub).
extends Node


func _ready() -> void:
	EventBus.push_notification("Gameplay started (stub).")


func _on_return_to_hub_pressed() -> void:
	EventBus.run_ended.emit()
	SceneManager.go_to_hub()


