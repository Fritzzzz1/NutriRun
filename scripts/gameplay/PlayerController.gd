extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal player_died
signal nitro_changed(current: float, max_energy: float)

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
var push_decay: float = 15.0
var max_push_force: float = 200.0
var player_push_force: float = 50.0

# Nitro boost system
var nitro_energy: float = 100.0
var nitro_max_energy: float = 100.0
var nitro_drain_per_press: float = 8.0
var nitro_drain_while_held: float = 15.0
var nitro_boost_acceleration: float = 600.0
var nitro_max_boost_speed: float = 500.0
var nitro_boost_decay: float = 400.0
var nitro_min_to_activate: float = 5.0
var nitro_pickup_refill: float = 25.0

var nitro_boost_velocity: float = 0.0
var nitro_just_pressed: bool = false
var nitro_last_direction: Vector2 = Vector2.DOWN

var game_balance: Dictionary = {}

@onready var health_bar: ProgressBar = $HealthBar
@onready var nitro_bar: ProgressBar = $NitroBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var exhaust_particles: GPUParticles2D = $ExhaustParticles

# Keep sprite reference for compatibility with existing code (tweens, etc.)
var sprite: AnimatedSprite2D:
	get:
		return animated_sprite

var character_data: Dictionary = {}

# Animation state
var facing_direction: String = "down"
var is_moving: bool = false

var world_bounds: Rect2 = Rect2()
var player_half_size: float = 16.0
var player_collision_radius: float = 16.0
var bounce_force: float = 200.0
var bounce_cooldown: float = 0.0

var entity_scales: Dictionary = {}


func _ready() -> void:
	_load_game_balance()
	_load_character_stats()
	_setup_animations()

	base_max_health = max_health
	base_speed = speed

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if nitro_bar:
		nitro_bar.max_value = nitro_max_energy
		nitro_bar.value = nitro_energy
		# Style nitro bar with yellow color
		var yellow_style = StyleBoxFlat.new()
		yellow_style.bg_color = Color(1.0, 0.85, 0.0)  # Bright yellow
		yellow_style.corner_radius_top_left = 2
		yellow_style.corner_radius_top_right = 2
		yellow_style.corner_radius_bottom_left = 2
		yellow_style.corner_radius_bottom_right = 2
		nitro_bar.add_theme_stylebox_override("fill", yellow_style)
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.15)  # Dark yellowish background
		bg_style.corner_radius_top_left = 2
		bg_style.corner_radius_top_right = 2
		bg_style.corner_radius_bottom_left = 2
		bg_style.corner_radius_bottom_right = 2
		nitro_bar.add_theme_stylebox_override("background", bg_style)

	if exhaust_particles:
		exhaust_particles.emitting = false

	InventoryManager.inventory_changed.connect(_on_inventory_changed)

	call_deferred("_find_world_bounds")

	EventBus.push_notification("Player spawned (HP: %d/%d)" % [current_health, max_health])


