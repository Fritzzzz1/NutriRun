extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal player_died

var base_max_health: int = 100
var base_speed: int = 200
var max_health: int = 100
var current_health: int = 100
var speed: int = 200

var is_invincible: bool = false
var debug_invincible: bool = false
var is_dying: bool = false
var invincibility_duration: float = 0.8
var knockback_force: float = 300.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

# Push physics
var push_velocity: Vector2 = Vector2.ZERO
var push_force: float = 1.0
var push_dot_threshold: float = 0.5
var push_decay: float = 15.0
var max_push_force: float = 200.0
var player_push_force: float = 50.0

var game_balance: Dictionary = {}

@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: ColorRect = $Sprite
@onready var hurtbox: Area2D = $Hurtbox

var character_data: Dictionary = {}

var world_bounds: Rect2 = Rect2()
var player_half_size: float = 16.0
var bounce_force: float = 200.0
var bounce_cooldown: float = 0.0


func _ready() -> void:
	_load_game_balance()
	_load_character_stats()

	base_max_health = max_health
	base_speed = speed
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	
	call_deferred("_find_world_bounds")
	
	EventBus.push_notification("Player spawned (HP: %d/%d)" % [current_health, max_health])


func _find_world_bounds() -> void:
	"""Get world bounds from camera controller."""
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0:
		var camera = cameras[0]
		if camera.world_bounds.has_area():
			world_bounds = camera.world_bounds


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

				if game_balance.has("player"):
					var player_config = game_balance.player
					base_max_health = player_config.get("base_health", 100)
					max_health = base_max_health
					current_health = max_health
					base_speed = player_config.get("base_speed", 200)
					speed = base_speed
					knockback_force = player_config.get("knockback_force", 300.0)
					knockback_decay = player_config.get("knockback_decay", 10.0)
					invincibility_duration = player_config.get("invincibility_duration", 0.8)
					bounce_force = player_config.get("bounce_force", 200.0)
					push_force = player_config.get("push_force", 250.0)
					push_dot_threshold = player_config.get("push_dot_threshold", 0.5)
					push_decay = player_config.get("push_decay", 15.0)
					max_push_force = player_config.get("max_push_force", 400.0)
					player_push_force = player_config.get("player_push_force", 50.0)


func _load_character_stats() -> void:
	var char_id: String = GameState.selected_character_id
	
	var char_stats_path = "res://assets/data/character_stats.json"
	if ResourceLoader.exists(char_stats_path):
		var file = FileAccess.open(char_stats_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse_string(file.get_as_text())
			file.close()
			
			if parse_result and parse_result.has("characters"):
				for char in parse_result.characters:
					if char.id == char_id:
						character_data = char
						max_health = char.get("hp", 100)
						current_health = max_health
						speed = char.get("speed", 20) * 10
						break

	if character_data.is_empty():
		max_health = 100
		current_health = 100
		speed = 200


func _on_inventory_changed() -> void:
	"""Update player stats based on active buffs."""
	var health_multiplier = InventoryManager.get_stat_multiplier("max_health")
	var new_max_health = int(base_max_health * health_multiplier)
	
	if max_health > 0:
		var health_ratio = float(current_health) / float(max_health)
		current_health = int(new_max_health * health_ratio)
	
	max_health = new_max_health
	
	var speed_multiplier = InventoryManager.get_stat_multiplier("speed")
	speed = int(base_speed * speed_multiplier)
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _physics_process(delta: float) -> void:
	_apply_knockback(delta)
	_handle_movement(delta)
	_clamp_to_world_bounds()

	if bounce_cooldown > 0:
		bounce_cooldown -= delta


func _handle_movement(delta: float) -> void:
	var input_vector := Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

	# Combine all forces: input, knockback, and push
	var input_velocity = input_vector * speed
	velocity = input_velocity + knockback_velocity + push_velocity

	print("[PUSH DEBUG] Before move_and_slide - push_velocity: %s, total velocity: %s" % [push_velocity, velocity])

	move_and_slide()

	# Calculate push forces from collisions and immediately apply for next iteration
	_calculate_push_forces()

	# Decay push when not colliding (will be overwritten if collision detected above)
	if get_slide_collision_count() == 0:
		push_velocity = push_velocity.lerp(Vector2.ZERO, push_decay * delta)
		if push_velocity.length() > 0.1:
			print("[PUSH DEBUG] Decaying push_velocity: %s" % push_velocity)

	print("[PUSH DEBUG] End of frame - push_velocity: %s" % push_velocity)


func _apply_knockback(delta: float) -> void:
	"""Decay knockback over time."""
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)


