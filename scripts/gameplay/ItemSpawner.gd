extends Node2D

signal item_spawned(item_node: Node2D)

var spawn_interval: float = 3.0
var spawn_timer: float = 0.0
var items_data: Array = []
var spawn_area: Rect2 = Rect2(-3500, -2000, 7000, 4000)
var max_items_on_screen: int = 15
var current_items: Array[Node2D] = []

var gameplay_layer: Node2D = null


func _ready() -> void:
	_load_items_data()
	_find_gameplay_layer()
	spawn_timer = spawn_interval * 0.5


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


func _process(delta: float) -> void:
	spawn_timer -= delta
	
	current_items = current_items.filter(func(item): return is_instance_valid(item))
	
	if spawn_timer <= 0.0 and current_items.size() < max_items_on_screen:
		_spawn_random_item()
		spawn_timer = spawn_interval


func _load_items_data() -> void:
	"""Load nutrition items from JSON."""
	var items_path = "res://assets/data/nutrition_items.json"
	if not ResourceLoader.exists(items_path):
		push_error("Nutrition items JSON not found!")
		return
	
	var file = FileAccess.open(items_path, FileAccess.READ)
	if not file:
		push_error("Failed to open nutrition items JSON!")
		return
	
	var json = JSON.new()
	var parse_result = json.parse_string(file.get_as_text())
	file.close()
	
	if not parse_result or not parse_result.has("items"):
		push_error("Invalid nutrition items JSON format!")
		return
	
	items_data = parse_result.items


func _spawn_random_item() -> void:
	"""Spawn a random nutrition item at a random position."""
	if items_data.is_empty():
		return
	
	var random_item = items_data[randi() % items_data.size()]
	
	var spawn_pos = _get_random_spawn_position()
	
	var pickup_scene = load("res://scenes/entities/NutritionPickup.tscn")
	if not pickup_scene:
		push_error("Failed to load NutritionPickup scene!")
		return
	
	var pickup = pickup_scene.instantiate()
	pickup.initialize(random_item)
	pickup.position = spawn_pos
	pickup.picked_up.connect(_on_item_picked_up)
	
	if gameplay_layer:
		gameplay_layer.add_child(pickup)
		current_items.append(pickup)
		item_spawned.emit(pickup)
	else:
		push_error("Gameplay layer not found!")


func _get_random_spawn_position() -> Vector2:
	"""Get a random spawn position, avoiding the center (player spawn area)."""
	var attempts = 0
	var pos: Vector2
	
	while attempts < 20:
		pos = Vector2(
			randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
			randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
		)
		
		if pos.distance_to(Vector2.ZERO) > 150:
			return pos
		
		attempts += 1
	
	var fallback_x: float
	if randf() > 0.5:
		fallback_x = spawn_area.position.x
	else:
		fallback_x = spawn_area.position.x + spawn_area.size.x
	return Vector2(
		fallback_x,
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)


func _on_item_picked_up(item_data: Dictionary) -> void:
	"""Handle when an item is picked up (remove from tracking)."""
	pass


func set_spawn_rate(interval: float) -> void:
	"""Adjust spawn rate dynamically."""
	spawn_interval = max(0.5, interval)  # Minimum 0.5 seconds