func _setup_animations() -> void:
	"""Load spritesheet and create animations."""
	if not animated_sprite:
		return

	# Get spritesheet path based on selected character
	var character_id: String = GameState.selected_character_id
	var spritesheet_path: String
	
	match character_id:
		"monster":
			spritesheet_path = "res://assets/sprites/player/monster-spritesheet.png"
		"lizardman":
			spritesheet_path = "res://assets/sprites/player/lizardman-spritesheet.png"
		_:  # Default to "kid"
			spritesheet_path = "res://assets/sprites/player/character-spritesheet.png"
	
	var spritesheet = load(spritesheet_path)
	if spritesheet:
		var sprite_frames = PlayerAnimationSetup.create_sprite_frames(spritesheet)
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idle_down")


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

				# Load entity scales first
				if game_balance.has("entity_scales"):
					entity_scales = game_balance.entity_scales
					if entity_scales.has("player"):
						var player_scale = entity_scales.player
						player_collision_radius = player_scale.get("collision_radius", 16.0)
						player_half_size = player_scale.get("half_size", 16.0)

				if game_balance.has("player"):
					var player_config = game_balance.player
					base_max_health = player_config.get("base_health", 100)
					max_health = base_max_health
					current_health = max_health
					base_speed = player_config.get("base_speed", 200)
					speed = base_speed
					knockback_force = player_config.get("knockback_force", 200.0)
					knockback_decay = player_config.get("knockback_decay", 10.0)
					invincibility_duration = player_config.get("invincibility_duration", 0.8)
					bounce_force = player_config.get("bounce_force", 100.0)
					push_force = player_config.get("push_force", 150.0)
					push_decay = player_config.get("push_decay", 12.0)
					max_push_force = player_config.get("max_push_force", 400.0)
					player_push_force = player_config.get("player_push_force", 80.0)

				if game_balance.has("nitro"):
					var nitro_config = game_balance.nitro
					nitro_max_energy = nitro_config.get("max_energy", 100.0)
					nitro_energy = nitro_max_energy
					nitro_drain_per_press = nitro_config.get("drain_per_press", 8.0)
					nitro_drain_while_held = nitro_config.get("drain_while_held", 15.0)
					nitro_boost_acceleration = nitro_config.get("boost_acceleration", 600.0)
					nitro_max_boost_speed = nitro_config.get("max_boost_speed", 500.0)
					nitro_boost_decay = nitro_config.get("boost_decay", 400.0)
					nitro_min_to_activate = nitro_config.get("min_energy_to_activate", 5.0)
					nitro_pickup_refill = nitro_config.get("pickup_refill_amount", 25.0)


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
	_handle_nitro_boost(delta)
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

	# Update animation based on input
	_update_animation(input_vector)

	# Update exhaust direction based on movement
	if input_vector.length() > 0:
		_update_exhaust_direction(input_vector)

	# Combine all forces: input, knockback, push, and nitro boost
	var input_velocity = input_vector * speed

	# Apply nitro boost in movement direction
	var boost_velocity = Vector2.ZERO
	if nitro_boost_velocity > 0 and input_vector.length() > 0:
		boost_velocity = input_vector.normalized() * nitro_boost_velocity
	elif nitro_boost_velocity > 0:
		# If boosting but not moving, use last direction
		boost_velocity = nitro_last_direction * nitro_boost_velocity

	velocity = input_velocity + knockback_velocity + push_velocity + boost_velocity

	move_and_slide()

	# Calculate and apply push forces from collisions
	_calculate_push_forces(input_vector, delta)


func _update_animation(input_vector: Vector2) -> void:
	"""Update sprite animation based on movement direction."""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	var was_moving = is_moving
	is_moving = input_vector.length() > 0

	# Update facing direction based on input
	if is_moving:
		# Determine direction - prioritize horizontal for diagonal movement
		if abs(input_vector.x) > abs(input_vector.y):
			facing_direction = "right" if input_vector.x > 0 else "left"
		else:
			facing_direction = "down" if input_vector.y > 0 else "up"

	# Play appropriate animation
	var target_anim: String
	if is_moving:
		target_anim = "walk_" + facing_direction
	else:
		target_anim = "idle_" + facing_direction

	# Only change animation if different (to avoid restarting)
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)


func _apply_knockback(delta: float) -> void:
	"""Decay knockback over time."""
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)


func _handle_nitro_boost(delta: float) -> void:
	"""Handle nitro boost input and energy management."""
	var space_pressed = Input.is_action_pressed("ui_select")
	var space_just_pressed = Input.is_action_just_pressed("ui_select")

	var can_boost = nitro_energy >= nitro_min_to_activate

	if space_pressed and can_boost:
		# Drain energy - extra drain on first press for that "pump" feel
		if space_just_pressed:
			nitro_energy = max(0, nitro_energy - nitro_drain_per_press)
			# Big acceleration burst on press
			nitro_boost_velocity = min(nitro_boost_velocity + nitro_boost_acceleration * 0.5, nitro_max_boost_speed)
		else:
			# Continuous drain while held
			nitro_energy = max(0, nitro_energy - nitro_drain_while_held * delta)

		# Add continuous acceleration while held (builds up speed)
		nitro_boost_velocity = min(nitro_boost_velocity + nitro_boost_acceleration * delta, nitro_max_boost_speed)

		# Start exhaust particles
		if exhaust_particles and not exhaust_particles.emitting:
			exhaust_particles.emitting = true
			_start_boost_visual()
	else:
		# Decay boost speed when not pressing space
		nitro_boost_velocity = max(0, nitro_boost_velocity - nitro_boost_decay * delta)

		# Stop exhaust particles when not boosting
		if exhaust_particles and exhaust_particles.emitting and nitro_boost_velocity < 10:
			exhaust_particles.emitting = false
			_stop_boost_visual()

	# Update UI
	_update_nitro_display()

	# Emit signal for external UI
	nitro_changed.emit(nitro_energy, nitro_max_energy)


