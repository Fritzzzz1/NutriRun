## Room manager: handles room state, transitions, and difficulty scaling.
extends Node2D

signal room_cleared
signal exit_triggered

var room_number: int = 1
var is_cleared: bool = false

# World bounds for camera system - large arena for exploration
var world_bounds: Rect2 = Rect2(-3840, -2160, 7680, 4320)  # 4x4 camera viewports (1920x1080 each)

@onready var exit_trigger: Area2D = $ExitTrigger
@onready var floor: ColorRect = $Floor


func _ready() -> void:
	# Connect exit trigger
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_trigger_entered)
		exit_trigger.area_entered.connect(_on_exit_trigger_entered)
	
	# Notify camera controller of world bounds
	_setup_camera_bounds()
	
	EventBus.push_notification("Room %d loaded" % room_number)


func initialize(room_num: int) -> void:
	room_number = room_num
	is_cleared = false
	# Future: Apply difficulty scaling based on room_number


func _on_exit_trigger_entered(body: Node) -> void:
	# Only allow exit if room is cleared (or for now, always allow)
	if body.is_in_group("player"):
		EventBus.push_notification("Exiting to hub...")
		exit_triggered.emit()
		# Return to hub after a short delay
		await get_tree().create_timer(0.5).timeout
		EventBus.run_ended.emit()
		SceneManager.go_to_hub()


func clear_room() -> void:
	if is_cleared:
		return
	
	is_cleared = true
	room_cleared.emit()
	EventBus.push_notification("Room %d cleared!" % room_number)


func _setup_camera_bounds() -> void:
	"""Find camera controller and set world bounds."""
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0:
		var camera = cameras[0]
		if camera.has_method("set_world_bounds"):
			camera.set_world_bounds(world_bounds)
	else:
		# Try to find camera in parent scene
		var parent = get_parent()
		if parent:
			var camera = parent.get_node_or_null("Camera2D")
			if camera and camera.has_method("set_world_bounds"):
				camera.set_world_bounds(world_bounds)


func get_world_bounds() -> Rect2:
	"""Get the world boundaries for this room."""
	return world_bounds

