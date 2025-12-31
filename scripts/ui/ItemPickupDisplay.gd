## Item pickup display: shows nice description when item is collected.
extends Control

var display_duration: float = 2.5
var fade_duration: float = 0.3

@onready var item_name_label: Label = $VBox/ItemName
@onready var item_description_label: Label = $VBox/Description
@onready var item_icon: ColorRect = $VBox/IconContainer/Icon


func _ready() -> void:
	"""Initialize the display and hide it initially."""
	hide()
	# Ensure nodes are found
	if not item_name_label:
		item_name_label = get_node_or_null("VBox/ItemName")
	if not item_description_label:
		item_description_label = get_node_or_null("VBox/Description")
	if not item_icon:
		item_icon = get_node_or_null("VBox/IconContainer/Icon")


func show_item(item_data: Dictionary) -> void:
	"""Display item information with animation."""
	if not item_data.has("id"):
		return
	
	# Ensure nodes are ready (in case @onready hasn't initialized yet)
	if not item_name_label:
		item_name_label = get_node_or_null("VBox/ItemName")
	if not item_description_label:
		item_description_label = get_node_or_null("VBox/Description")
	if not item_icon:
		item_icon = get_node_or_null("VBox/IconContainer/Icon")
	
	# Check if nodes exist before setting properties
	if not item_name_label or not item_description_label or not item_icon:
		push_error("ItemPickupDisplay: Missing required UI nodes!")
		return
	
	# Set item name
	var item_name = item_data.get("id", "Unknown").capitalize()
	item_name_label.text = item_name
	
	# Set description based on buffs
	var description = _generate_description(item_data)
	item_description_label.text = description
	
	# Set icon color based on type
	var icon_color = _get_item_color(item_data)
	item_icon.color = icon_color
	
	# Show with animation
	show()
	_play_show_animation()
	
	# Auto-hide after duration
	await get_tree().create_timer(display_duration).timeout
	_play_hide_animation()


func _generate_description(item_data: Dictionary) -> String:
	"""Generate a nice description from item data."""
	var buff = item_data.get("buff", {})
	var multipliers = buff.get("stat_multipliers", {})
	var type = item_data.get("type", "item")
	
	var desc_parts: Array[String] = []
	
	# Add stat changes
	if multipliers.has("damage"):
		var val = multipliers.damage
		if val > 1.0:
			desc_parts.append("+%d%% Damage" % int((val - 1.0) * 100))
		else:
			desc_parts.append("%d%% Damage" % int((val - 1.0) * 100))
	
	if multipliers.has("speed"):
		var val = multipliers.speed
		if val > 1.0:
			desc_parts.append("+%d%% Speed" % int((val - 1.0) * 100))
		else:
			desc_parts.append("%d%% Speed" % int((val - 1.0) * 100))
	
	if multipliers.has("max_health"):
		var val = multipliers.max_health
		if val > 1.0:
			desc_parts.append("+%d%% Health" % int((val - 1.0) * 100))
		else:
			desc_parts.append("%d%% Health" % int((val - 1.0) * 100))
	
	# Add type flavor
	match type:
		"fruit":
			desc_parts.append("Fresh & Healthy!")
		"vegetable":
			desc_parts.append("Nutritious Power!")
		"junk":
			desc_parts.append("Risky but Powerful...")
	
	if desc_parts.is_empty():
		return "Power-up collected!"
	
	return " • ".join(desc_parts)


func _get_item_color(item_data: Dictionary) -> Color:
	"""Get color for item icon."""
	var type = item_data.get("type", "item")
	match type:
		"fruit":
			return Color(1.0, 0.6, 0.2)  # Orange
		"vegetable":
			return Color(0.2, 0.9, 0.4)  # Green
		"junk":
			return Color(0.9, 0.2, 0.3)  # Red
		_:
			return Color(0.6, 0.6, 0.9)  # Purple


func _play_show_animation() -> void:
	"""Play show animation (slide up and fade in)."""
	modulate.a = 0.0
	position.y += 50
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_property(self, "position:y", position.y - 50, fade_duration)
	tween.tween_property(self, "scale", Vector2.ONE, fade_duration).from(Vector2(0.8, 0.8))


func _play_hide_animation() -> void:
	"""Play hide animation (fade out)."""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(self, "position:y", position.y + 30, fade_duration)
	
	await tween.finished
	hide()
