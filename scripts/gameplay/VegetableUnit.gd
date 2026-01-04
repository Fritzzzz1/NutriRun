## Base vegetable unit class: handles movement, combat, and AI behavior.
extends CharacterBody2D

signal vegetable_died
signal vegetable_attacked(target: Node2D, damage: int)

var max_health: int = 30
var current_health: int = 30
var base_max_health: int = 30  # Store base value for multiplier calculations
var base_damage: int = 5
var base_damage_value: int = 5  # Store base value for multiplier calculations
var base_speed: float = 100.0
var base_speed_value: float = 100.0  # Store base value for multiplier calculations
var attack_range: float = 50.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

var vegetable_type: String = "tomato"  # tomato, carrot, pepper, lettuce, potato
var player_ref: Node2D = null
var target_enemy: Node2D = null
var is_active: bool = true

@onready var health_bar: ProgressBar = $HealthBar
var visual_container: Node2D = null
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	current_health = max_health
	
	# Create visual container if it doesn't exist
	visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		visual_container = Node2D.new()
		visual_container.name = "VisualContainer"
		add_child(visual_container)
	
	_setup_visual()
	_find_player()
	
	# Add to vegetables group
	add_to_group("vegetables")
	
	# Connect to inventory changes to update stats
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed()  # Initial stat update


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	attack_timer -= delta
	
	# Update stats from buffs
	_update_stats_from_buffs()
	
	# Find target enemy
	_find_target_enemy()
	
	# Move and attack
	if target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		
		if distance <= attack_range and attack_timer <= 0.0:
			_attack_enemy(target_enemy)
			attack_timer = attack_cooldown
		else:
			# Move towards target
			var direction = (target_enemy.global_position - global_position).normalized()
			velocity = direction * base_speed
			move_and_slide()
	else:
		# Follow player if no target
		if player_ref and is_instance_valid(player_ref):
			var direction = (player_ref.global_position - global_position).normalized()
			# Keep some distance from player
			var distance = global_position.distance_to(player_ref.global_position)
			if distance > 80.0:
				velocity = direction * base_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO


func _find_player() -> void:
	"""Find the player in the scene."""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _find_target_enemy() -> void:
	"""Find the nearest enemy to attack."""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		target_enemy = null
		return
	
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance and distance <= 300.0:  # Max aggro range
			nearest_distance = distance
			nearest_enemy = enemy
	
	target_enemy = nearest_enemy


func _attack_enemy(enemy: Node2D) -> void:
	"""Attack the target enemy."""
	if not enemy or not is_instance_valid(enemy):
		return
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(base_damage)
		vegetable_attacked.emit(enemy, base_damage)
		
		# Visual feedback
		_play_attack_animation()


func _play_attack_animation() -> void:
	"""Play attack animation feedback."""
	if not visual_container:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_container, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(visual_container, "scale", Vector2.ONE, 0.1)


func take_damage(amount: int) -> void:
	"""Take damage and update health."""
	current_health = max(0, current_health - amount)
	_update_health_display()
	
	# Flash when hit
	_flash_damage()
	
	if current_health <= 0:
		_die()


func _flash_damage() -> void:
	"""Flash when taking damage."""
	if not visual_container:
		return
	var tween = create_tween()
	visual_container.modulate = Color.RED
	tween.tween_property(visual_container, "modulate", Color.WHITE, 0.2)


func _update_health_display() -> void:
	"""Update health bar."""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _die() -> void:
	"""Handle vegetable death."""
	is_active = false
	vegetable_died.emit()
	
	# Death animation
	if visual_container:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(visual_container, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(visual_container, "modulate:a", 0.0, 0.3)
		tween.tween_property(self, "position:y", position.y - 20, 0.3)
		await tween.finished
	
	queue_free()


func _setup_visual() -> void:
	"""Set up visual representation based on vegetable type."""
	# Clear existing visuals
	for child in visual_container.get_children():
		child.queue_free()
	
	var size = 28.0
	var color: Color
	
	match vegetable_type:
		"tomato":
			color = Color(0.9, 0.2, 0.2)  # Red
		"carrot":
			color = Color(1.0, 0.6, 0.2)  # Orange
		"pepper":
			color = Color(0.2, 0.8, 0.3)  # Green
		"lettuce":
			color = Color(0.4, 0.9, 0.4)  # Light green
		"potato":
			color = Color(0.8, 0.7, 0.5)  # Brown
		_:
			color = Color(0.6, 0.6, 0.9)  # Purple default
	
	# Create glow
	var glow = ColorRect.new()
	glow.size = Vector2(size + 6, size + 6)
	glow.color = Color(color.r, color.g, color.b, 0.4)
	glow.position = Vector2(-(size + 6) / 2, -(size + 6) / 2)
	visual_container.add_child(glow)
	
	# Create main body (circle for vegetables)
	var body = ColorRect.new()
	body.size = Vector2(size, size)
	body.color = color
	body.position = Vector2(-size / 2, -size / 2)
	# Make it circular by using a rotated square (simple approach)
	body.rotation_degrees = 45
	visual_container.add_child(body)
	
	# Add simple face (two dots for eyes)
	var eye1 = ColorRect.new()
	eye1.size = Vector2(4, 4)
	eye1.color = Color.WHITE
	eye1.position = Vector2(-size / 2 - 2, -size / 2 - 2)
	visual_container.add_child(eye1)
	
	var eye2 = ColorRect.new()
	eye2.size = Vector2(4, 4)
	eye2.color = Color.WHITE
	eye2.position = Vector2(size / 2 - 2, -size / 2 - 2)
	visual_container.add_child(eye2)


func _on_inventory_changed() -> void:
	"""Update stats when inventory/buffs change."""
	_update_stats_from_buffs()


func _update_stats_from_buffs() -> void:
	"""Apply nutrition buffs to vegetable stats."""
	# Get multipliers from inventory manager
	var damage_mult = InventoryManager.get_stat_multiplier("damage")
	var speed_mult = InventoryManager.get_stat_multiplier("speed")
	var health_mult = InventoryManager.get_stat_multiplier("max_health")
	
	# Apply multipliers to current stats
	base_damage = int(base_damage_value * damage_mult)
	base_speed = base_speed_value * speed_mult
	
	# Update health proportionally if max health changed
	var old_max = max_health
	var new_max = int(base_max_health * health_mult)
	if old_max != new_max and old_max > 0:
		var health_ratio = float(current_health) / float(old_max)
		max_health = new_max
		current_health = int(new_max * health_ratio)
		_update_health_display()
	elif old_max != new_max:
		max_health = new_max
		current_health = new_max
		_update_health_display()


func initialize(type: String, base_hp: int = 30, base_dmg: int = 5, base_spd: float = 100.0) -> void:
	"""Initialize vegetable with type and stats."""
	vegetable_type = type
	base_max_health = base_hp
	max_health = base_hp
	current_health = base_hp
	base_damage_value = base_dmg
	base_damage = base_dmg
	base_speed_value = base_spd
	base_speed = base_spd
	
	_setup_visual()
	_update_stats_from_buffs()  # Apply any existing buffs

