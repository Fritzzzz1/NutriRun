# Godot 4.5 Development Guide - NutriRun

## Project Information

- **Godot Version**: 4.5 (Forward Plus rendering)
- **Project Name**: NutriRun
- **Primary Language**: GDScript

## How to Run the Game Locally

You can run your game in several ways:

1. **Using Godot Editor**: Open the project in Godot Editor and press **F5** (or click the Play button)
2. **Command line**: `godot --path /Users/fritzzzz/DevGigs/games/nutrirun`
3. **Run specific scene**: `godot main.tscn` (when you have your main scene)
4. **Check for errors**: `godot --check-only project.godot`

## Godot Architecture Fundamentals

### Scene-Based Architecture

Godot uses a **scene-based architecture**. Think of scenes as reusable building blocks:

```
Recommended Project Structure:
nutrirun/
├── scenes/
│   ├── player/
│   │   └── player.tscn
│   ├── enemies/
│   │   ├── base_enemy.tscn
│   │   └── specific_enemy.tscn
│   ├── levels/
│   │   └── level_01.tscn
│   └── ui/
│       └── hud.tscn
├── scripts/
│   ├── player.gd
│   └── enemy.gd
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── project.godot
```

**Key Principles**:

- Each scene represents a **single entity** (Player, Enemy, UI element)
- Use **meaningful names** for nodes (snake_case: `health_bar`, not `HealthBar`)
- Keep scenes **focused** - one purpose per scene
- Build **scene hierarchies** logically

### Node Tree Structure

A typical node hierarchy looks like this:

```gdscript
# Player.tscn structure
CharacterBody2D (Player)  # Root node
├── Sprite2D              # Visual representation
├── CollisionShape2D      # Physics collision
├── AnimationPlayer       # Animations
└── Camera2D              # Player camera (optional)
```

**Best practices**:

- Avoid deeply nested trees (keep it **3-5 levels max**)
- Group related nodes under containers (Node2D, Control)
- Use **Groups** for easy access: `add_to_group("enemies")`

## GDScript Coding Standards (2025)

### Naming Conventions

- **Files/Scenes**: `snake_case` (player.gd, main_menu.tscn)
- **Classes**: `PascalCase` (class_name PlayerController)
- **Variables/Functions**: `snake_case` (max_health, get_damage())
- **Constants**: `SCREAMING_SNAKE_CASE` (MAX_SPEED)
- **Private vars**: `_snake_case` (\_current_health)
- **Signals**: `snake_case` (health_changed, enemy_died)

### Documentation

- Use `##` for docstrings (generates reference docs)
- Use `#` for regular comments

### Example Script Structure

```gdscript
## Player controller for NutriRun.
## Handles movement, combat, and health management.
extends CharacterBody2D

# Constants (SCREAMING_SNAKE_CASE)
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Exported variables (visible in Inspector)
@export var max_health: int = 100
@export var attack_damage: int = 10

# Private variables (use _ prefix)
var _current_health: int
var _is_attacking: bool = false

# Onready variables (initialized when node enters tree)
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer


func _ready() -> void:
	"""Called when node enters the scene tree."""
	_current_health = max_health
	add_to_group("player")


func _physics_process(delta: float) -> void:
	"""Handle physics updates (movement, gravity)."""
	# Handle gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func take_damage(amount: int) -> void:
	"""Reduce health by the specified amount."""
	_current_health -= amount
	if _current_health <= 0:
		_die()


func _die() -> void:
	"""Handle player death."""
	queue_free()  # Remove from scene
```

## Communication Patterns

### Signals (Preferred)

Instead of direct node references, use **signals** for loose coupling:

```gdscript
# In enemy.gd
signal enemy_died(score_value)

func _die() -> void:
	enemy_died.emit(100)  # Emit signal with score
	queue_free()

# In game_manager.gd
func _ready() -> void:
	# Connect to enemy signals
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(score: int) -> void:
	current_score += score
```

## Scene Instancing

Create reusable enemies/bullets by instancing scenes:

```gdscript
# Preload scene at compile time (faster)
const BulletScene = preload("res://scenes/bullet.tscn")

func shoot() -> void:
	var bullet = BulletScene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position
```

## Performance Best Practices

- **Minimize object creation** in loops
- Use `@onready` for node references (cached once)
- Prefer `_physics_process` for movement, `_process` for non-physics
- Use object pooling for frequently spawned objects (bullets, particles)
- Avoid `get_node()` in every frame - cache references

## Project Organization

- **Separate concerns**: Keep UI, gameplay logic, and data management distinct
- **Use AutoLoad** for global managers (GameManager, AudioManager)
- **Version control**: `.godot/` folder is in gitignore
- **Asset organization**: Group by type (sprites/, audio/, fonts/)

## Development Workflow

1. **Design your scene hierarchy first** (sketch it out)
2. **Create base scenes** (Player, Enemy templates)
3. **Extend with inheritance** (create specific enemy types from base)
4. **Use signals** for communication between nodes
5. **Test incrementally** - run the game often
6. **Keep scripts focused** - single responsibility principle

## Common Patterns

### Getting Nodes

```gdscript
# Preferred: Use @onready
@onready var sprite = $Sprite2D
@onready var health_bar = get_node("UI/HealthBar")

# Avoid in _process or _physics_process
func _process(delta):
	var sprite = $Sprite2D  # Bad - lookups every frame
```

### Creating Nodes Dynamically

```gdscript
# Set properties before adding to tree (preferred)
var sprite = Sprite2D.new()
sprite.texture = load("res://icon.svg")
sprite.position = Vector2(100, 100)
add_child(sprite)
```

### Scene Tree Access

```gdscript
func _ready():
	var scene_tree = get_tree()
	var root = scene_tree.root
	var current_scene = scene_tree.current_scene

	# Change scenes
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

## References

- [GDScript Style Guide - Godot Engine](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Best Practices - Godot Engine](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [GDScript Best Practices 2025 - Toxigon](https://toxigon.com/gdscript-best-practices-2025)
- [GDQuest's Guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines)
- [Project Organization - Godot Engine](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
