## Player controller: handles movement, health, and basic player state.
extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal player_died

var base_max_health: int = 100
var base_speed: int = 200
var max_health: int = 100
var current_health: int = 100
var speed: int = 200

@onready var health_bar: ProgressBar = $HealthBar

# Character stats from GameState
var character_data: Dictionary = {}


func _ready() -> void:
	# Load character stats from GameState
	_load_character_stats()
	
	# Store base stats
	base_max_health = max_health
	base_speed = speed
	
	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Connect to inventory changes to update stats
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	
	EventBus.push_notification("Player spawned (HP: %d/%d)" % [current_health, max_health])


func _load_character_stats() -> void:
	# Get selected character from GameState
	var char_id: String = GameState.selected_character_id
	
	# Load character data from JSON (placeholder - will be replaced with proper data loading)
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
						speed = char.get("speed", 200) * 10  # Convert to pixels/second
						# Apply 1.5x speed multiplier
						speed = int(speed * 1.5)
						break
	
	# Fallback if no data found
	if character_data.is_empty():
		max_health = 100
		current_health = 100
		speed = 200
	
	# Apply 1.5x speed multiplier to all cases
	speed = int(speed * 1.5)


func _on_inventory_changed() -> void:
	"""Update player stats based on active buffs."""
	# Recalculate max health with multipliers
	var health_multiplier = InventoryManager.get_stat_multiplier("max_health")
	var new_max_health = int(base_max_health * health_multiplier)
	
	# Adjust current health proportionally
	if max_health > 0:
		var health_ratio = float(current_health) / float(max_health)
		current_health = int(new_max_health * health_ratio)
	
	max_health = new_max_health
	
	# Update speed with multipliers
	var speed_multiplier = InventoryManager.get_stat_multiplier("speed")
	speed = int(base_speed * speed_multiplier)
	
	# Update health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _physics_process(delta: float) -> void:
	_handle_movement(delta)


func _handle_movement(delta: float) -> void:
	var input_vector := Vector2.ZERO
	
	# WASD movement
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()


func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	_update_health_display()
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	_update_health_display()
	health_changed.emit(current_health, max_health)


func _update_health_display() -> void:
	if health_bar:
		health_bar.value = current_health


func _die() -> void:
	EventBus.push_notification("Player died!")
	player_died.emit()
	# Future: Handle death logic (return to hub, show game over, etc.)

