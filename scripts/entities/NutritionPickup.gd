## Nutrition pickup entity: can be collected by player.
extends Area2D

signal picked_up(item_data: Dictionary)

var item_data: Dictionary = {}  # Contains id, type, rarity, buff from JSON
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound

var visual_container: Node2D
var main_shape: ColorRect
var glow_shape: ColorRect
var pulse_tween: Tween


func _ready() -> void:
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	# Create visual container if it doesn't exist
	visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		visual_container = Node2D.new()
		visual_container.name = "VisualContainer"
		add_child(visual_container)
	
	# Visual will be set up in initialize() if item_data is provided
	if not item_data.is_empty():
		_setup_visual()
		_play_spawn_animation()


func initialize(data: Dictionary) -> void:
	item_data = data
	
	# Ensure visual container exists
	if not visual_container:
		visual_container = get_node_or_null("VisualContainer")
		if not visual_container:
			visual_container = Node2D.new()
			visual_container.name = "VisualContainer"
			add_child(visual_container)
	
	_setup_visual()
	_play_spawn_animation()


func _setup_visual() -> void:
	"""Set up visual placeholder based on item type."""
	if item_data.is_empty():
		return
	
	# Clear existing visuals
	for child in visual_container.get_children():
		child.queue_free()
	
	# Determine colors and shape based on item type and rarity
	var base_color: Color
	var shape_type: String = "circle"  # "circle" or "square"
	var size: float = 24.0
	
	if item_data.has("type"):
		match item_data.type:
			"fruit":
				base_color = Color(1.0, 0.6, 0.2)  # Vibrant orange
				shape_type = "circle"
			"vegetable":
				base_color = Color(0.2, 0.9, 0.4)  # Bright green
				shape_type = "square"
			"junk":
				base_color = Color(0.9, 0.2, 0.3)  # Red
				shape_type = "square"
			_:
				base_color = Color(0.6, 0.6, 0.9)  # Purple
				shape_type = "circle"
	else:
		base_color = Color.GREEN
		shape_type = "circle"
	
	# Adjust color based on rarity
	if item_data.has("rarity"):
		match item_data.rarity:
			"rare":
				base_color = base_color.lerp(Color.WHITE, 0.3)
				size = 32.0
			"uncommon":
				base_color = base_color.lerp(Color.WHITE, 0.15)
				size = 28.0
	
	# Create glow effect (outer ring)
	var glow_size = size + 12.0
	glow_shape = ColorRect.new()
	glow_shape.size = Vector2(glow_size, glow_size)
	glow_shape.color = Color(base_color.r, base_color.g, base_color.b, 0.4)
	glow_shape.position = Vector2(-glow_size / 2, -glow_size / 2)
	visual_container.add_child(glow_shape)
	
	# Create main shape
	main_shape = ColorRect.new()
	main_shape.size = Vector2(size, size)
	main_shape.color = base_color
	main_shape.position = Vector2(-size / 2, -size / 2)
	visual_container.add_child(main_shape)
	
	# Add icon/identifier (simple text for now)
	var label = Label.new()
	var item_id = item_data.get("id", "?")
	if item_id.length() > 0:
		label.text = item_id[0].to_upper()
	else:
		label.text = "?"
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-size / 2, -size / 2)
	label.size = Vector2(size, size)
	label.add_theme_color_override("font_color", Color.WHITE)
	visual_container.add_child(label)
	
	# Start pulsing animation
	_start_pulse_animation()


func _play_spawn_animation() -> void:
	"""Play a nice spawn animation (pop in with scale and fade)."""
	if not visual_container:
		return
	
	visual_container.scale = Vector2.ZERO
	visual_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_container, "scale", Vector2.ONE, 0.3)
	tween.tween_property(visual_container, "modulate:a", 1.0, 0.3)
	tween.tween_method(_spawn_bounce, 0.0, 1.0, 0.3)
	
	# Play spawn sound
	_play_spawn_sound()


func _spawn_bounce(progress: float) -> void:
	"""Bounce effect during spawn."""
	if not visual_container:
		return
	var bounce = sin(progress * PI) * 0.2
	visual_container.position.y = -bounce * 20.0


func _start_pulse_animation() -> void:
	"""Start a continuous pulsing glow animation."""
	if not glow_shape:
		return
	
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(glow_shape, "modulate:a", 0.2, 1.0)
	pulse_tween.tween_property(glow_shape, "modulate:a", 0.6, 1.0)


func _play_spawn_sound() -> void:
	"""Play spawn sound effect."""
	# Create a simple beep sound programmatically if no audio file exists
	if not pickup_sound:
		pickup_sound = AudioStreamPlayer2D.new()
		pickup_sound.name = "PickupSound"
		add_child(pickup_sound)
	
	# For now, we'll use a simple beep (can be replaced with actual audio file)
	# This creates a pleasant "pop" sound
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	pickup_sound.stream = stream
	pickup_sound.volume_db = -10
	pickup_sound.pitch_scale = 1.5
	pickup_sound.play()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_collected:
		is_collected = true
		_collect_item()


func _collect_item() -> void:
	"""Handle item collection with animation and sound."""
	if not visual_container:
		# If no visual, just emit and remove
		picked_up.emit(item_data)
		queue_free()
		return
	
	# Play collection animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_container, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(visual_container, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "position:y", position.y - 30, 0.2)
	
	# Play pickup sound
	_play_pickup_sound()
	
	# Emit signal and remove after animation
	await tween.finished
	picked_up.emit(item_data)
	queue_free()


func _play_pickup_sound() -> void:
	"""Play pickup sound effect."""
	# Create pickup sound (can be replaced with actual audio file)
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	if not pickup_sound:
		pickup_sound = AudioStreamPlayer2D.new()
		pickup_sound.name = "PickupSound"
		add_child(pickup_sound)
	
	pickup_sound.stream = stream
	pickup_sound.volume_db = -5
	pickup_sound.pitch_scale = 1.2
	pickup_sound.play()