func _calculate_push_forces() -> void:
	"""Calculate push forces from directional collisions with enemies."""
	var accumulated_push = Vector2.ZERO
	var collision_count = get_slide_collision_count()

	if collision_count > 0:
		print("[PUSH DEBUG] Total collisions: %d" % collision_count)

	for i in range(collision_count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		print("[PUSH DEBUG] Collision %d: collider=%s, is_enemy=%s" % [
			i,
			collider.name if collider else "null",
			collider.is_in_group("enemies") if collider else false
		])

		if not collider or not collider.is_in_group("enemies"):
			continue

		# Get enemy movement direction and speed
		# IMPORTANT: Don't use collider.velocity - it's modified by move_and_slide()
		# Use last_movement_direction which stores the enemy's intended direction
		var enemy_direction = Vector2.ZERO
		var enemy_speed = 0.0

		if "last_movement_direction" in collider and "speed" in collider:
			enemy_direction = collider.last_movement_direction
			enemy_speed = collider.speed

		print("[PUSH DEBUG] Enemy direction: %s, speed: %.2f" % [enemy_direction, enemy_speed])

		if enemy_direction.length_squared() < 0.01:
			print("[PUSH DEBUG] Enemy not moving, skipping")
			continue

		var enemy_vel_norm = enemy_direction.normalized()

		# Simple approach: Push player in the direction the enemy is moving
		# Scale push by enemy speed
		var speed_factor = min(enemy_speed / 100.0, 1.5)
		var push_amount = enemy_vel_norm * push_force * speed_factor
		accumulated_push += push_amount

		print("[PUSH DEBUG] PUSH APPLIED! enemy_vel_norm: %s, speed_factor: %.2f, push_amount: %s, total: %s" % [
			enemy_vel_norm,
			speed_factor,
			push_amount,
			accumulated_push
		])

		# Apply minor counter-push to enemy
		if collider.has_method("apply_push"):
			var counter_push = -enemy_vel_norm * player_push_force * speed_factor
			collider.apply_push(counter_push)

	# Cap maximum push force when surrounded
	if accumulated_push.length() > max_push_force:
		accumulated_push = accumulated_push.normalized() * max_push_force

	print("[PUSH DEBUG] Final accumulated_push: %s, push_velocity set to: %s" % [accumulated_push, accumulated_push])

	# Set push velocity for next frame
	push_velocity = accumulated_push




func _clamp_to_world_bounds() -> void:
	"""Keep player within world boundaries with bounce effect."""
	if not world_bounds.has_area():
		return
	
	var min_x = world_bounds.position.x + player_half_size
	var max_x = world_bounds.position.x + world_bounds.size.x - player_half_size
	var min_y = world_bounds.position.y + player_half_size
	var max_y = world_bounds.position.y + world_bounds.size.y - player_half_size
	
	var bounce_dir = Vector2.ZERO
	var hit_boundary = false
	
	if global_position.x < min_x:
		global_position.x = min_x
		bounce_dir.x = 1.0
		hit_boundary = true
	elif global_position.x > max_x:
		global_position.x = max_x
		bounce_dir.x = -1.0
		hit_boundary = true
	
	if global_position.y < min_y:
		global_position.y = min_y
		bounce_dir.y = 1.0
		hit_boundary = true
	elif global_position.y > max_y:
		global_position.y = max_y
		bounce_dir.y = -1.0
		hit_boundary = true
	
	if hit_boundary and bounce_cooldown <= 0:
		_apply_boundary_bounce(bounce_dir.normalized())
		bounce_cooldown = 0.3


func _apply_boundary_bounce(direction: Vector2) -> void:
	"""Apply a bounce effect when hitting world boundary."""
	knockback_velocity = direction * bounce_force
	
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		
		var squeeze_scale: Vector2
		if abs(direction.x) > abs(direction.y):
			squeeze_scale = Vector2(0.7, 1.3)
		else:
			squeeze_scale = Vector2(1.3, 0.7)
		
		tween.tween_property(sprite, "scale", squeeze_scale, 0.05)
		tween.chain().tween_property(sprite, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		
		var original_color = sprite.color
		tween.tween_property(sprite, "color", Color(1.0, 0.8, 0.4), 0.05)
		tween.tween_property(sprite, "color", original_color, 0.1)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	"""Handle collision with enemy hitbox."""
	if is_invincible:
		return
	
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		var damage = parent.damage if "damage" in parent else 10
		var knockback_dir = (global_position - parent.global_position).normalized()
		take_damage(damage, knockback_dir)


func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_dying:
		return
	
	current_health = max(0, current_health - amount)
	_update_health_display()
	health_changed.emit(current_health, max_health)
	
	# Check for death only if debug invincibility is not enabled
	if current_health <= 0 and not debug_invincible:
		_die()
		return
	
	if DamageNumbers:
		DamageNumbers.spawn_at_world_position(amount, global_position + Vector2(0, -20))
	
	if knockback_direction != Vector2.ZERO:
		knockback_velocity = knockback_direction * knockback_force
	
	_flash_damage()
	_start_invincibility()


func _flash_damage() -> void:
	"""Flash red/white when taking damage."""
	if not sprite:
		return
	
	var original_color = sprite.color
	var tween = create_tween()
	
	tween.tween_property(sprite, "color", Color.WHITE, 0.05)
	tween.tween_property(sprite, "color", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "color", original_color, 0.15)


func _start_invincibility() -> void:
	"""Start invincibility frames with flashing effect."""
	is_invincible = true
	
	var flash_tween = create_tween()
	flash_tween.set_loops(int(invincibility_duration / 0.15))
	flash_tween.tween_property(sprite, "modulate:a", 0.3, 0.075)
	flash_tween.tween_property(sprite, "modulate:a", 1.0, 0.075)
	
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false
	
	if sprite:
		sprite.modulate.a = 1.0


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	_update_health_display()
	health_changed.emit(current_health, max_health)
	
	if DamageNumbers:
		DamageNumbers.spawn_at_world_position(amount, global_position + Vector2(0, -20), null, false, true)


func _update_health_display() -> void:
	if health_bar:
		health_bar.value = current_health


func _die() -> void:
	"""Handle player death with animation."""
	if is_dying:
		return
	is_dying = true
	is_invincible = true
	
	EventBus.push_notification("Player died!")
	
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	
	set_physics_process(false)
	
	player_died.emit()
	
	_play_death_animation()


func _play_death_animation() -> void:
	"""Play death animation sequence (non-blocking)."""
	if not sprite:
		return
	
	var flash_tween = create_tween()
	for i in range(6):
		flash_tween.tween_property(sprite, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.05)
		flash_tween.tween_property(sprite, "modulate", Color(0.3, 0.1, 0.1, 1.0), 0.05)
	await flash_tween.finished
	
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.4).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	death_tween.tween_property(sprite, "rotation", randf_range(-0.5, 0.5), 0.4)
	
	death_tween.tween_property(self, "position:y", position.y - 30, 0.4).set_ease(Tween.EASE_OUT)


func set_debug_invincible(enabled: bool) -> void:
	"""Set debug invincibility mode."""
	debug_invincible = enabled
	if enabled:
		EventBus.push_notification("Debug: Invincibility enabled")
	else:
		EventBus.push_notification("Debug: Invincibility disabled")
