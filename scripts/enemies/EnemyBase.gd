extends CharacterBody2D

signal enemy_died
signal enemy_hit_player

var max_health: int = 50
var current_health: int = 50
var speed: float = 80.0
var damage: int = 10
var attack_cooldown: float = 0.3
var attack_timer: float = 0.0
var last_movement_direction: Vector2 = Vector2.ZERO

# Push physics
var push_velocity: Vector2 = Vector2.ZERO
var push_resistance: float = 0.4

# Separation physics (prevents sticking to player)
var separation_velocity: Vector2 = Vector2.ZERO
var min_separation_distance: float = 20.0
var separation_force: float = 250.0
var separation_distance_multiplier: float = 2.5

var can_shoot: bool = true
var projectile_speed: float = 250.0
var shoot_range: float = 300.0
var shoot_cooldown: float = 2.0
var shoot_timer: float = 0.0

var game_balance: Dictionary = {}
var entity_scales: Dictionary = {}

var player_ref: Node2D = null
var is_active: bool = true

# Scale-based configuration (loaded from game_balance.json)
var enemy_collision_radius: float = 8.0
var enemy_sprite_scale: float = 0.04
var enemy_hitbox_radius: float = 12.0
var player_collision_radius: float = 16.0
var projectile_collision_radius: float = 3.0
var projectile_visual_size: float = 6.0
var projectile_glow_size: float = 8.0

@onready var health_bar: ProgressBar = $HealthBar
var visual_container: Node2D = null
@onready var collision: CollisionShape2D = $CollisionShape2D
var hitbox: Area2D = null


func _ready() -> void:
	_load_game_balance()
	current_health = max_health

	collision_layer = 4
	collision_mask = 1 + 2  # Collide with walls (layer 1) and player (layer 2)

	visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		visual_container = Node2D.new()
		visual_container.name = "VisualContainer"
		add_child(visual_container)

	_setup_visual()
	_setup_hitbox()
	_find_player()

	add_to_group("enemies")

	shoot_timer = randf_range(0.5, shoot_cooldown)


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	attack_timer -= delta
	shoot_timer -= delta

	# Decay push velocity (from player pushing enemy)
	push_velocity = push_velocity.lerp(Vector2.ZERO, 15.0 * delta)

	# Decay separation velocity (from collision response)
	separation_velocity = separation_velocity.lerp(Vector2.ZERO, 10.0 * delta)

	if player_ref and is_instance_valid(player_ref):
		var direction = (player_ref.global_position - global_position).normalized()
		var distance = global_position.distance_to(player_ref.global_position)

		last_movement_direction = direction

		# Always chase the player - let collision physics handle separation
		var chase_velocity = direction * speed

		# Combine velocities: chase + push from player + separation from collision
		velocity = chase_velocity + push_velocity + separation_velocity
		move_and_slide()

		# Apply separation ONLY when actually colliding (post-collision response)
		_handle_player_collision_separation()

		if can_shoot and shoot_timer <= 0 and distance < shoot_range and distance > 50:
			_shoot_projectile(direction)
			shoot_timer = shoot_cooldown

		_check_contact_damage()
	else:
		_find_player()


func _handle_player_collision_separation() -> void:
	"""Check for direct collision with player and apply strong separation."""
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("player"):
			# We're physically colliding with player - apply immediate separation
			var separation_dir = (global_position - collider.global_position).normalized()

			# If positions are nearly identical, pick a random direction
			if separation_dir.length() < 0.1:
				separation_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

			# Apply strong separation impulse
			separation_velocity = separation_dir * separation_force * 1.5
			break


func _shoot_projectile(direction: Vector2) -> void:
	"""Fire a projectile at the player."""
	var projectile = _create_projectile()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = damage
	
	get_parent().add_child(projectile)
	
	_shoot_animation()


func _create_projectile() -> Node2D:
	"""Create an enemy projectile."""
	var proj = Area2D.new()
	proj.name = "EnemyProjectile"
	proj.add_to_group("enemy_projectiles")
	
	proj.collision_layer = 16
	proj.collision_mask = 8
	proj.monitoring = true
	
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = projectile_collision_radius
	collision_shape.shape = shape
	proj.add_child(collision_shape)

	var vis_size = projectile_visual_size
	var visual = ColorRect.new()
	visual.size = Vector2(vis_size, vis_size)
	visual.position = Vector2(-vis_size / 2, -vis_size / 2)
	visual.color = Color(1.0, 0.3, 0.1)
	proj.add_child(visual)

	var glow_size = projectile_glow_size
	var glow = ColorRect.new()
	glow.size = Vector2(glow_size, glow_size)
	glow.position = Vector2(-glow_size / 2, -glow_size / 2)
	glow.color = Color(1.0, 0.5, 0.2, 0.5)
	glow.z_index = -1
	proj.add_child(glow)
	
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 10
var lifetime: float = 4.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		if parent.has_method("take_damage"):
			var knockback_dir = direction
			parent.take_damage(damage, knockback_dir)
		_destroy()

func _destroy() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished
	queue_free()
