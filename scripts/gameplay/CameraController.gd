extends Camera2D

enum CameraMode {
	EDGE_BASED,
	PLAYER_CENTERED
}

@export var camera_mode: CameraMode = CameraMode.PLAYER_CENTERED
@export var viewport_margin: float = 300.0
@export_range(3.0, 10.0, 0.5) var smooth_speed: float = 4.5
@export var smooth_camera: bool = true
@export_range(1.0, 3.0, 0.1) var camera_zoom: float = 1.5

var target_position: Vector2
var world_bounds: Rect2
var viewport_size: Vector2

@onready var player: CharacterBody2D = null


func _ready() -> void:
	add_to_group("cameras")

	# Apply zoom (higher = more zoomed in = player appears larger)
	zoom = Vector2(camera_zoom, camera_zoom)

	var viewport = get_viewport()
	if viewport:
		viewport_size = viewport.get_visible_rect().size / camera_zoom

	target_position = global_position

	_find_player()

	if player:
		global_position = player.global_position
		target_position = global_position


func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return

	_update_camera_position(delta)


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D


func _update_camera_position(delta: float) -> void:
	if not player:
		return

	match camera_mode:
		CameraMode.PLAYER_CENTERED:
			_update_player_centered(delta)
		CameraMode.EDGE_BASED:
			_update_edge_based(delta)


func _update_player_centered(delta: float) -> void:
	"""Always keep player centered with smooth following."""
	# Target is always player position
	target_position = player.global_position

	# Smoothly interpolate to target with FIXED lerp calculation
	if smooth_camera:
		var lerp_weight = clamp(smooth_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(target_position, lerp_weight)
	else:
		global_position = target_position

	# Clamp to world bounds
	_clamp_camera_to_world()


func _update_edge_based(delta: float) -> void:
	"""Move camera only when player approaches viewport edges."""
	var player_pos = player.global_position
	var camera_pos = global_position

	var half_viewport = viewport_size / 2.0
	var visible_left = camera_pos.x - half_viewport.x
	var visible_right = camera_pos.x + half_viewport.x
	var visible_top = camera_pos.y - half_viewport.y
	var visible_bottom = camera_pos.y + half_viewport.y

	var camera_needs_move = false
	var new_target = camera_pos

	# Check all edges with updated threshold (300px)
	if player_pos.x > visible_right - viewport_margin:
		new_target.x = player_pos.x - (half_viewport.x - viewport_margin)
		camera_needs_move = true

	if player_pos.x < visible_left + viewport_margin:
		new_target.x = player_pos.x + (half_viewport.x - viewport_margin)
		camera_needs_move = true

	if player_pos.y > visible_bottom - viewport_margin:
		new_target.y = player_pos.y - (half_viewport.y - viewport_margin)
		camera_needs_move = true

	if player_pos.y < visible_top + viewport_margin:
		new_target.y = player_pos.y + (half_viewport.y - viewport_margin)
		camera_needs_move = true

	if camera_needs_move:
		target_position = new_target

	# Smoothly interpolate with FIXED lerp calculation
	if smooth_camera:
		var lerp_weight = clamp(smooth_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(target_position, lerp_weight)
	else:
		global_position = target_position

	# Clamp to world bounds
	_clamp_camera_to_world()


func _clamp_camera_to_world() -> void:
	"""Clamp camera position to world boundaries."""
	if not world_bounds.has_area():
		return

	var half_viewport = viewport_size / 2.0

	# Calculate valid camera bounds
	var min_cam_x = world_bounds.position.x + half_viewport.x
	var max_cam_x = world_bounds.position.x + world_bounds.size.x - half_viewport.x
	var min_cam_y = world_bounds.position.y + half_viewport.y
	var max_cam_y = world_bounds.position.y + world_bounds.size.y - half_viewport.y

	# Clamp position
	global_position.x = clamp(global_position.x, min_cam_x, max_cam_x)
	global_position.y = clamp(global_position.y, min_cam_y, max_cam_y)

	# CRITICAL FIX: Snap target to match when hitting bounds
	# This prevents rubber-banding and stuttering at edges
	if global_position.x == min_cam_x or global_position.x == max_cam_x:
		target_position.x = global_position.x
	if global_position.y == min_cam_y or global_position.y == max_cam_y:
		target_position.y = global_position.y


func set_world_bounds(bounds: Rect2) -> void:
	"""Set the total world boundaries for camera clamping."""
	world_bounds = bounds


func set_camera_mode(mode: CameraMode) -> void:
	"""Change camera behavior mode."""
	camera_mode = mode

	# When switching to player-centered, snap to player position
	if mode == CameraMode.PLAYER_CENTERED and player:
		target_position = player.global_position


func get_visible_area() -> Rect2:
	"""Get the currently visible area in world coordinates."""
	var half_viewport = viewport_size / 2.0
	return Rect2(
		global_position - half_viewport,
		viewport_size
	)


func set_zoom_level(new_zoom: float) -> void:
	"""Change camera zoom at runtime."""
	camera_zoom = new_zoom
	zoom = Vector2(camera_zoom, camera_zoom)

	var viewport = get_viewport()
	if viewport:
		viewport_size = viewport.get_visible_rect().size / camera_zoom

