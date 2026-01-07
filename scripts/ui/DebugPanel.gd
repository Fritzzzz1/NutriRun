extends PanelContainer

signal invincibility_toggled(enabled: bool)
signal camera_zoom_changed(zoom_level: float)

@export var show_in_debug: bool = true

const ZOOM_LEVELS: Array[float] = [0.5, 1.0, 1.5, 2.0, 4.0]

@onready var invincible_checkbox: CheckBox = $VBox/InvincibleCheckBox
@onready var game_speed_slider: HSlider = $VBox/GameSpeedContainer/GameSpeedSlider
@onready var game_speed_label: Label = $VBox/GameSpeedContainer/GameSpeedValueLabel
@onready var camera_zoom_option: OptionButton = $VBox/CameraZoomContainer/CameraZoomOption


func _ready() -> void:
	visible = show_in_debug
	_setup_controls()


func _setup_controls() -> void:
	if game_speed_slider:
		game_speed_slider.value = 1.0
		Engine.time_scale = 1.0
		_update_game_speed_label(1.0)
		game_speed_slider.value_changed.connect(_on_game_speed_changed)

	if invincible_checkbox:
		invincible_checkbox.toggled.connect(_on_invincible_toggled)

	if camera_zoom_option:
		camera_zoom_option.select(3)  # Default to 2x (index 3)
		camera_zoom_option.item_selected.connect(_on_camera_zoom_selected)


func _on_invincible_toggled(button_pressed: bool) -> void:
	invincibility_toggled.emit(button_pressed)


func _on_game_speed_changed(value: float) -> void:
	Engine.time_scale = value
	_update_game_speed_label(value)


func _update_game_speed_label(value: float) -> void:
	if game_speed_label:
		game_speed_label.text = "%.2fx" % value


func _on_camera_zoom_selected(index: int) -> void:
	if index >= 0 and index < ZOOM_LEVELS.size():
		camera_zoom_changed.emit(ZOOM_LEVELS[index])
