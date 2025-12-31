## Global signal hub (autoload) to decouple systems.
extends Node

signal save_requested
signal save_completed(ok: bool)

signal run_started
signal run_ended

signal notification_pushed(text: String)


func push_notification(text: String) -> void:
	notification_pushed.emit(text)


