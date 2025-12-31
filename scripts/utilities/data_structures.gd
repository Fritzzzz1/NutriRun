## Data structures used across systems (Resources).

# Note: Keeping these small and editor-friendly makes JSON->Resource mapping easy later.

extends RefCounted


class Buff:
	extends Resource
	@export var name: String = ""
	@export var duration: float = 0.0 # seconds; 0 = permanent this run
	@export var stat_multipliers: Dictionary = {} # {"damage": 1.2, "speed": 1.1}
	@export var special_effect: String = "" # "chill_aura", "split_fire", etc.


class NutritionItem:
	extends Resource
	@export var item_name: String = ""
	@export var item_type: String = "" # "fruit", "vegetable", "junk", "gadget"
	@export var buff_applied: Buff
	@export var icon: Texture2D
	@export var rarity: String = "common" # "common", "uncommon", "rare"


class Synergy:
	extends Resource
	@export var name: String = ""
	@export var description: String = ""
	@export var condition: String = "" # e.g. "fruit_count >= 3"
	@export var buff_reward: Buff
	@export var discovery_text: String = ""


