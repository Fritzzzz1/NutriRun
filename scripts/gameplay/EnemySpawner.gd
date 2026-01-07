extends Node2D

signal enemy_spawned(enemy_node: Node2D)

var spawn_interval: float = 4.0
var spawn_timer: float = 0.0
var max_enemies: int = 8
var current_enemies: Array[Node2D] = []
var spawn_area: Rect2 = Rect2(-3500, -2000, 7000, 4000)

var gameplay_layer: Node2D = null

# Scale config (loaded from game_balance.json)
var enemy_collision_radius: float = 8.0
var enemy_health_bar_width: float = 24.0
var enemy_health_bar_height: float = 4.0


func _ready() -> void:
	_load_entity_scales()
	_find_gameplay_layer()
	spawn_timer = spawn_interval * 0.7


func _load_entity_scales() -> void:
	"""Load entity scale configuration."""
	var balance_path = "res://assets/data/game_balance.json"
	if ResourceLoader.exists(balance_path):
		var file = FileAccess.open(balance_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse_string(file.get_as_text())
			file.close()

			if parse_result and parse_result.has("entity_scales"):
				var scales = parse_result.entity_scales
				if scales.has("enemy"):
					var enemy_scale = scales.enemy
					enemy_collision_radius = enemy_scale.get("collision_radius", 8.0)
					enemy_health_bar_width = enemy_scale.get("health_bar_width", 24.0)
					enemy_health_bar_height = enemy_scale.get("health_bar_height", 4.0)


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
	
	current_enemies = current_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	if spawn_timer <= 0.0 and current_enemies.size() < max_enemies:
		_spawn_enemy()
		spawn_timer = spawn_interval


func _spawn_enemy() -> void:
	"""Spawn an enemy at a random position."""
	var spawn_pos = _get_random_spawn_position()
	
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
	# Layer 4 = enemies, Mask 1 = walls, Mask 2 = player
	enemy.collision_layer = 4
	enemy.collision_mask = 3  # 1 (walls) + 2 (player)
	
	var script = load("res://scripts/enemies/EnemyBase.gd")
	enemy.set_script(script)
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = enemy_collision_radius
	collision.shape = shape
	enemy.add_child(collision)

	var visual_container = Node2D.new()
	visual_container.name = "VisualContainer"
	enemy.add_child(visual_container)

	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(enemy_health_bar_width, enemy_health_bar_height)
	# Position health bar above the enemy based on collision radius
	var bar_y_offset = -(enemy_collision_radius * 2 + 4)
	health_bar.position = Vector2(-enemy_health_bar_width / 2, bar_y_offset)
	health_bar.show_percentage = false
	enemy.add_child(health_bar)
	
	# Note: Hitbox is created in _ready() of EnemyBase.gd
	
	return enemy


func _get_random_spawn_position() -> Vector2:
	"""Get a random spawn position at the edges of the arena."""
	var attempts = 0
	var pos: Vector2
	
	while attempts < 20:
		if randf() > 0.5:
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
			var y_pos: float
			if randf() > 0.5:
				y_pos = spawn_area.position.y
			else:
				y_pos = spawn_area.position.y + spawn_area.size.y
			pos = Vector2(
				randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
				y_pos
			)
		
		if pos.distance_to(Vector2.ZERO) > 200:
			return pos
		
		attempts += 1
	
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
	pass


func _on_enemy_hit_player() -> void:
	"""Handle when enemy hits player."""
	# Could add screen shake, sound, etc.
	pass


func set_spawn_rate(interval: float) -> void:
	"""Adjust spawn rate dynamically."""
	spawn_interval = max(1.0, interval)  # Minimum 1 second
