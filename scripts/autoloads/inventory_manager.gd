## Inventory manager: manages player's nutrition item inventory (8 slots).
extends Node

signal inventory_changed
signal item_added(item_data: Dictionary, slot: int)
signal item_removed(slot: int)

const MAX_SLOTS: int = 8

var inventory: Array[Dictionary] = []  # Array of item dictionaries from JSON
var active_buffs: Array[Dictionary] = []  # Array of active buff dictionaries


func _ready() -> void:
	# Initialize empty inventory
	inventory.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		inventory[i] = {}


func reset_inventory() -> void:
	"""Reset inventory at start of new run."""
	inventory.clear()
	inventory.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		inventory[i] = {}
	active_buffs.clear()
	inventory_changed.emit()


func add_item(item_data: Dictionary) -> bool:
	"""Add item to first available slot. Returns true if added, false if inventory full."""
	for i in range(MAX_SLOTS):
		if inventory[i].is_empty():
			inventory[i] = item_data.duplicate()
			item_added.emit(item_data, i)
			_apply_item_buff(item_data)
			_evaluate_synergies()
			inventory_changed.emit()
			return true
	return false


func remove_item(slot: int) -> void:
	"""Remove item from specified slot."""
	if slot >= 0 and slot < MAX_SLOTS and not inventory[slot].is_empty():
		var item_data = inventory[slot]
		_remove_item_buff(item_data)
		inventory[slot] = {}
		item_removed.emit(slot)
		_evaluate_synergies()
		inventory_changed.emit()


func _apply_item_buff(item_data: Dictionary) -> void:
	"""Apply buff from nutrition item."""
	if not item_data.has("buff"):
		return
	
	var buff = item_data.buff
	if buff.has("stat_multipliers") or buff.has("special_effect"):
		active_buffs.append(buff.duplicate())
		# Notification is handled by gameplay_root_controller


func _remove_item_buff(item_data: Dictionary) -> void:
	"""Remove buff when item is removed."""
	if not item_data.has("buff"):
		return
	
	var buff_name = item_data.buff.get("name", "")
	# Remove matching buff from active_buffs by name
	for i in range(active_buffs.size() - 1, -1, -1):
		if active_buffs[i].get("name", "") == buff_name:
			active_buffs.remove_at(i)
			break


func get_item_count_by_type(type: String) -> int:
	"""Count items of a specific type (e.g., 'fruit')."""
	var count = 0
	for item in inventory:
		if not item.is_empty() and item.get("type") == type:
			count += 1
	return count


func _evaluate_synergies() -> void:
	"""Evaluate all synergies and apply/remove synergy buffs."""
	# Load synergies from JSON
	var synergies_path = "res://assets/data/synergies.json"
	if not ResourceLoader.exists(synergies_path):
		return
	
	var file = FileAccess.open(synergies_path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	var parse_result = json.parse_string(file.get_as_text())
	file.close()
	
	if not parse_result or not parse_result.has("synergies"):
		return
	
	# For each synergy, check condition and apply/remove buff
	for synergy_data in parse_result.synergies:
		var condition = synergy_data.get("condition", "")
		var should_activate = _check_synergy_condition(condition)
		
		# Check if synergy buff is already active
		var synergy_name = synergy_data.get("name", "")
		var already_active = false
		for buff in active_buffs:
			if buff.get("name") == synergy_name:
				already_active = true
				break
		
		if should_activate and not already_active:
			# Apply synergy buff
			if synergy_data.has("buff"):
				active_buffs.append(synergy_data.buff.duplicate())
				EventBus.push_notification(synergy_data.get("discovery_text", synergy_name + " activated!"))
		elif not should_activate and already_active:
			# Remove synergy buff
			for i in range(active_buffs.size() - 1, -1, -1):
				if active_buffs[i].get("name") == synergy_name:
					active_buffs.remove_at(i)
					break


func _check_synergy_condition(condition: String) -> bool:
	"""Evaluate synergy condition string (e.g., 'fruit_count >= 3')."""
	# Simple condition parser for now
	# Supports: type_count >= number, type_count == number, type_count <= number
	
	if condition.is_empty():
		return false
	
	# Extract type and count from condition
	var parts = condition.split(" ")
	if parts.size() < 3:
		return false
	
	var type_var = parts[0]  # e.g., "fruit_count"
	var operator = parts[1]  # e.g., ">="
	var threshold = int(parts[2])
	
	# Extract type from variable name (remove "_count")
	var item_type = type_var.replace("_count", "")
	var actual_count = get_item_count_by_type(item_type)
	
	match operator:
		">=":
			return actual_count >= threshold
		"==":
			return actual_count == threshold
		"<=":
			return actual_count <= threshold
		">":
			return actual_count > threshold
		"<":
			return actual_count < threshold
		_:
			return false


func get_stat_multiplier(stat_name: String) -> float:
	"""Get combined multiplier for a stat from all active buffs."""
	var multiplier = 1.0
	for buff in active_buffs:
		if buff.has("stat_multipliers") and buff.stat_multipliers.has(stat_name):
			multiplier *= buff.stat_multipliers[stat_name]
	return multiplier

