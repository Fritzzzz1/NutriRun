extends Control

@onready var horde_size_button: Button = $VBox/HordeSizeButton
@onready var capacity_button: Button = $VBox/CapacityButton
@onready var points_label: Label = $VBox/PointsLabel

var horde_size_level: int = 0
var capacity_level: int = 0

const HORDE_SIZE_COST = 100
const CAPACITY_COST = 150


func _ready() -> void:
	_update_display()


func _update_display() -> void:
	"""Update upgrade buttons and points display."""
	if points_label:
		points_label.text = "Harvest Points: %d" % GameState.harvest_points
	
	if horde_size_button:
		var cost = HORDE_SIZE_COST * (horde_size_level + 1)
		horde_size_button.text = "Horde Size +1 (Cost: %d)" % cost
		horde_size_button.disabled = GameState.harvest_points < cost or horde_size_level >= 2
	
	if capacity_button:
		var cost = CAPACITY_COST * (capacity_level + 1)
		capacity_button.text = "Inventory Capacity +2 (Cost: %d)" % cost
		capacity_button.disabled = GameState.harvest_points < cost or capacity_level >= 2


func _on_horde_size_pressed() -> void:
	"""Purchase horde size upgrade."""
	var cost = HORDE_SIZE_COST * (horde_size_level + 1)
	if GameState.harvest_points >= cost and horde_size_level < 2:
		GameState.harvest_points -= cost
		horde_size_level += 1
		EventBus.push_notification("Horde size upgraded! (+1 vegetable)")
		_update_display()
		SaveSystem.auto_save()


func _on_capacity_pressed() -> void:
	"""Purchase inventory capacity upgrade."""
	var cost = CAPACITY_COST * (capacity_level + 1)
	if GameState.harvest_points >= cost and capacity_level < 2:
		GameState.harvest_points -= cost
		capacity_level += 1
		InventoryManager.MAX_SLOTS += 2
		InventoryManager._resize_inventory()
		EventBus.push_notification("Inventory capacity upgraded! (+2 slots)")
		_update_display()
		SaveSystem.auto_save()

