## Minimap: Shows a small overhead view of the map with camera and entity positions.
## The world is ~4x4 camera viewports, so camera rect takes up ~1/16th of minimap.
extends Control

@export var minimap_size: Vector2 = Vector2(200, 150)
@export var background_color: Color = Color(0.08, 0.1, 0.15, 0.9)
@export var border_color: Color = Color(0.3, 0.4, 0.6, 1.0)
@export var camera_rect_color: Color = Color(0.2, 0.7, 1.0, 0.3)
@export var camera_border_color: Color = Color(0.3, 0.85, 1.0, 0.9)
@export var player_color: Color = Color(0.3, 0.7, 1.0, 1.0)
@export var enemy_color: Color = Color(1.0, 0.25, 0.25, 1.0)
@export var item_color: Color = Color(0.4, 1.0, 0.5, 0.9)

var camera_ref: Camera2D = null
var player_ref: Node2D = null

# World bounds - 4x4 grid of camera viewports
var world_bounds: Rect2 = Rect2(-3840, -2160, 7680, 4320)
var viewport_size: Vector2 = Vector2(1920, 1080)


func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	call_deferred("_find_references")


func _process(_delta: float) -> void:
	if not camera_ref:
		_find_references()
	else:
		# Update from camera
		if camera_ref.world_bounds.has_area():
			world_bounds = camera_ref.world_bounds
		if camera_ref.viewport_size != Vector2.ZERO:
			viewport_size = camera_ref.viewport_size
	
	queue_redraw()


func _find_references() -> void:
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0:
		camera_ref = cameras[0]
		if camera_ref.world_bounds.has_area():
			world_bounds = camera_ref.world_bounds
		if camera_ref.viewport_size != Vector2.ZERO:
			viewport_size = camera_ref.viewport_size
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)
	
	# Inner area
	var inner_margin = 2.0
	draw_rect(Rect2(Vector2(inner_margin, inner_margin), minimap_size - Vector2(inner_margin * 2, inner_margin * 2)), Color(0.05, 0.07, 0.1, 0.5))
	
	# Grid showing the 4x4 viewport divisions
	_draw_grid()
	
	# Items
	_draw_items()
	
	# Enemies
	_draw_enemies()
	
	# Camera rect
	_draw_camera_rect()
	
	# Player
	_draw_player()
	
	# Border and decorations
	draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, 2.0)
	_draw_corners()
	_draw_label()


func _draw_label() -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(6, 14), "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.6, 0.7, 0.7))


func _draw_grid() -> void:
	"""Draw 4x4 grid lines showing viewport-sized areas."""
	var grid_color = Color(0.25, 0.3, 0.4, 0.3)
	
	# 4 columns = 3 vertical lines
	for i in range(1, 4):
		var x = (minimap_size.x / 4.0) * i
		draw_line(Vector2(x, 0), Vector2(x, minimap_size.y), grid_color, 1.0)
	
	# 4 rows = 3 horizontal lines
	for i in range(1, 4):
		var y = (minimap_size.y / 4.0) * i
		draw_line(Vector2(0, y), Vector2(minimap_size.x, y), grid_color, 1.0)


func _draw_corners() -> void:
	var corner_size = 10.0
	var corner_color = Color(0.4, 0.55, 0.8, 0.9)
	var thickness = 2.0
	
	# Top-left
	draw_line(Vector2(0, corner_size), Vector2(0, 0), corner_color, thickness)
	draw_line(Vector2(0, 0), Vector2(corner_size, 0), corner_color, thickness)
	
	# Top-right
	draw_line(Vector2(minimap_size.x - corner_size, 0), Vector2(minimap_size.x, 0), corner_color, thickness)
	draw_line(Vector2(minimap_size.x, 0), Vector2(minimap_size.x, corner_size), corner_color, thickness)
	
	# Bottom-left
	draw_line(Vector2(0, minimap_size.y - corner_size), Vector2(0, minimap_size.y), corner_color, thickness)
	draw_line(Vector2(0, minimap_size.y), Vector2(corner_size, minimap_size.y), corner_color, thickness)
	
	# Bottom-right
	draw_line(Vector2(minimap_size.x - corner_size, minimap_size.y), Vector2(minimap_size.x, minimap_size.y), corner_color, thickness)
	draw_line(Vector2(minimap_size.x, minimap_size.y - corner_size), Vector2(minimap_size.x, minimap_size.y), corner_color, thickness)


func _draw_camera_rect() -> void:
	"""Draw the camera viewport as a small rectangle (~1/16th of minimap for 4x4 world)."""
	if not camera_ref:
		return
	
	# Camera rect size on minimap = viewport_size / world_size * minimap_size
	# For 4x4 viewports: this should be ~1/4 width, 1/4 height = 1/16 area
	var rect_size = (viewport_size / world_bounds.size) * minimap_size
	
	# Get camera world position and convert to minimap position
	var camera_world_pos = camera_ref.global_position
	var camera_minimap_center = _world_to_minimap(camera_world_pos)
	
	# Rect position is center minus half size
	var rect_pos = camera_minimap_center - rect_size / 2.0
	
	# Clamp rect to stay within minimap bounds
	rect_pos.x = clamp(rect_pos.x, 0, minimap_size.x - rect_size.x)
	rect_pos.y = clamp(rect_pos.y, 0, minimap_size.y - rect_size.y)
	
	var minimap_rect = Rect2(rect_pos, rect_size)
	
	# Draw filled + border
	draw_rect(minimap_rect, camera_rect_color)
	draw_rect(minimap_rect, camera_border_color, false, 2.0)


func _draw_player() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	var minimap_pos = _world_to_minimap(player_ref.global_position)
	minimap_pos.x = clamp(minimap_pos.x, 4, minimap_size.x - 4)
	minimap_pos.y = clamp(minimap_pos.y, 4, minimap_size.y - 4)
	
	# Glow + dot
	draw_circle(minimap_pos, 5.0, Color(player_color.r, player_color.g, player_color.b, 0.3))
	draw_circle(minimap_pos, 3.0, player_color)
	
	# Direction indicator
	if player_ref.velocity.length() > 10:
		var dir = player_ref.velocity.normalized() * 6.0
		draw_line(minimap_pos, minimap_pos + dir, Color.WHITE, 1.5)


func _draw_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var minimap_pos = _world_to_minimap(enemy.global_position)
		if _is_in_minimap(minimap_pos):
			draw_circle(minimap_pos, 2.5, enemy_color)


func _draw_items() -> void:
	var gameplay_layer = _get_gameplay_layer()
	if not gameplay_layer:
		return
	
	for child in gameplay_layer.get_children():
		if child.name.begins_with("NutritionPickup") or child.is_in_group("items"):
			if not is_instance_valid(child):
				continue
			var minimap_pos = _world_to_minimap(child.global_position)
			if _is_in_minimap(minimap_pos):
				draw_circle(minimap_pos, 2.0, item_color)


func _get_gameplay_layer() -> Node:
	var root = get_tree().current_scene
	if root:
		return root.get_node_or_null("GameplayLayer")
	return null


func _world_to_minimap(world_pos: Vector2) -> Vector2:
	"""Convert world position to minimap position."""
	var relative = world_pos - world_bounds.position
	var normalized = relative / world_bounds.size
	return normalized * minimap_size


func _is_in_minimap(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= minimap_size.x and pos.y >= 0 and pos.y <= minimap_size.y
