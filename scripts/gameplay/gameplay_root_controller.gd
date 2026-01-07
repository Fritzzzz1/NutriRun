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
	GameState.reset_run_state()
	GameState.current_room = 1
	
	InventoryManager.reset_inventory()
	
	_reset_run_stats()
	
	if room and room.has_method("initialize"):
		room.initialize(GameState.current_room)
	
	if camera and room and room.has_method("get_world_bounds"):
		var bounds = room.get_world_bounds()
		if camera.has_method("set_world_bounds"):
			camera.set_world_bounds(bounds)
		if camera.has_method("set_camera_mode"):
			camera.set_camera_mode(1)  # 1 = PLAYER_CENTERED

	var minimap = get_node_or_null("UILayer/UI/TopRight/VBox/Minimap")
	if minimap and minimap.has_method("set_minimap_mode"):
		minimap.set_minimap_mode(1)  # 1 = PLAYER_CENTERED
	
	if room and room.has_signal("exit_triggered"):
		room.exit_triggered.connect(_on_room_exit_triggered)
	
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	
	_setup_spawners()

	_update_room_label()

	EventBus.push_notification("Gameplay started - Room %d" % GameState.current_room)
	EventBus.run_started.emit()


func _process(delta: float) -> void:
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
	run_stats.rooms_cleared += 1


func _on_player_died() -> void:
	"""Handle player death - show death screen."""
	run_active = false
	
	EventBus.push_notification("Run ended - Player died")
	
	if enemy_spawner:
		enemy_spawner.set_process(false)
	if item_spawner:
		item_spawner.set_process(false)
	
	get_tree().paused = false
	
	_show_death_screen()


func _show_death_screen() -> void:
	"""Display the death screen with run statistics."""
	death_screen = DEATH_SCREEN_SCENE.instantiate()
	add_child(death_screen)
	
	if death_screen.continue_pressed.connect(_on_death_screen_continue) != OK:
		push_error("Failed to connect continue_pressed signal")
	
	death_screen.show_death_screen(run_stats)


func _on_death_screen_continue() -> void:
	"""Handle continue from death screen."""
	EventBus.run_ended.emit()
	GameState.reset_run_state()
	InventoryManager.reset_inventory()
	call_deferred("_transition_to_main_menu")


func _transition_to_main_menu() -> void:
	"""Transition to main menu (called deferred)."""
	SceneManager.go_to_main_menu()




func _setup_spawners() -> void:
	"""Setup item and enemy spawners."""
	if item_spawner and item_spawner.has_signal("item_spawned"):
		item_spawner.item_spawned.connect(_on_item_spawned)
	
	if enemy_spawner and enemy_spawner.has_signal("enemy_spawned"):
		enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)


func _on_item_spawned(item_node: Node2D) -> void:
	"""Handle when an item is spawned."""
	if item_node.has_signal("picked_up"):
		item_node.picked_up.connect(_on_pickup_collected)


func _on_enemy_spawned(enemy_node: Node2D) -> void:
	"""Handle when an enemy is spawned."""
	if enemy_node.has_signal("enemy_died"):
		enemy_node.enemy_died.connect(_on_enemy_defeated)


func _on_enemy_defeated() -> void:
	"""Track enemy kills."""
	run_stats.enemies_defeated += 1


func _on_pickup_collected(item_data: Dictionary) -> void:
	"""Handle when player collects a nutrition pickup."""
	if InventoryManager.add_item(item_data):
		run_stats.items_collected += 1

		if item_display:
			item_display.show_item(item_data)

		# Refill nitro when collecting items
		if player and player.has_method("refill_nitro"):
			var refill_amount = player.nitro_pickup_refill if "nitro_pickup_refill" in player else 25.0
			player.refill_nitro(refill_amount)

		EventBus.push_notification("Collected: %s" % item_data.get("id", "Unknown"))
	else:
		EventBus.push_notification("Inventory full!")


func _on_return_to_hub_pressed() -> void:
	run_active = false
	EventBus.run_ended.emit()
	SceneManager.go_to_hub()


func _on_debug_invincible_toggled(enabled: bool) -> void:
	if player and player.has_method("set_debug_invincible"):
		player.set_debug_invincible(enabled)


func _on_debug_camera_zoom_changed(zoom_level: float) -> void:
	if camera and camera.has_method("set_zoom_level"):
		camera.set_zoom_level(zoom_level)
