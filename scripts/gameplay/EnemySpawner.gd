## Enemy spawner: automatically spawns enemies at intervals.
extends Node2D

signal enemy_spawned(enemy_node: Node2D)

var spawn_interval: float = 4.0  # Seconds between spawns
var spawn_timer: float = 0.0
var max_enemies: int = 8  # Max concurrent enemies
var current_enemies: Array[Node2D] = []
var spawn_area: Rect2 = Rect2(-3500, -2000, 7000, 4000)  # Large spawn area across the arena

var gameplay_layer: Node2D = null


func _ready() -> void:
	# Find gameplay layer
	_find_gameplay_layer()
	# Start spawning after initial delay
	spawn_timer = spawn_interval * 0.7


func _find_gameplay_layer() -> void:
	"""Find the gameplay layer in the scene tree."""
	var parent = get_parent()
	if parent:
		gameplay_layer = parent
		# If parent is GameplayLayer, we're good. Otherwise search for it.
		if parent.name != "GameplayLayer":
			gameplay_layer = parent.get_node_or_null("GameplayLayer")
			if not gameplay_layer:
				# Try to find it in the tree
				var root = get_tree().root
				gameplay_layer = root.get_node_or_null("GameplayRoot/GameplayLayer")


func _process(delta: float) -> void:
	spawn_timer -= delta
	
	# Clean up dead enemies from tracking
	current_enemies = current_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	# Spawn new enemy if timer expired and we're under the limit
	if spawn_timer <= 0.0 and current_enemies.size() < max_enemies:
		_spawn_enemy()
		spawn_timer = spawn_interval


func _spawn_enemy() -> void:
	"""Spawn an enemy at a random position."""
	var spawn_pos = _get_random_spawn_position()
	
	# Create enemy scene programmatically (or load from scene file if we create one)
	var enemy = _create_enemy()
	enemy.position = spawn_pos
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_hit_player.connect(_on_enemy_hit_player)
	
	if gameplay_layer:
		gameplay_layer.add_child(enemy)
		current_enemies.append(enemy)
		enemy_spawned.emit(enemy)


func _create_enemy() -> Node2D:
	"""Create an enemy instance with proper collision setup."""
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy"
	
	# Set collision layers BEFORE adding to tree
	# Layer 3 (enemies = 4), mask only layer 1 (world = 1) - NOT player to avoid getting stuck
	enemy.collision_layer = 4
	enemy.collision_mask = 1
	
	# Add script
	var script = load("res://scripts/enemies/EnemyBase.gd")
	enemy.set_script(script)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	enemy.add_child(collision)
	
	# Add visual container
	var visual_container = Node2D.new()
	visual_container.name = "VisualContainer"
	enemy.add_child(visual_container)
	
	# Add health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(40, 6)
	health_bar.position = Vector2(-20, -30)
	health_bar.show_percentage = false
	enemy.add_child(health_bar)
	
	# Note: Hitbox is created in _ready() of EnemyBase.gd
	
	return enemy


func _get_random_spawn_position() -> Vector2:
	"""Get a random spawn position at the edges of the arena."""
	var attempts = 0
	var pos: Vector2
	
	while attempts < 20:
		# Spawn at edges more often
		if randf() > 0.5:
			# Spawn on horizontal edges
			var x_pos: float
			if randf() > 0.5:
				x_pos = spawn_area.position.x
			else:
				x_pos = spawn_area.position.x + spawn_area.size.x
			pos = Vector2(
				x_pos,
				randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
			)
		else:
			# Spawn on vertical edges
			var y_pos: float
			if randf() > 0.5:
				y_pos = spawn_area.position.y
			else:
				y_pos = spawn_area.position.y + spawn_area.size.y
			pos = Vector2(
				randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
				y_pos
			)
		
		# Make sure it's away from center
		if pos.distance_to(Vector2.ZERO) > 200:
			return pos
		
		attempts += 1
	
	# Fallback
	var fallback_x: float
	var fallback_y: float
	if randf() > 0.5:
		fallback_x = spawn_area.position.x
	else:
		fallback_x = spawn_area.position.x + spawn_area.size.x
	if randf() > 0.5:
		fallback_y = spawn_area.position.y
	else:
		fallback_y = spawn_area.position.y + spawn_area.size.y
	return Vector2(fallback_x, fallback_y)


func _on_enemy_died() -> void:
	"""Handle enemy death."""
	# Enemy removes itself, we just track count
	pass


func _on_enemy_hit_player() -> void:
	"""Handle when enemy hits player."""
	# Could add screen shake, sound, etc.
	pass


func set_spawn_rate(interval: float) -> void:
	"""Adjust spawn rate dynamically."""
	spawn_interval = max(1.0, interval)  # Minimum 1 second
