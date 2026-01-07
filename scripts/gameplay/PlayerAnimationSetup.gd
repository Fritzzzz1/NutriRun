extends Node
class_name PlayerAnimationSetup

# Frame configuration - adjust these values to match your spritesheet layout
# Format: [x, y] position in pixels for each frame
const FRAME_SIZE := Vector2(64, 64)

# Walking animation frames - each array contains [x, y] pixel positions for each frame
# Adjust these coordinates to match your spritesheet

static var WALK_DOWN_FRAMES := [
	Vector2(192, 640), Vector2(256, 640), Vector2(320, 640),
	Vector2(384, 640), Vector2(448, 640), Vector2(512, 640), 
]

static var WALK_LEFT_FRAMES := [
	Vector2(0, 576), Vector2(64, 576), Vector2(128, 576),
	Vector2(192, 576), Vector2(256, 576), Vector2(320, 576)
]

static var WALK_RIGHT_FRAMES := [
	Vector2(0, 704), Vector2(64, 704), Vector2(128, 704),
	Vector2(192, 704), Vector2(256, 704), Vector2(320, 704)
]

static var WALK_UP_FRAMES := [
	Vector2(192, 512), Vector2(256, 512), Vector2(320, 512),
	Vector2(384, 512), Vector2(448, 512), Vector2(512, 512), 
]

static func create_sprite_frames(spritesheet: Texture2D) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()

	# Remove default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	# Create walk animations
	_add_animation(sprite_frames, "walk_down", spritesheet, WALK_DOWN_FRAMES, 10.0)
	_add_animation(sprite_frames, "walk_left", spritesheet, WALK_LEFT_FRAMES, 10.0)
	_add_animation(sprite_frames, "walk_right", spritesheet, WALK_RIGHT_FRAMES, 10.0)
	_add_animation(sprite_frames, "walk_up", spritesheet, WALK_UP_FRAMES, 10.0)

	# Create idle animations (first frame of each walk direction)
	_add_animation(sprite_frames, "idle_down", spritesheet, [WALK_DOWN_FRAMES[0]], 1.0, false)
	_add_animation(sprite_frames, "idle_left", spritesheet, [WALK_LEFT_FRAMES[0]], 1.0, false)
	_add_animation(sprite_frames, "idle_right", spritesheet, [WALK_RIGHT_FRAMES[0]], 1.0, false)
	_add_animation(sprite_frames, "idle_up", spritesheet, [WALK_UP_FRAMES[0]], 1.0, false)

	return sprite_frames


static func _add_animation(sprite_frames: SpriteFrames, anim_name: String,
		spritesheet: Texture2D, frame_positions: Array, fps: float = 10.0, loop: bool = true) -> void:

	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, fps)
	sprite_frames.set_animation_loop(anim_name, loop)

	for pos in frame_positions:
		var atlas := AtlasTexture.new()
		atlas.atlas = spritesheet
		atlas.region = Rect2(pos, FRAME_SIZE)
		sprite_frames.add_frame(anim_name, atlas)
