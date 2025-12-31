## Individual inventory slot UI element.
extends PanelContainer

var slot_index: int = -1

@onready var item_label: Label = $VBox/ItemLabel


func set_item(item_data: Dictionary) -> void:
	if item_data.is_empty():
		item_label.text = "Empty"
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		var item_id = item_data.get("id", "Unknown")
		var item_type = item_data.get("type", "")
		item_label.text = item_id.capitalize()
		# Color code by type
		match item_type:
			"fruit":
				modulate = Color(1.0, 0.8, 0.6, 1.0)  # Orange-ish
			"vegetable":
				modulate = Color(0.6, 1.0, 0.6, 1.0)  # Green-ish
			_:
				modulate = Color.WHITE

