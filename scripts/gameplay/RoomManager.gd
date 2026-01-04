extends Node2D

signal room_cleared

var room_number: int = 1
var is_cleared: bool = false

var world_bounds: Rect2 = Rect2(-3840, -2160, 7680, 4320)

@onready var floor: ColorRect = $Floor


func _ready() -> void:
	_setup_camera_bounds()

	EventBus.push_notification("Room %d loaded" % room_number)


func initialize(room_num: int) -> void:
	room_number = room_num
	is_cleared = false
	# Future: Apply difficulty scaling based on room_number


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
		var parent = get_parent()
		if parent:
			var camera = parent.get_node_or_null("Camera2D")
			if camera and camera.has_method("set_world_bounds"):
				camera.set_world_bounds(world_bounds)


func get_world_bounds() -> Rect2:
	"""Get the world boundaries for this room."""
	return world_bounds

