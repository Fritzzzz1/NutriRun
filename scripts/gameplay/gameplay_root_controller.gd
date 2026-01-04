## Gameplay root controller: manages room and player instances.
extends Node

const DEATH_SCREEN_SCENE = preload("res://scenes/ui/death_screen.tscn")

@onready var gameplay_layer: Node2D = $GameplayLayer
@onready var room: Node2D = $GameplayLayer/Room
@onready var player: CharacterBody2D = $GameplayLayer/Player
@onready var camera: Camera2D = $GameplayLayer/Camera2D
@onready var room_label: Label = $UILayer/UI/TopLeft/VBox/Label
@onready var item_spawner: Node2D = $GameplayLayer/ItemSpawner
@onready var enemy_spawner: Node2D = $GameplayLayer/EnemySpawner
@onready var item_display: Control = $UILayer/ItemPickupDisplay

# Run statistics
var run_stats: Dictionary = {
	"rooms_cleared": 0,
	"enemies_defeated": 0,
	"items_collected": 0,
	"time_survived": 0.0,
	"damage_taken": 0,
	"damage_dealt": 0
}

var run_active: bool = true
var death_screen: CanvasLayer = null


func _ready() -> void:
	# Initialize run state
	GameState.reset_run_state()
	GameState.current_room = 1
	
	# Reset inventory for new run
	InventoryManager.reset_inventory()
	
	# Reset run stats
	_reset_run_stats()
	
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


func _process(delta: float) -> void:
	# Track time survived
	if run_active:
		run_stats.time_survived += delta


func _reset_run_stats() -> void:
	"""Reset all run statistics."""
	run_stats = {
		"rooms_cleared": 0,
		"enemies_defeated": 0,
		"items_collected": 0,
		"time_survived": 0.0,
		"damage_taken": 0,
		"damage_dealt": 0
	}
	run_active = true


func _update_room_label() -> void:
	if room_label:
		room_label.text = "Room: %d" % GameState.current_room


func _on_room_exit_triggered() -> void:
	# Room manager handles the transition, but we can do cleanup here if needed
	run_stats.rooms_cleared += 1


func _on_player_died() -> void:
	"""Handle player death - show death screen."""
	run_active = false
	
	EventBus.push_notification("Run ended - Player died")
	
	# Pause enemy spawning
	if enemy_spawner:
		enemy_spawner.set_process(false)
	if item_spawner:
		item_spawner.set_process(false)
	
	# Ensure game is not paused (scene changes need unpaused tree)
	get_tree().paused = false
	
	# Show death screen
	_show_death_screen()


func _show_death_screen() -> void:
	"""Display the death screen with run statistics."""
	death_screen = DEATH_SCREEN_SCENE.instantiate()
	add_child(death_screen)
	
	# Connect continue signal
	if death_screen.continue_pressed.connect(_on_death_screen_continue) != OK:
		print("ERROR: Failed to connect continue_pressed signal!")
	else:
		print("GameplayRoot: Successfully connected continue_pressed signal")
	
	# Show with stats
	death_screen.show_death_screen(run_stats)


func _on_death_screen_continue() -> void:
	"""Handle continue from death screen."""
	print("GameplayRoot: Death screen continue received!")
	EventBus.run_ended.emit()
	# Reset run state before going to main menu
	GameState.reset_run_state()
	InventoryManager.reset_inventory()
	print("GameplayRoot: Transitioning to main menu...")
	# Use call_deferred to ensure scene change happens after current frame
	call_deferred("_transition_to_main_menu")


func _transition_to_main_menu() -> void:
	"""Transition to main menu (called deferred)."""
	SceneManager.go_to_main_menu()


func _on_player_health_changed(current: int, max_health: int) -> void:
	# Track damage taken (we could calculate this from health changes)
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
	# Connect to enemy death signal to track kills
	if enemy_node.has_signal("enemy_died"):
		enemy_node.enemy_died.connect(_on_enemy_defeated)


func _on_enemy_defeated() -> void:
	"""Track enemy kills."""
	run_stats.enemies_defeated += 1


func _on_pickup_collected(item_data: Dictionary) -> void:
	"""Handle when player collects a nutrition pickup."""
	if InventoryManager.add_item(item_data):
		# Track item collection
		run_stats.items_collected += 1
		
		# Show nice pickup display
		if item_display:
			item_display.show_item(item_data)
		
		EventBus.push_notification("Collected: %s" % item_data.get("id", "Unknown"))
	else:
		EventBus.push_notification("Inventory full!")


func _on_return_to_hub_pressed() -> void:
	run_active = false
	EventBus.run_ended.emit()
	SceneManager.go_to_hub()
