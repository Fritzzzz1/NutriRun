## PlayerHealthUI: Displays player health bar with exact numbers.
extends Control

@export var bar_width: float = 250.0
@export var bar_height: float = 24.0
@export var background_color: Color = Color(0.15, 0.15, 0.2, 0.9)
@export var health_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var low_health_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var border_color: Color = Color(0.4, 0.5, 0.6, 1.0)

var player_ref: Node = null
var current_health: int = 100
var max_health: int = 100
var display_health: float = 100.0  # For smooth animation


func _ready() -> void:
	custom_minimum_size = Vector2(bar_width + 20, bar_height + 40)
	call_deferred("_find_player")


func _process(delta: float) -> void:
	if not player_ref:
		_find_player()
		return
	
	# Update health values from player
	if "current_health" in player_ref:
		current_health = player_ref.current_health
	if "max_health" in player_ref:
		max_health = player_ref.max_health
	
	# Smooth health bar animation
	display_health = lerp(display_health, float(current_health), delta * 10.0)
	
	queue_redraw()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		# Connect to health changed signal if available
		if player_ref.has_signal("health_changed"):
			if not player_ref.health_changed.is_connected(_on_health_changed):
				player_ref.health_changed.connect(_on_health_changed)


func _on_health_changed(new_health: int, new_max: int) -> void:
	current_health = new_health
	max_health = new_max


func _draw() -> void:
	var padding = 10.0
	var start_pos = Vector2(padding, 25)
	
	# Draw "HP" label
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(padding, 18), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.8, 0.9, 0.9))
	
	# Draw background
	var bg_rect = Rect2(start_pos, Vector2(bar_width, bar_height))
	draw_rect(bg_rect, background_color)
	
	# Calculate health percentage
	var health_percent = display_health / max(max_health, 1) if max_health > 0 else 0.0
	health_percent = clamp(health_percent, 0.0, 1.0)
	
	# Determine bar color based on health
	var bar_color: Color
	if health_percent < 0.25:
		bar_color = low_health_color
	elif health_percent < 0.5:
		bar_color = health_color.lerp(low_health_color, (0.5 - health_percent) * 2.0)
	else:
		bar_color = health_color
	
	# Draw health bar fill
	if health_percent > 0:
		var fill_width = bar_width * health_percent
		var fill_rect = Rect2(start_pos, Vector2(fill_width, bar_height))
		draw_rect(fill_rect, bar_color)
		
		# Draw shine effect on top of bar
		var shine_rect = Rect2(start_pos, Vector2(fill_width, bar_height * 0.4))
		draw_rect(shine_rect, Color(1.0, 1.0, 1.0, 0.15))
	
	# Draw border
	draw_rect(bg_rect, border_color, false, 2.0)
	
	# Draw health numbers (current / max)
	var health_text = "%d / %d" % [current_health, max_health]
	var text_pos = Vector2(start_pos.x + bar_width / 2.0 - 30, start_pos.y + bar_height - 6)
	
	# Draw text shadow
	draw_string(font, text_pos + Vector2(1, 1), health_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0, 0, 0, 0.7))
	# Draw text
	draw_string(font, text_pos, health_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	
	# Draw corner accents
	var corner_size = 6.0
	var accent_color = Color(0.5, 0.6, 0.8, 0.8)
	
	# Top-left
	draw_line(start_pos, start_pos + Vector2(corner_size, 0), accent_color, 2.0)
	draw_line(start_pos, start_pos + Vector2(0, corner_size), accent_color, 2.0)
	
	# Top-right
	var tr = start_pos + Vector2(bar_width, 0)
	draw_line(tr, tr + Vector2(-corner_size, 0), accent_color, 2.0)
	draw_line(tr, tr + Vector2(0, corner_size), accent_color, 2.0)
	
	# Bottom-left
	var bl = start_pos + Vector2(0, bar_height)
	draw_line(bl, bl + Vector2(corner_size, 0), accent_color, 2.0)
	draw_line(bl, bl + Vector2(0, -corner_size), accent_color, 2.0)
	
	# Bottom-right
	var br = start_pos + Vector2(bar_width, bar_height)
	draw_line(br, br + Vector2(-corner_size, 0), accent_color, 2.0)
	draw_line(br, br + Vector2(0, -corner_size), accent_color, 2.0)

