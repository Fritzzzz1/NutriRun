## DamageNumbers: Displays floating damage numbers when entities take damage.
## Spawns numbers in world space that float up and fade out.
extends Node

const FLOAT_DISTANCE: float = 50.0
const FLOAT_DURATION: float = 0.8
const SPREAD_RANGE: float = 20.0


func spawn_at_world_position(damage: int, world_pos: Vector2, _camera: Camera2D = null, is_critical: bool = false, is_heal: bool = false) -> void:
	"""Spawn a floating damage number at the given world position."""
	# Find the gameplay layer to add the number to
	var gameplay_layer = _get_gameplay_layer()
	if not gameplay_layer:
		return
	
	# Create the damage number node
	var container = Node2D.new()
	container.global_position = world_pos + Vector2(randf_range(-SPREAD_RANGE, SPREAD_RANGE), 0)
	container.z_index = 100
	
	# Create label
	var label = Label.new()
	
	# Set text
	if is_heal:
		label.text = "+%d" % damage
	else:
		label.text = "%d" % damage
	
	# Style based on type
	var color: Color
	var font_size: int
	
	if is_heal:
		color = Color(0.2, 1.0, 0.3)  # Bright green
		font_size = 22
	elif is_critical:
		color = Color(1.0, 0.9, 0.1)  # Bright gold
		font_size = 32
		label.text = "%d!" % damage
	else:
		color = Color(1.0, 0.2, 0.2)  # Bright red
		font_size = 24
	
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# Center the label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(100, 40)
	label.position = Vector2(-50, -20)
	
	container.add_child(label)
	gameplay_layer.add_child(container)
	
	# Initial scale
	container.scale = Vector2(0.5, 0.5)
	
	# Animate
	var tween = container.create_tween()
	tween.set_parallel(true)
	
	# Pop in
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(container, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Float up
	tween.tween_property(container, "position:y", container.position.y - FLOAT_DISTANCE, FLOAT_DURATION).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(container, "modulate:a", 0.0, FLOAT_DURATION * 0.4).set_delay(FLOAT_DURATION * 0.6)
	
	# Cleanup
	await tween.finished
	container.queue_free()


func _get_gameplay_layer() -> Node:
	"""Find the gameplay layer to spawn numbers in."""
	var tree = get_tree()
	if not tree:
		return null
	
	var root = tree.current_scene
	if root:
		var layer = root.get_node_or_null("GameplayLayer")
		if layer:
			return layer
	
	# Fallback: try to find any node in the gameplay group
	var players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].get_parent()
	
	return null
