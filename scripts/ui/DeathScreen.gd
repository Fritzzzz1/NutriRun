extends CanvasLayer

signal continue_pressed

@export var fade_duration: float = 0.5
@export var text_delay: float = 0.3

var run_stats: Dictionary = {}

@onready var overlay: ColorRect = $Overlay
@onready var container: Control = $Container
@onready var death_label: Label = $Container/VBox/DeathLabel
@onready var stats_container: VBoxContainer = $Container/VBox/StatsContainer
@onready var continue_button: Button = $Container/VBox/ContinueButton


func _ready() -> void:
	overlay.modulate.a = 0
	container.modulate.a = 0
	container.scale = Vector2(0.8, 0.8)
	visible = false
	
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if continue_button:
		var error = continue_button.pressed.connect(_on_continue_pressed)
		if error != OK:
			push_error("Failed to connect continue_button.pressed signal: " + str(error))
	else:
		push_error("DeathScreen: continue_button is null!")


func show_death_screen(stats: Dictionary = {}) -> void:
	"""Show the death screen with run statistics."""
	run_stats = stats
	visible = true
	
	continue_button.visible = true
	continue_button.modulate.a = 1.0
	continue_button.disabled = false
	
	_populate_stats()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(overlay, "modulate:a", 1.0, fade_duration)
	
	tween.tween_property(container, "modulate:a", 1.0, fade_duration).set_delay(text_delay)
	tween.tween_property(container, "scale", Vector2.ONE, fade_duration * 1.5).set_delay(text_delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	_animate_death_text()


func _populate_stats() -> void:
	"""Populate the stats display."""
	for child in stats_container.get_children():
		child.queue_free()
	
	_add_stat_line("Rooms Cleared", str(run_stats.get("rooms_cleared", 0)))
	_add_stat_line("Enemies Defeated", str(run_stats.get("enemies_defeated", 0)))
	_add_stat_line("Items Collected", str(run_stats.get("items_collected", 0)))
	_add_stat_line("Time Survived", _format_time(run_stats.get("time_survived", 0.0)))
	
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 10)
	stats_container.add_child(separator)
	
	var score = _calculate_score()
	_add_stat_line("TOTAL SCORE", str(score), true)


func _add_stat_line(label_text: String, value_text: String, is_highlight: bool = false) -> void:
	"""Add a stat line to the display."""
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_highlight:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if is_highlight:
		value.add_theme_font_size_override("font_size", 24)
		value.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		value.add_theme_font_size_override("font_size", 18)
		value.add_theme_color_override("font_color", Color.WHITE)
	
	hbox.add_child(label)
	hbox.add_child(value)
	stats_container.add_child(hbox)
	
	hbox.modulate.a = 0


func _animate_death_text() -> void:
	"""Animate the death text and stats appearing."""
	var original_pos = death_label.position
	var shake_tween = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-5, 5), randf_range(-3, 3))
		shake_tween.tween_property(death_label, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(death_label, "position", original_pos, 0.05)
	
	await get_tree().create_timer(0.3).timeout
	
	for child in stats_container.get_children():
		var stat_tween = create_tween()
		stat_tween.tween_property(child, "modulate:a", 1.0, 0.2)
		await get_tree().create_timer(0.1).timeout
	
	continue_button.modulate.a = 1.0


func _calculate_score() -> int:
	"""Calculate total score from run stats."""
	var score = 0
	score += run_stats.get("rooms_cleared", 0) * 100
	score += run_stats.get("enemies_defeated", 0) * 25
	score += run_stats.get("items_collected", 0) * 10
	score += int(run_stats.get("time_survived", 0.0)) * 2
	return score


func _format_time(seconds: float) -> String:
	"""Format seconds into MM:SS."""
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]


func _on_continue_pressed() -> void:
	"""Handle continue button press."""
	continue_button.disabled = true
	continue_pressed.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()