func _update_nitro_display() -> void:
	"""Update the nitro bar display."""
	if nitro_bar:
		nitro_bar.value = nitro_energy


func _start_boost_visual() -> void:
	"""Visual effects when starting nitro boost."""
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.2, 1.1, 0.8), 0.1)


func _stop_boost_visual() -> void:
	"""Reset visual effects when stopping nitro boost."""
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _update_exhaust_direction(direction: Vector2) -> void:
	"""Update exhaust particles to emit opposite to movement direction."""
	if not exhaust_particles:
		return

	# Point exhaust opposite to movement
	if direction.length() > 0:
		nitro_last_direction = direction.normalized()

	# Rotate particles to face opposite of movement
	var exhaust_angle = nitro_last_direction.rotated(PI).angle()
	exhaust_particles.rotation = exhaust_angle


func refill_nitro(amount: float) -> void:
	"""Refill nitro energy (called when picking up items)."""
	var old_energy = nitro_energy
	nitro_energy = min(nitro_max_energy, nitro_energy + amount)
	_update_nitro_display()
	nitro_changed.emit(nitro_energy, nitro_max_energy)

	var actual_gain = nitro_energy - old_energy
	if actual_gain > 0 and DamageNumbers:
		DamageNumbers.spawn_at_world_position(int(actual_gain), global_position + Vector2(0, -20), null, false, false, true)


func _calculate_push_forces(player_input: Vector2, delta: float) -> void:
	"""Calculate push forces from directional collisions with enemies."""
	var target_push = Vector2.ZERO
	var collision_count = get_slide_collision_count()

	for i in range(collision_count):
		var collision_data = get_slide_collision(i)
		var collider = collision_data.get_collider()

		if not collider or not collider.is_in_group("enemies"):
			continue

		# Use position-based direction (more reliable than collision normal)
		var push_direction = (global_position - collider.global_position).normalized()

		# Handle edge case where positions are nearly identical
		if push_direction.length() < 0.1:
			push_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

		# Get enemy speed for force calculation
		var enemy_speed = collider.speed if "speed" in collider else 80.0

		# Calculate push force scaled by enemy speed
		var speed_factor = clamp(enemy_speed / 100.0, 0.5, 1.5)
		var push_amount = push_direction * push_force * speed_factor

		# Reduce push if player is actively moving against it
		if player_input.length() > 0:
			var input_vs_push = player_input.normalized().dot(push_direction)
			if input_vs_push < 0:
				# Scale down push based on how much player opposes it
				var resistance_factor = 1.0 + input_vs_push * 0.6
				push_amount *= resistance_factor

		target_push += push_amount

		# Apply counter-push to enemy (push them away from player)
		if collider.has_method("apply_push"):
			var separation_dir = (collider.global_position - global_position).normalized()
			var counter_push = separation_dir * player_push_force * speed_factor * 2.0
			collider.apply_push(counter_push)

	# Cap maximum push force when surrounded
	if target_push.length() > max_push_force:
		target_push = target_push.normalized() * max_push_force

	# Smoothly interpolate toward target push velocity
	if collision_count > 0:
		# While colliding, quickly ramp up to target push
		push_velocity = push_velocity.lerp(target_push, 20.0 * delta)
	else:
		# When not colliding, decay smoothly
		push_velocity = push_velocity.lerp(Vector2.ZERO, push_decay * delta)




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
		
		var original_color = sprite.modulate
		tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.4), 0.05)
		tween.tween_property(sprite, "modulate", original_color, 0.1)


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
	
	var original_color = sprite.modulate
	var tween = create_tween()

	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", original_color, 0.15)


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
