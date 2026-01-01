## Gameplay root controller: manages room and player instances.
extends Node

@onready var gameplay_layer: Node2D = $GameplayLayer
@onready var room: Node2D = $GameplayLayer/Room
@onready var player: CharacterBody2D = $GameplayLayer/Player
@onready var camera: Camera2D = $GameplayLayer/Camera2D
@onready var room_label: Label = $UILayer/UI/TopLeft/VBox/Label
@onready var item_spawner: Node2D = $GameplayLayer/ItemSpawner
@onready var enemy_spawner: Node2D = $GameplayLayer/EnemySpawner
@onready var item_display: Control = $UILayer/ItemPickupDisplay


func _ready() -> void:
	# Initialize run state
	GameState.reset_run_state()
	GameState.current_room = 1
	
	# Reset inventory for new run
	InventoryManager.reset_inventory()
	
	# Initialize room
	if room and room.has_method("initialize"):
		room.initialize(GameState.current_room)
	
	# Setup camera with world bounds
	if camera and room and room.has_method("get_world_bounds"):
		var bounds = room.get_world_bounds()
		if camera.has_method("set_world_bounds"):
			camera.set_world_bounds(bounds)
	
	# Connect room signals
	if room and room.has_signal("exit_triggered"):
		room.exit_triggered.connect(_on_room_exit_triggered)
	
	# Connect player signals
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	
	# Setup spawners
	_setup_spawners()
	
	# Update UI
	_update_room_label()
	
	EventBus.push_notification("Gameplay started - Room %d" % GameState.current_room)
	EventBus.run_started.emit()


func _update_room_label() -> void:
	if room_label:
		room_label.text = "Room: %d" % GameState.current_room


func _on_room_exit_triggered() -> void:
	# Room manager handles the transition, but we can do cleanup here if needed
	pass


func _on_player_died() -> void:
	EventBus.push_notification("Run ended - Player died")
	# Return to hub after a delay
	await get_tree().create_timer(2.0).timeout
	EventBus.run_ended.emit()
	SceneManager.go_to_hub()


func _on_player_health_changed(current: int, max_health: int) -> void:
	# Future: Update health UI
	pass


func _setup_spawners() -> void:
	"""Setup item and enemy spawners."""
	# Setup item spawner
	if item_spawner:
		if item_spawner.has_method("_ready"):
			# Connect to item spawner signals
			if item_spawner.has_signal("item_spawned"):
				item_spawner.item_spawned.connect(_on_item_spawned)
	
	# Setup enemy spawner
	if enemy_spawner:
		if enemy_spawner.has_method("_ready"):
			# Connect to enemy spawner signals
			if enemy_spawner.has_signal("enemy_spawned"):
				enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)


func _on_item_spawned(item_node: Node2D) -> void:
	"""Handle when an item is spawned."""
	if item_node.has_signal("picked_up"):
		item_node.picked_up.connect(_on_pickup_collected)


func _on_enemy_spawned(enemy_node: Node2D) -> void:
	"""Handle when an enemy is spawned."""
	pass


func _on_pickup_collected(item_data: Dictionary) -> void:
	"""Handle when player collects a nutrition pickup."""
	if InventoryManager.add_item(item_data):
		# Show nice pickup display
		if item_display:
			item_display.show_item(item_data)
		
		EventBus.push_notification("Collected: %s" % item_data.get("id", "Unknown"))
	else:
		EventBus.push_notification("Inventory full!")


func _on_return_to_hub_pressed() -> void:
	EventBus.run_ended.emit()
	SceneManager.go_to_hub()


