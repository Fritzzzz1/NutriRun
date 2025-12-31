## Inventory UI controller: displays player's inventory slots.
extends Control

@onready var slots_container: GridContainer = $VBox/SlotsContainer
@onready var synergy_label: Label = $VBox/SynergyLabel

const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")


func _ready() -> void:
	# Create 8 inventory slots
	for i in range(InventoryManager.MAX_SLOTS):
		var slot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		slots_container.add_child(slot)
	
	# Connect to inventory changes
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	InventoryManager.item_added.connect(_on_item_added)
	InventoryManager.item_removed.connect(_on_item_removed)
	
	# Initial update
	_update_display()


func _on_inventory_changed() -> void:
	_update_display()


func _on_item_added(item_data: Dictionary, slot: int) -> void:
	_update_slot(slot)


func _on_item_removed(slot: int) -> void:
	_update_slot(slot)


func _update_display() -> void:
	# Update all slots
	for i in range(InventoryManager.MAX_SLOTS):
		_update_slot(i)
	
	# Update synergy display
	_update_synergy_display()


func _update_slot(slot_index: int) -> void:
	if slot_index >= slots_container.get_child_count():
		return
	
	var slot = slots_container.get_child(slot_index)
	if slot.has_method("set_item"):
		var item = InventoryManager.inventory[slot_index]
		slot.set_item(item)


func _update_synergy_display() -> void:
	# Count active synergies
	var synergy_count = 0
	for buff in InventoryManager.active_buffs:
		if buff.get("name", "").contains("Synergy"):
			synergy_count += 1
	
	if synergy_count > 0:
		synergy_label.text = "Active Synergies: %d" % synergy_count
		synergy_label.visible = true
	else:
		synergy_label.visible = false