"""
	script.reload()
	proj.set_script(script)
	
	return proj


func _shoot_animation() -> void:
	"""Visual feedback when enemy shoots."""
	if not visual_container:
		return
	
	var tween = create_tween()
	tween.tween_property(visual_container, "modulate", Color(1.5, 1.0, 0.5), 0.1)
	tween.tween_property(visual_container, "modulate", Color.WHITE, 0.2)


func _load_game_balance() -> void:
	"""Load game balance settings from JSON config."""
	var balance_path = "res://assets/data/game_balance.json"
	if ResourceLoader.exists(balance_path):
		var file = FileAccess.open(balance_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse_string(file.get_as_text())
			file.close()

			if parse_result:
				game_balance = parse_result

				# Load entity scales first
				if game_balance.has("entity_scales"):
					entity_scales = game_balance.entity_scales
					_apply_entity_scales()

				if game_balance.has("enemy"):
					var enemy_config = game_balance.enemy
					max_health = enemy_config.get("base_health", 50)
					speed = enemy_config.get("base_speed", 80.0)
					damage = enemy_config.get("base_damage", 10)
					attack_cooldown = enemy_config.get("attack_cooldown", 0.3)
					projectile_speed = enemy_config.get("projectile_speed", 250.0)
					shoot_range = enemy_config.get("shoot_range", 300.0)
					shoot_cooldown = enemy_config.get("shoot_cooldown", 2.0)
					push_resistance = enemy_config.get("push_resistance", 0.4)
					separation_distance_multiplier = enemy_config.get("min_separation_distance_multiplier", 2.5)
					separation_force = enemy_config.get("separation_force", 250.0)

				# Calculate min_separation_distance based on entity sizes
				min_separation_distance = (player_collision_radius + enemy_collision_radius) * separation_distance_multiplier


func _apply_entity_scales() -> void:
	"""Apply entity scale configuration."""
	if entity_scales.has("enemy"):
		var enemy_scale = entity_scales.enemy
		enemy_collision_radius = enemy_scale.get("collision_radius", 8.0)
		enemy_sprite_scale = enemy_scale.get("sprite_scale", 0.04)
		enemy_hitbox_radius = enemy_scale.get("hitbox_radius", 12.0)

	if entity_scales.has("player"):
		var player_scale = entity_scales.player
		player_collision_radius = player_scale.get("collision_radius", 16.0)

	if entity_scales.has("projectile"):
		var proj_scale = entity_scales.projectile
		projectile_collision_radius = proj_scale.get("collision_radius", 3.0)
		projectile_visual_size = proj_scale.get("visual_size", 6.0)
		projectile_glow_size = proj_scale.get("glow_size", 8.0)


func _find_player() -> void:
	"""Find the player in the scene."""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _setup_visual() -> void:
	"""Set up enemy visual representation using sprite."""
	var sprite = Sprite2D.new()
	sprite.name = "EnemySprite"

	# Load the bacteria sprite texture
	var texture = load("res://assets/sprites/enemy/enemy_bacteria_2.png")
	if texture:
		sprite.texture = texture
		# Use scale from config
		sprite.scale = Vector2(enemy_sprite_scale, enemy_sprite_scale)
	else:
		# Fallback to colored rectangle if texture not found
		var fallback_size = enemy_collision_radius * 2
		var fallback = ColorRect.new()
		fallback.size = Vector2(fallback_size, fallback_size)
		fallback.color = Color(0.9, 0.3, 0.3)
		fallback.position = Vector2(-fallback_size / 2, -fallback_size / 2)
		visual_container.add_child(fallback)
		return

	visual_container.add_child(sprite)


func _setup_hitbox() -> void:
	"""Set up the hitbox Area2D for detecting collision with player hurtbox."""
	hitbox = get_node_or_null("Hitbox")
	if not hitbox:
		hitbox = Area2D.new()
		hitbox.name = "Hitbox"

		hitbox.collision_layer = 16
		hitbox.collision_mask = 8
		hitbox.monitoring = true
		hitbox.monitorable = true

		var hitbox_collision = CollisionShape2D.new()
		var hitbox_shape = CircleShape2D.new()
		hitbox_shape.radius = enemy_hitbox_radius
		hitbox_collision.shape = hitbox_shape
		hitbox.add_child(hitbox_collision)

		add_child(hitbox)
	


func _check_contact_damage() -> void:
	"""Check for continuous contact damage with player."""
	if attack_timer > 0 or not is_active or not hitbox:
		return

	var overlapping_areas = hitbox.get_overlapping_areas()
	for area in overlapping_areas:
		var player = area.get_parent()
		if player and player.is_in_group("player"):
			_deal_contact_damage(player)
			break


func _deal_contact_damage(player: Node2D) -> void:
	"""Deal contact damage to the player and push them in enemy's movement direction."""
	if player.has_method("take_damage"):
		var push_direction = last_movement_direction if last_movement_direction != Vector2.ZERO else (player.global_position - global_position).normalized()
		player.take_damage(damage, push_direction)
		enemy_hit_player.emit()
		attack_timer = attack_cooldown

		_attack_animation()


func _attack_animation() -> void:
	"""Visual feedback when enemy attacks."""
	if not visual_container:
		return
	
	var tween = create_tween()
	tween.tween_property(visual_container, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.2)


func take_damage(amount: int) -> void:
	"""Take damage and update health."""
	current_health = max(0, current_health - amount)
	_update_health_display()
	
	if DamageNumbers:
		var is_crit = amount >= 20
		var damage_offset = -(enemy_hitbox_radius + 4)
		DamageNumbers.spawn_at_world_position(amount, global_position + Vector2(0, damage_offset), null, is_crit)
	
	_flash_damage()
	
	if current_health <= 0:
		_die()


func _flash_damage() -> void:
	"""Flash red when taking damage."""
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


func apply_push(push_force: Vector2) -> void:
	"""Apply a push force to this enemy (from player collision)."""
	push_velocity += push_force * push_resistance


func _die() -> void:
	"""Handle enemy death."""
	is_active = false
	enemy_died.emit()

	if hitbox:
		hitbox.set_deferred("monitoring", false)

	if visual_container:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(visual_container, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(visual_container, "modulate:a", 0.0, 0.3)
		tween.tween_property(self, "position:y", position.y - 20, 0.3)
		await tween.finished

	queue_free()
