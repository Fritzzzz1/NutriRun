## Base enemy class: handles movement, health, and combat.
extends CharacterBody2D

signal enemy_died
signal enemy_hit_player

var max_health: int = 50
var current_health: int = 50
var speed: float = 80.0
var damage: int = 5
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

var player_ref: Node2D = null
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
	
	# Add to enemies group
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	attack_timer -= delta
	
	# Simple AI: move towards player
	if player_ref and is_instance_valid(player_ref):
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Check if close enough to attack
		var distance = global_position.distance_to(player_ref.global_position)
		if distance < 40.0 and attack_timer <= 0.0:
			_attack_player()
			attack_timer = attack_cooldown
	else:
		_find_player()


func _find_player() -> void:
	"""Find the player in the scene."""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _setup_visual() -> void:
	"""Set up enemy visual representation."""
	# Create a simple enemy shape (red/purple to distinguish from items)
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


func take_damage(amount: int) -> void:
	"""Take damage and update health."""
	current_health = max(0, current_health - amount)
	_update_health_display()
	
	# Flash red when hit
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


func _attack_player() -> void:
	"""Attack the player if in range."""
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)
		enemy_hit_player.emit()


func _die() -> void:
	"""Handle enemy death."""
	is_active = false
	enemy_died.emit()
	
	# Death animation
	if visual_container:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(visual_container, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(visual_container, "modulate:a", 0.0, 0.3)
		tween.tween_property(self, "position:y", position.y - 20, 0.3)
		await tween.finished
	
	queue_free()

