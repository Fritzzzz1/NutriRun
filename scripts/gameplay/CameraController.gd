## Camera controller: manages camera movement with edge-based panning.
## When player reaches viewport edges, camera pans to reveal new map areas.
extends Camera2D

@export var viewport_margin: float = 200.0  # Distance from edge before camera starts moving (larger = triggers earlier, shows more map)
@export var camera_speed: float = 750.0  # Pixels per second for camera movement (increased to keep up with faster player)
@export var smooth_camera: bool = true  # Whether to use smooth interpolation

var target_position: Vector2
var world_bounds: Rect2  # The total world size
var viewport_size: Vector2  # The visible viewport size

@onready var player: CharacterBody2D = null


func _ready() -> void:
	# Add to cameras group for easy access
	add_to_group("cameras")
	
	# Get viewport size
	var viewport = get_viewport()
	if viewport:
		viewport_size = viewport.get_visible_rect().size
	
	# Set initial camera position
	target_position = global_position
	
	# Find player node
	_find_player()
	
	# Connect to player if found
	if player:
		# Start following player
		global_position = player.global_position
		target_position = global_position


func _process(delta: float) -> void:
	if not player:
		_find_player()
		return
	
	_update_camera_position(delta)


func _find_player() -> void:
	# Try to find player in the scene tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D


func _update_camera_position(delta: float) -> void:
	if not player:
		return
	
	var player_pos = player.global_position
	var camera_pos = global_position
	
	# Calculate the visible area boundaries in world space
	var half_viewport = viewport_size / 2.0
	var visible_left = camera_pos.x - half_viewport.x
	var visible_right = camera_pos.x + half_viewport.x
	var visible_top = camera_pos.y - half_viewport.y
	var visible_bottom = camera_pos.y + half_viewport.y
	
	# Check if player is near the edges and adjust camera target
	var camera_needs_move = false
	var new_target = camera_pos
	
	# Right edge - player moving right, camera should follow
	if player_pos.x > visible_right - viewport_margin:
		new_target.x = player_pos.x - (half_viewport.x - viewport_margin)
		camera_needs_move = true
	
	# Left edge - player moving left, camera should follow
	if player_pos.x < visible_left + viewport_margin:
		new_target.x = player_pos.x + (half_viewport.x - viewport_margin)
		camera_needs_move = true
	
	# Bottom edge - player moving down, camera should follow
	if player_pos.y > visible_bottom - viewport_margin:
		new_target.y = player_pos.y - (half_viewport.y - viewport_margin)
		camera_needs_move = true
	
	# Top edge - player moving up, camera should follow
	if player_pos.y < visible_top + viewport_margin:
		new_target.y = player_pos.y + (half_viewport.y - viewport_margin)
		camera_needs_move = true
	
	# If camera needs to move, update target
	if camera_needs_move:
		target_position = new_target
	
	# Apply camera movement
	if smooth_camera:
		# Smooth interpolation
		global_position = global_position.lerp(target_position, camera_speed * delta / 100.0)
	else:
		# Instant movement
		global_position = target_position
	
	# Clamp camera to world bounds if set
	if world_bounds.has_area():
		global_position.x = clamp(global_position.x, 
			world_bounds.position.x + half_viewport.x,
			world_bounds.position.x + world_bounds.size.x - half_viewport.x)
		global_position.y = clamp(global_position.y,
			world_bounds.position.y + half_viewport.y,
			world_bounds.position.y + world_bounds.size.y - half_viewport.y)


func set_world_bounds(bounds: Rect2) -> void:
	"""Set the total world boundaries for camera clamping."""
	world_bounds = bounds


func get_visible_area() -> Rect2:
	"""Get the currently visible area in world coordinates."""
	var half_viewport = viewport_size / 2.0
	return Rect2(
		global_position - half_viewport,
		viewport_size
	)

