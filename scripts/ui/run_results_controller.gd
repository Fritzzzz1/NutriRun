extends Control

@onready var rooms_label: Label = $VBox/RoomsLabel
@onready var enemies_label: Label = $VBox/EnemiesLabel
@onready var items_label: Label = $VBox/ItemsLabel
@onready var points_label: Label = $VBox/PointsLabel
@onready var return_button: Button = $VBox/ReturnButton
@onready var play_again_button: Button = $VBox/PlayAgainButton

var rooms_cleared: int = 0
var enemies_defeated: int = 0
var items_collected: int = 0
var points_earned: int = 0


func _ready() -> void:
	rooms_cleared = GameState.rooms_cleared_this_run
	enemies_defeated = GameState.enemies_defeated_this_run
	items_collected = GameState.items_collected_this_run
	
	points_earned = (rooms_cleared * 10) + (enemies_defeated * 5) + (items_collected * 2)
	if GameState.current_room > 10:
		points_earned += 50
	
	_update_display()
	
	if return_button:
		return_button.pressed.connect(_on_return_pressed)
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)


func _update_display() -> void:
	"""Update all display labels."""
	if rooms_label:
		rooms_label.text = "Rooms Cleared: %d" % rooms_cleared
	if enemies_label:
		enemies_label.text = "Enemies Defeated: %d" % enemies_defeated
	if items_label:
		items_label.text = "Items Collected: %d" % items_collected
	if points_label:
		points_label.text = "Harvest Points Earned: %d" % points_earned


func _on_return_pressed() -> void:
	"""Return to hub."""
	SceneManager.go_to_hub()


func _on_play_again_pressed() -> void:
	"""Start a new run."""
	GameState.reset_run_state()
	EventBus.run_started.emit()
	SceneManager.go_to_gameplay()

