extends Control

@export var bar_width: float = 250.0
@export var bar_height: float = 24.0
@export var nitro_bar_height: float = 16.0
@export var background_color: Color = Color(0.15, 0.15, 0.2, 0.9)
@export var health_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var low_health_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var nitro_color: Color = Color(1.0, 0.85, 0.0, 1.0)
@export var nitro_low_color: Color = Color(0.6, 0.4, 0.0, 1.0)
@export var border_color: Color = Color(0.4, 0.5, 0.6, 1.0)

var player_ref: Node = null
var current_health: int = 100
var max_health: int = 100
var display_health: float = 100.0

var current_nitro: float = 100.0
var max_nitro: float = 100.0
var display_nitro: float = 100.0


func _ready() -> void:
	custom_minimum_size = Vector2(bar_width + 20, bar_height + nitro_bar_height + 60)
	call_deferred("_find_player")


func _process(delta: float) -> void:
	if not player_ref:
		_find_player()
		return

	if "current_health" in player_ref:
		current_health = player_ref.current_health
	if "max_health" in player_ref:
		max_health = player_ref.max_health
	if "nitro_energy" in player_ref:
		current_nitro = player_ref.nitro_energy
	if "nitro_max_energy" in player_ref:
		max_nitro = player_ref.nitro_max_energy

	display_health = lerp(display_health, float(current_health), delta * 10.0)
	display_nitro = lerp(display_nitro, current_nitro, delta * 10.0)

	queue_redraw()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		if player_ref.has_signal("health_changed"):
			if not player_ref.health_changed.is_connected(_on_health_changed):
				player_ref.health_changed.connect(_on_health_changed)
		if player_ref.has_signal("nitro_changed"):
			if not player_ref.nitro_changed.is_connected(_on_nitro_changed):
				player_ref.nitro_changed.connect(_on_nitro_changed)


func _on_health_changed(new_health: int, new_max: int) -> void:
	current_health = new_health
	max_health = new_max


func _on_nitro_changed(new_nitro: float, new_max: float) -> void:
	current_nitro = new_nitro
	max_nitro = new_max


func _draw() -> void:
	var padding = 10.0
	var start_pos = Vector2(padding, 25)
	
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(padding, 18), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.8, 0.9, 0.9))
	
	var bg_rect = Rect2(start_pos, Vector2(bar_width, bar_height))
	draw_rect(bg_rect, background_color)
	
	var health_percent = display_health / max(max_health, 1) if max_health > 0 else 0.0
	health_percent = clamp(health_percent, 0.0, 1.0)
	
	var bar_color: Color
	if health_percent < 0.25:
		bar_color = low_health_color
	elif health_percent < 0.5:
		bar_color = health_color.lerp(low_health_color, (0.5 - health_percent) * 2.0)
	else:
		bar_color = health_color
	
	if health_percent > 0:
		var fill_width = bar_width * health_percent
		var fill_rect = Rect2(start_pos, Vector2(fill_width, bar_height))
		draw_rect(fill_rect, bar_color)
		
		var shine_rect = Rect2(start_pos, Vector2(fill_width, bar_height * 0.4))
		draw_rect(shine_rect, Color(1.0, 1.0, 1.0, 0.15))
	
	draw_rect(bg_rect, border_color, false, 2.0)
	
	var health_text = "%d / %d" % [current_health, max_health]
	var text_pos = Vector2(start_pos.x + bar_width / 2.0 - 30, start_pos.y + bar_height - 6)
	
	draw_string(font, text_pos + Vector2(1, 1), health_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0, 0, 0, 0.7))
	draw_string(font, text_pos, health_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	
	var corner_size = 6.0
	var accent_color = Color(0.5, 0.6, 0.8, 0.8)
	
	draw_line(start_pos, start_pos + Vector2(corner_size, 0), accent_color, 2.0)
	draw_line(start_pos, start_pos + Vector2(0, corner_size), accent_color, 2.0)
	
	var tr = start_pos + Vector2(bar_width, 0)
	draw_line(tr, tr + Vector2(-corner_size, 0), accent_color, 2.0)
	draw_line(tr, tr + Vector2(0, corner_size), accent_color, 2.0)
	
	var bl = start_pos + Vector2(0, bar_height)
	draw_line(bl, bl + Vector2(corner_size, 0), accent_color, 2.0)
	draw_line(bl, bl + Vector2(0, -corner_size), accent_color, 2.0)
	
	var br = start_pos + Vector2(bar_width, bar_height)
	draw_line(br, br + Vector2(-corner_size, 0), accent_color, 2.0)
	draw_line(br, br + Vector2(0, -corner_size), accent_color, 2.0)

	# Draw nitro bar below HP bar
	var nitro_start_pos = Vector2(padding, start_pos.y + bar_height + 18)

	draw_string(font, Vector2(padding, nitro_start_pos.y - 4), "NITRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.4, 0.9))

	var nitro_bg_rect = Rect2(nitro_start_pos, Vector2(bar_width, nitro_bar_height))
	draw_rect(nitro_bg_rect, background_color)

	var nitro_percent = display_nitro / max(max_nitro, 1) if max_nitro > 0 else 0.0
	nitro_percent = clamp(nitro_percent, 0.0, 1.0)

	var nitro_bar_color: Color
	if nitro_percent < 0.2:
		nitro_bar_color = nitro_low_color
	elif nitro_percent < 0.4:
		nitro_bar_color = nitro_color.lerp(nitro_low_color, (0.4 - nitro_percent) * 2.5)
	else:
		nitro_bar_color = nitro_color

	if nitro_percent > 0:
		var nitro_fill_width = bar_width * nitro_percent
		var nitro_fill_rect = Rect2(nitro_start_pos, Vector2(nitro_fill_width, nitro_bar_height))
		draw_rect(nitro_fill_rect, nitro_bar_color)

		var nitro_shine_rect = Rect2(nitro_start_pos, Vector2(nitro_fill_width, nitro_bar_height * 0.4))
		draw_rect(nitro_shine_rect, Color(1.0, 1.0, 1.0, 0.2))

	draw_rect(nitro_bg_rect, Color(0.6, 0.5, 0.2, 0.8), false, 1.5)

