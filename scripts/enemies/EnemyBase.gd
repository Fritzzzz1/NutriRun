extends CharacterBody2D

signal enemy_died
signal enemy_hit_player

var max_health: int = 50
var current_health: int = 50
var speed: float = 80.0
var damage: int = 10
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

var can_shoot: bool = true
var projectile_speed: float = 250.0
var shoot_range: float = 300.0
var shoot_cooldown: float = 2.0
var shoot_timer: float = 0.0

var player_ref: Node2D = null
var is_active: bool = true

@onready var health_bar: ProgressBar = $HealthBar
var visual_container: Node2D = null
@onready var collision: CollisionShape2D = $CollisionShape2D
var hitbox: Area2D = null


func _ready() -> void:
	current_health = max_health
	
	collision_layer = 4
	collision_mask = 1
	
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
	
	if player_ref and is_instance_valid(player_ref):
		var direction = (player_ref.global_position - global_position).normalized()
		var distance = global_position.distance_to(player_ref.global_position)
		
		velocity = direction * speed
		move_and_slide()
		
		if can_shoot and shoot_timer <= 0 and distance < shoot_range and distance > 50:
			_shoot_projectile(direction)
			shoot_timer = shoot_cooldown
	else:
		_find_player()


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
	shape.radius = 6.0
	collision_shape.shape = shape
	proj.add_child(collision_shape)
	
	var visual = ColorRect.new()
	visual.size = Vector2(12, 12)
	visual.position = Vector2(-6, -6)
	visual.color = Color(1.0, 0.3, 0.1)
	proj.add_child(visual)
	
	var glow = ColorRect.new()
	glow.size = Vector2(16, 16)
	glow.position = Vector2(-8, -8)
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


func _find_player() -> void:
	"""Find the player in the scene."""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _setup_visual() -> void:
	"""Set up enemy visual representation."""
	var enemy_size = 32.0
	
	# Outer glow
	var glow = ColorRect.new()
	glow.size = Vector2(enemy_size + 8, enemy_size + 8)
	glow.color = Color(0.8, 0.2, 0.2, 0.5)
	glow.position = Vector2(-(enemy_size + 8) / 2, -(enemy_size + 8) / 2)
	visual_container.add_child(glow)
	
	# Main body (diamond shape using rotated square)
	var body = ColorRect.new()
	body.size = Vector2(enemy_size, enemy_size)
	body.color = Color(0.9, 0.3, 0.3)
	body.position = Vector2(-enemy_size / 2, -enemy_size / 2)
	body.rotation_degrees = 45
	visual_container.add_child(body)
	
	# Eyes (simple dots)
	var eye1 = ColorRect.new()
	eye1.size = Vector2(6, 6)
	eye1.color = Color.WHITE
	eye1.position = Vector2(-enemy_size / 2 - 4, -enemy_size / 2 - 4)
	visual_container.add_child(eye1)
	
	var eye2 = ColorRect.new()
	eye2.size = Vector2(6, 6)
	eye2.color = Color.WHITE
	eye2.position = Vector2(enemy_size / 2 - 2, -enemy_size / 2 - 4)
	visual_container.add_child(eye2)


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
		hitbox_shape.radius = 24.0
		hitbox_collision.shape = hitbox_shape
		hitbox.add_child(hitbox_collision)
		
		add_child(hitbox)
	
	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _on_hitbox_area_entered(area: Area2D) -> void:
	"""Handle when hitbox overlaps with player hurtbox (contact damage)."""
	if attack_timer > 0 or not is_active:
		return
	
	var player = area.get_parent()
	if player and player.is_in_group("player"):
		_deal_contact_damage(player)


func _deal_contact_damage(player: Node2D) -> void:
	"""Deal contact damage to the player."""
	if player.has_method("take_damage"):
		var knockback_dir = (player.global_position - global_position).normalized()
		player.take_damage(damage, knockback_dir)
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
		DamageNumbers.spawn_at_world_position(amount, global_position + Vector2(0, -20), null, is_crit)
	
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
