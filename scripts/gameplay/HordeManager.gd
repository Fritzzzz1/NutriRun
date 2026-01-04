## Horde manager: manages the vegetable squad, spawning and AI coordination.
extends Node2D

signal horde_member_died
signal horde_size_changed(new_size: int)

var vegetable_units: Array[Node2D] = []
var max_horde_size: int = 5  # Start with 5 vegetables
var base_vegetable_stats: Dictionary = {
	"tomato": {"hp": 30, "damage": 5, "speed": 100.0},
	"carrot": {"hp": 20, "damage": 8, "speed": 120.0},
	"pepper": {"hp": 40, "damage": 4, "speed": 80.0},
	"lettuce": {"hp": 25, "damage": 3, "speed": 110.0},
	"potato": {"hp": 50, "damage": 7, "speed": 70.0}
}

var gameplay_layer: Node2D = null


func _ready() -> void:
	# Find gameplay layer
	_find_gameplay_layer()
	
	# Spawn initial horde
	spawn_initial_horde()


func _find_gameplay_layer() -> void:
	"""Find the gameplay layer in the scene tree."""
	var parent = get_parent()
	if parent:
		gameplay_layer = parent
		if parent.name != "GameplayLayer":
			gameplay_layer = parent.get_node_or_null("GameplayLayer")
			if not gameplay_layer:
				var root = get_tree().root
				gameplay_layer = root.get_node_or_null("GameplayRoot/GameplayLayer")


func spawn_initial_horde() -> void:
	"""Spawn the initial vegetable horde."""
	if not gameplay_layer:
		push_error("HordeManager: Gameplay layer not found!")
		return
	
	# Spawn a mix of vegetables
	var types_to_spawn = ["tomato", "tomato", "carrot", "pepper", "lettuce"]
	
	for i in range(min(max_horde_size, types_to_spawn.size())):
		var veg_type = types_to_spawn[i]
		spawn_vegetable(veg_type, _get_spawn_position_around_player(i))


func _get_spawn_position_around_player(index: int) -> Vector2:
	"""Get spawn position around player in a circle formation."""
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	var player = players[0]
	var angle = (float(index) / float(max_horde_size)) * TAU
	var radius = 60.0 + (index * 10.0)  # Stagger positions
	var offset = Vector2(cos(angle), sin(angle)) * radius
	
	return player.global_position + offset


func spawn_vegetable(type: String, position: Vector2) -> Node2D:
	"""Spawn a vegetable unit of the specified type."""
	if not gameplay_layer:
		return null
	
	# Create vegetable unit
	var vegetable = CharacterBody2D.new()
	vegetable.name = "Vegetable_" + type.capitalize()
	vegetable.position = position
	
	# Add script
	var script = load("res://scripts/gameplay/VegetableUnit.gd")
	vegetable.set_script(script)
	
	# Get stats for this type
	var stats = base_vegetable_stats.get(type, base_vegetable_stats["tomato"])
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	vegetable.add_child(collision)
	
	# Add visual container
	var visual_container = Node2D.new()
	visual_container.name = "VisualContainer"
	vegetable.add_child(visual_container)
	
	# Add health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(30, 5)
	health_bar.position = Vector2(-15, -25)
	health_bar.show_percentage = false
	vegetable.add_child(health_bar)
	
	# Add to gameplay layer
	gameplay_layer.add_child(vegetable)
	
	# Initialize vegetable
	if vegetable.has_method("initialize"):
		vegetable.initialize(type, stats.hp, stats.damage, stats.speed)
	
	# Connect signals
	if vegetable.has_signal("vegetable_died"):
		vegetable.vegetable_died.connect(_on_vegetable_died)
	
	# Track vegetable
	vegetable_units.append(vegetable)
	horde_size_changed.emit(vegetable_units.size())
	
	return vegetable


func _on_vegetable_died() -> void:
	"""Handle when a vegetable dies."""
	# Clean up dead vegetables from tracking
	vegetable_units = vegetable_units.filter(func(veg): return is_instance_valid(veg))
	horde_size_changed.emit(vegetable_units.size())
	horde_member_died.emit()


func get_horde_size() -> int:
	"""Get current number of alive vegetables."""
	# Clean up dead vegetables
	vegetable_units = vegetable_units.filter(func(veg): return is_instance_valid(veg))
	return vegetable_units.size()


func get_alive_vegetables() -> Array[Node2D]:
	"""Get array of all alive vegetables."""
	vegetable_units = vegetable_units.filter(func(veg): return is_instance_valid(veg))
	return vegetable_units.duplicate()


func apply_buffs_to_horde() -> void:
	"""Apply nutrition buffs to all vegetables in horde."""
	# This is handled automatically by VegetableUnit._on_inventory_changed
	# But we can trigger it manually if needed
	for veg in vegetable_units:
		if is_instance_valid(veg) and veg.has_method("_on_inventory_changed"):
			veg._on_inventory_changed()

