# Progress Log (NutriRun)

## 2025-12-31

### Accomplished

- **Bootable Godot project**:
  - Set `run/main_scene` to `res://scenes/ui/main_menu.tscn`
  - Added autoload singletons: `EventBus`, `GameState`, `SaveSystem`, `SceneManager`
- **Core scaffolding**:
  - Added folder structure for `scenes/`, `scripts/`, `assets/` to match the architecture prompt
  - Added placeholder JSON data files under `assets/data/` (characters, items, synergies, etc.)
- **UI + navigation skeleton (end-to-end flow)**:
  - `MainMenu → CharacterSelect → Hub → Gameplay → Hub`
  - Implemented with placeholder scenes + controllers:
    - `scenes/ui/main_menu.tscn` + `scripts/ui/main_menu_controller.gd`
    - `scenes/ui/character_select.tscn` + `scripts/ui/character_select_controller.gd`
    - `scenes/hub/hub_screen.tscn` + `scripts/hub/hub_controller.gd`
    - `scenes/gameplay/gameplay_root.tscn` + `scripts/gameplay/gameplay_root_controller.gd`
  - Centralized transitions in `scripts/autoloads/scene_manager.gd`
- **Basic persistence stub**:
  - `SaveSystem` loads/saves `user://nutrirun_save.json`
  - Hub has a **Save** button that emits `EventBus.save_requested`
- **Dev docs cleanup**:
  - Updated `GODOT_BEST_PRACTICES.md` to correctly reference **NutriRun** and the correct local path.
- **Version control**:
  - Initialized git repo inside `nutrirun/`
  - Added `.gitignore` for `.godot/`
  - Committed:
    - `Scaffold NutriRun project skeleton`
    - `Add basic scene flow skeleton`

### Next steps (recommended order)

1. **Gameplay foundation** ✅
   - ✅ Created `Room.tscn` + `RoomManager.gd` (simple arena with exit trigger)
   - ✅ Added `Player.tscn` + `PlayerController.gd` (WASD movement + health system)
   - ✅ Integrated Room and Player into `gameplay_root` scene
   - ✅ Player can move around arena and trigger exit to return to hub
2. **Nutrition system (vertical slice)** ✅
   - ✅ Created `NutritionPickup.tscn` + `NutritionPickup.gd` (pickup entity with collision detection)
   - ✅ Created `InventoryManager` autoload (8-slot inventory system)
   - ✅ Created inventory UI (`inventory_ui.tscn` + `inventory_slot.tscn`) displayed in gameplay scene
   - ✅ Implemented buff system that applies stat multipliers (damage, speed, max_health) to player
   - ✅ Implemented synergy evaluation system from `assets/data/synergies.json` (e.g., 3+ fruits → +15% max health)
   - ✅ Added 4 nutrition items to `nutrition_items.json` (apple, banana, orange, carrot)
   - ✅ Player stats update dynamically when items are collected/removed
   - ✅ Test pickups spawn in gameplay rooms for testing
3. **Horde system (MVP)**
   - `Horde.tscn` + `HordeManager.gd` that spawns 3–5 follower units
   - Simple target acquisition + attack loop
4. **Run loop glue**
   - Award harvest points at end-of-run
   - Save meta progression in `SaveSystem` and show in Hub


