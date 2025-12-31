# NutriRun: Complete Architecture & Technical Specification Prompt

## Executive Summary

**Project:** NutriRun - A 2D Roguelite Nutrition-Based Game
**Engine:** Godot 4.x
**Target Scope:** V1 MVP for indie release
**Development Stage:** Pre-production → Technical Architecture Phase

---

## 1. CORE GAME VISION & DESIGN PHILOSOPHY

### 1.1 High-Concept
NutriRun is a **short-run roguelite (10-15 minutes per playthrough)** where nutrition is the primary power system. Players control diverse characters (kids, monsters, snowmen, robots) who grow stronger by eating healthy foods and weaker by consuming junk food. Combat is squad-based using a "vegetable horde"—vegetables that scale with the player's nutrition buffs. Between runs, players return to a persistent cozy hub space (café, garden, or home base) where they decorate and unlock progression.

### 1.2 Design Pillars (Non-Negotiable)
1. **Short, Replayable Runs:** 10-15 min per session; designed for "one more run" loop
2. **Nutrition as Core Mechanic:** Fruits/vegetables = power-ups; junk food = risky debuffs
3. **Distinctive Visual Identity:** Neon + pastels, anime-inspired silhouettes, reads in 10 seconds
4. **Cozy Hub Progression:** Persistent, decoratable space with visible unlock changes
5. **Social/Clip-Friendly:** Mechanics designed to generate speedruns, clutch moments, and ASMR loops
6. **Vegetable Horde Combat:** Squad-based battles where nutrition empowers AI-controlled vegetables

### 1.3 Target Audience
- **Primary:** Ages 8-18 (family-friendly, educational health angle)
- **Secondary:** Cozy game enthusiasts (Gen Z seeking stress-relief gaming)
- **Tertiary:** Roguelite/speedrun community (TikTok, YouTube Shorts, Twitch audiences)

---

## 2. GAMEPLAY MECHANICS (DETAILED)

### 2.1 The Core Loop: Each Run

**Phase 1: Exploration & Gathering**
- Player navigates procedurally-generated or hand-crafted tilemap rooms (2D top-down)
- Encounters scattered **Nutrition Items** (collectibles) and **Enemy Groups**
- Decision-making: Which items to pick up? Which enemies to fight? Risk vs. reward.

**Phase 2: Nutrition System (Your Deck-Building Equivalent)**
- **Inventory:** Hold up to 8 nutrition items at once
- **Good Nutrition (Fruits/Vegetables):** Provide immediate buffs + synergy bonuses
  - Apple → +10% damage, restore 1 health
  - Spinach → +15% speed for 30 seconds
  - Carrot → +20% horde size for 1 room
  - Broccoli → Team-wide +5% armor
  - Potato → Heal all vegetables in squad by 20%
  - Blueberry → Critical hit chance +10%
- **Bad Nutrition (Junk Food):** Risky debuffs + chaos synergies
  - Candy → -10% health but +30% speed (high risk)
  - Soda → -15% damage but horde gains split-fire ability
  - Burger → -25% defense but +50% horde attack power
  - Cookies → Player loses 1 health but all vegetables get +1 attack
- **Special Items (Kitchen Gadgets):**
  - Blender → Combine any 2 fruits for custom buff
  - Steamer → All vegetables gain "boiling hot" damage aura
  - Grill → Fire damage passive on horde attacks
  - Compost Bin → Turn eaten items into permanent stat boosts

**Phase 3: Battle (Horde Mechanics)**
- **Squad Composition:** Start with 3-5 vegetable units (tomatoes, carrots, peppers, lettuce)
- **Vegetable Units:** Each has health, attack, speed, special ability
  - Tomato (basic): Medium stats, good for damage
  - Carrot (ranged): Low health, high damage from range
  - Pepper (tank): High health, lower damage, taunts enemies
  - Lettuce (support): Heals nearby vegetables
  - Potato (heavy): Slow, high damage, knocks back enemies
- **Combat Flow:**
  - Player and horde fight waves of enemies
  - Horde AI attacks autonomously (configurable aggression)
  - Nutrition buffs modify vegetable stats in real-time
  - Player collects drops from defeated enemies
  - After victory: Nutrition items appear as room rewards

**Phase 4: Room Progression**
- Defeat enemies → Advance to next room
- Gather nutrition along the way
- Rooms scale in difficulty (more enemies, higher stats)
- Every 5 rooms: **Miniboss Battle**
- Run ends at: Death OR Boss Defeat (Victory Condition)

### 2.2 Enemy Design & Nutrition Theming

**Enemy Types (All Nutrition-Themed):**
1. **Sugar Slug:** Fast, low health, spawns candy drops
2. **Grease Goblin:** Medium, ranged oil attacks, drops junk food
3. **Soda Specter:** Tank-like, heals other enemies, drops soda cans
4. **Junk Hoarder:** Tanky enemy that grants debuffs to player on contact
5. **Candy Golem:** Large, slow, splits into smaller enemies on defeat
6. **Boss: The Sugar King:** Multi-phase boss with area attacks and minion summons

**Enemy Mechanics:**
- Enemies don't drop nutrition items; nutrition comes from ground spawns
- Defeating enemies grants experience/unlock points toward hub progression
- Some rooms have "nutrition caches" that appear without combat

### 2.3 Run Progression & Difficulty Scaling

**Structure:**
- **Act 1:** Rooms 1-5 (tutorial difficulty, establish mechanics)
- **Act 2:** Rooms 6-12 (medium difficulty, synergy depth)
- **Act 3:** Rooms 13-15 (hard difficulty, final gauntlet)
- **Miniboss:** Every 5 rooms
- **Final Boss:** The Sugar King (if player reaches end)

**Difficulty Scaling:**
- Enemy stats increase by 5-8% per room
- Horde scaling: Nutrition synergies must keep pace to stay viable
- RNG elements: Room layouts, enemy spawns, nutrition drop locations vary

### 2.4 Synergy System (Deck-Building Equivalent)

**Synergy Depth:** Stacking nutrition effects for multiplicative benefits
- **Fruit Synergy:** 3+ fruits in inventory → Team gains +15% health max
- **Vegetable Synergy:** 4+ vegetables in inventory → Horde attacks 20% faster
- **Rainbow Synergy:** 1 of each color (apple=red, spinach=green, carrot=orange, etc.) → All stats +10%
- **Chaotic Synergy:** 3+ junk food items → Horde does +50% damage but takes +25% damage
- **Blender Combo:** Use blender on apple + spinach → Create "Super Smoothie" (+25% all stats)

**Synergy Tracking:** UI shows current active synergies & points to next milestone

---

## 3. HUB SYSTEM (Between-Run Progression)

### 3.1 Hub Spaces (Pick One)

**Option A: Cozy Café**
- Counter area (NPCs serve nutrition advice)
- Dining tables (decoratable)
- Kitchen visible in background
- Plant window sill

**Option B: Garden Base**
- Central garden plot (plant seeds that grow into decorations)
- Tool shed (upgrade station)
- Sitting area with benches
- Fence perimeter to expand

**Option C: Home Dorm Room**
- Bed, desk, shelves (all decoratable)
- Small kitchen nook
- Window showing outside world
- Bulletin board for unlocked recipes

### 3.2 Hub Mechanics

**Decoration System:**
- Unlock furniture/decor by completing runs
- Place items freely in designated spaces
- Cosmetic only (no gameplay impact) but provides visual reward loop
- Save configurations across sessions

**Upgrade Tree:**
- **Horde Size:** Unlock +1 vegetable per tier (5→7 vegetables max)
- **Nutrition Capacity:** Increase inventory from 8→12 slots
- **Synergy Unlock:** New synergies unlock with progression
- **Character Skins:** Cosmetic character variants (robot kid, space snowman, etc.)
- **Kitchen Gadgets:** Unlock new special items for runs
- **Hub Expansions:** Unlock new rooms in hub or aesthetic changes

**Currency:** "Harvest Points" earned per run based on:
- Rooms cleared × 10 points
- Enemies defeated × 5 points
- Nutrition items collected × 2 points
- Bonus: +50 points for reaching final boss

### 3.3 Recipe System

**Unlockable Recipes:**
- Combine nutrition items (not real-time, between-run mechanic)
- Example: Apple + Honey → "Nutritious Apple Pie" (+30% health, +10% damage)
- Example: Spinach + Blueberry → "Power Blend" (+20% speed, +15% horde damage)
- Recipes discovered by using ingredient combos in runs
- Unlock new recipes with hub progression
- Recipes persist and can be used in future runs

---

## 4. CHARACTER SYSTEM

### 4.1 Starting Characters (V1)

**Character 1: The Kid**
- Base stats: Balanced (medium HP, medium damage, medium speed)
- Special ability: "Growth Spurt" (eat 3 fruits → gain +25% size/damage for 1 room)
- Lore: A determined child learning healthy eating

**Character 2: The Monster**
- Base stats: High HP, low speed, medium damage
- Special ability: "Taste Test" (can hold 2 extra nutrition items; inventory 10 slots)
- Lore: A friendly monster discovering vegetables aren't scary

**Character 3: The Snowman**
- Base stats: Low HP, high speed, medium damage
- Special ability: "Chill Aura" (nearby vegetables take 15% less damage)
- Lore: A cold creature that thrives on icy mechanics (frozen enemies)

**Future Characters:** Unlock with progression (robot, alien, shadow creature, etc.)

### 4.2 Character Customization

**Appearance:**
- Color swaps (red kid, blue monster, etc.)
- Outfit variations (unlockable cosmetics)
- No gameplay impact; purely visual

**Stats by Character:**
| Stat | Kid | Monster | Snowman |
|------|-----|---------|---------|
| HP | 100 | 150 | 80 |
| Damage | 15 | 12 | 18 |
| Speed | 15 | 10 | 20 |
| Special Ability | Growth Spurt | Taste Test | Chill Aura |

---

## 5. TECHNICAL ARCHITECTURE (GODOT)

### 5.1 Project Structure

```
NutriRun/
├── scenes/
│   ├── global/
│   │   ├── GameManager.tscn (persistent game state)
│   │   ├── AudioManager.tscn
│   │   └── SaveManager.tscn
│   ├── ui/
│   │   ├── HUDLayer.tscn (in-game UI)
│   │   ├── InventoryUI.tscn (nutrition items display)
│   │   ├── SynergiesUI.tscn (active synergies display)
│   │   ├── MainMenu.tscn
│   │   ├── HubScreen.tscn
│   │   └── CharacterSelectScreen.tscn
│   ├── gameplay/
│   │   ├── Room.tscn (tilemap + enemy spawners)
│   │   ├── Player.tscn (main character controller)
│   │   └── Horde.tscn (vegetable squad manager)
│   ├── entities/
│   │   ├── characters/
│   │   │   ├── KidCharacter.tscn
│   │   │   ├── MonsterCharacter.tscn
│   │   │   └── SnowmanCharacter.tscn
│   │   ├── vegetables/
│   │   │   ├── TomatoUnit.tscn
│   │   │   ├── CarrotUnit.tscn
│   │   │   ├── PepperUnit.tscn
│   │   │   ├── LettuceUnit.tscn
│   │   │   └── PotatoUnit.tscn
│   │   ├── enemies/
│   │   │   ├── SugarSlug.tscn
│   │   │   ├── GreaseGoblin.tscn
│   │   │   ├── SodaSpecter.tscn
│   │   │   ├── JunkHoarder.tscn
│   │   │   ├── CandyGolem.tscn
│   │   │   └── SugarKingBoss.tscn
│   │   └── items/
│   │       ├── NutritionItem.tscn
│   │       └── KitchenGadget.tscn
│   ├── hub/
│   │   ├── HubScene.tscn (main hub space)
│   │   ├── FurniturePlaceable.tscn
│   │   └── UpgradeTree.tscn
│   └── effects/
│       ├── BuffParticles.tscn
│       ├── DamageNumbers.tscn
│       └── SynergyFlash.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── GameState.gd (global game state)
│   │   ├── SaveSystem.gd (persist data to JSON)
│   │   └── EventBus.gd (signal hub for decoupling)
│   ├── gameplay/
│   │   ├── PlayerController.gd
│   │   ├── HordeManager.gd (squad AI, pathfinding)
│   │   ├── VegetableUnit.gd (base class for all vegetables)
│   │   ├── EnemySpawner.gd
│   │   ├── RoomManager.gd (level progression, difficulty)
│   │   └── NutritionSystem.gd (buff/debuff logic & synergies)
│   ├── ui/
│   │   ├── HUDController.gd
│   │   ├── InventoryUI.gd
│   │   ├── SynergiesDisplay.gd
│   │   └── MainMenuController.gd
│   ├── hub/
│   │   ├── HubController.gd
│   │   ├── FurnitureSystem.gd
│   │   ├── UpgradeTreeController.gd
│   │   └── RecipeManager.gd
│   ├── enemies/
│   │   ├── EnemyBase.gd
│   │   ├── SugarSlug.gd
│   │   ├── GreaseGoblin.gd
│   │   └── [other enemy types]
│   └── utilities/
│       ├── DataStructures.gd (Buff, Synergy, Item classes)
│       ├── MathUtils.gd (synergy calculations)
│       └── AudioPlayer.gd
├── assets/
│   ├── sprites/
│   │   ├── characters/ (pixel art or hand-drawn, 64x64 base)
│   │   ├── vegetables/ (animated sprites, 32x32)
│   │   ├── enemies/ (enemy sprites, varied sizes)
│   │   ├── items/ (nutrition icons, 16x16)
│   │   ├── ui/ (buttons, panels, icons)
│   │   └── effects/ (particle textures, animations)
│   ├── tilemaps/
│   │   ├── garden_tileset.tres
│   │   ├── kitchen_tileset.tres
│   │   └── [room templates]
│   ├── audio/
│   │   ├── sfx/ (eat sounds, attack, hit, unlock)
│   │   └── music/ (menu, hub, gameplay, boss)
│   └── data/
│       ├── character_stats.json
│       ├── nutrition_items.json
│       ├── enemies_config.json
│       ├── synergies.json
│       └── recipes.json
├── scenes_manager.gd (handles scene transitions)
└── project.godot (Godot 4.x config)
```

### 5.2 Core Systems & Responsibilities

#### **GameManager (Autoload Singleton)**
- Track run state (current room, character, inventory, horde composition)
- Manage transitions between hub, character select, and gameplay
- Persist progress to disk (SaveSystem)
- Emit events for UI updates (EventBus)

#### **NutritionSystem.gd**
- Store active nutrition buffs (list of Buff objects)
- Calculate synergies in real-time (check inventory for synergy conditions)
- Apply/remove buffs to player and horde
- Handle buff duration decay
- Data-driven: Load synergies from JSON

#### **HordeManager.gd**
- Manage squad of VegetableUnit instances
- Implement AI pathfinding (A* or simple patrol-chase behavior)
- Attack assignment (target nearest enemy, prioritize targets)
- Formation control (circle, line, loose)
- Scale vegetable stats based on active buffs

#### **PlayerController.gd**
- Handle WASD movement, dash, inventory access
- Track health, collect nutrition items on collision
- Sync buff display to UI
- Handle player death condition

#### **RoomManager.gd**
- Load room layouts (tilemap + enemy spawner data)
- Procedural generation or pre-designed room pools
- Manage difficulty scaling (per-room stat multipliers)
- Track room progression counter
- Spawn minibosses/final boss at appropriate gates

#### **EnemySpawner.gd**
- Define enemy types and counts per room
- Weighted random selection (difficulty-based weights)
- Spawn at designated points in room
- Remove enemies from scene on death

#### **HubController.gd**
- Load hub scene and player's saved decoration layout
- Handle furniture placement/removal
- Display upgrade tree UI
- Calculate harvest points from last run
- Show character selection

#### **SaveSystem.gd**
- Serialize: HarvestPoints, UnlockedDecorations, UnlockedUpgrades, CharacterSkins, RecipeProgress
- Save to `user://nutrirun_save.json`
- Load on startup
- Handle version migrations

### 5.3 Data Classes (GDScript)

```gdscript
# Buff.gd
class_name Buff
extends Resource

var name: String
var duration: float  # seconds; 0 = permanent this run
var stat_multipliers: Dictionary  # {"damage": 1.2, "speed": 1.1}
var special_effect: String  # "chill_aura", "split_fire", etc.

# NutritionItem.gd
class_name NutritionItem
extends Resource

var item_name: String
var item_type: String  # "fruit", "vegetable", "junk", "gadget"
var buff_applied: Buff
var icon: Texture2D
var rarity: String  # "common", "uncommon", "rare"

# Synergy.gd
class_name Synergy
extends Resource

var name: String
var description: String
var condition: String  # "fruit_count >= 3", "junk_count >= 3", "rainbow_colors"
var buff_reward: Buff
var discovery_text: String
```

### 5.4 Networking & Save Format

**NO MULTIPLAYER in V1.** Local save only.

```json
{
  "version": "1.0",
  "harvest_points": 250,
  "unlocked_decorations": ["bench_oak", "plant_fern", "table_round"],
  "unlocked_upgrades": [
    {"name": "horde_size_1", "level": 1},
    {"name": "nutrition_capacity_1", "level": 1}
  ],
  "unlocked_characters": ["kid", "monster"],
  "unlocked_recipes": ["apple_pie", "power_blend"],
  "playtime_minutes": 145,
  "total_rooms_cleared": 87,
  "best_run_rooms": 15,
  "hub_furniture_layout": [
    {"item": "bench_oak", "x": 100, "y": 150},
    {"item": "plant_fern", "x": 200, "y": 100}
  ]
}
```

---

## 6. ART & AUDIO DIRECTION

### 6.1 Visual Style

**Aesthetic:** Neon + Pastels + Anime Silhouettes

**Palette:**
- **Primary Neon:** #4ADE80 (lime green), #38BDF8 (cyan), #C084FC (purple), #FB923C (orange)
- **Pastels:** Soft cream, light peach, pale blue, soft purple
- **Dark Base:** #0F172A (dark slate for backgrounds)

**Sprite Guidelines:**
- **Characters:** 64×64 px, anime-inspired with clear silhouettes
- **Vegetables:** 32×32 px, cute anthropomorphic designs (smiling tomatoes, etc.)
- **Enemies:** 48×48 px, junk-food themed; visually distinct from vegetables
- **UI Icons:** 16×16 px, pixel-perfect, high contrast

**Animation:**
- Idle, walk, attack, hurt, death for all characters & vegetables
- Buff particles (glowing aura) when synergies activate
- Damage numbers float up on hit
- Screen shake on big impacts (synergy activation, boss attacks)

### 6.2 Audio Design

**Music:**
- **Main Menu:** Upbeat, cozy, inviting (loop ~2 min)
- **Hub:** Relaxing, almost ASMR-like (loop ~3 min, layered)
- **Gameplay (Rooms 1-5):** Light, energetic, exploration vibe
- **Gameplay (Rooms 6-12):** Intensity increases, more percussion
- **Gameplay (Rooms 13-15):** Action-packed, boss approaching
- **Boss Fight:** Epic, dramatic, multi-phase music
- **Victory:** Triumphant, rewarding
- **Game Over:** Sad but not harsh

**Sound Effects:**
- **Eating items:** Satisfying crunch/gulp sounds (different per item type)
- **Vegetable attack:** Soft swoosh, impact hit sound
- **Enemy hit:** Bonk, splat, or damage sound (varied per enemy)
- **Synergy activation:** Chime or glittery sound effect
- **Buff gained:** Uplifting tone
- **Debuff gained:** Low warning beep
- **UI clicks:** Soft click (avoid harsh beeps)
- **Room clear:** Celebratory chime
- **Unlock:** Magical "unlock" sound
- **Victory:** Fanfare
- **Defeat:** Slow, gentle fade

**Voice Lines (Optional, V1):**
- Character selection: Light intro voice ("Let's do this!" etc.)
- Synergy discovery: NPC says synergy name
- No constant chatter; keep player focused

---

## 7. USER EXPERIENCE (UX/UI)

### 7.1 Flow Diagram

```
Start Game
  ↓
MainMenu (Play, Settings, Credits, Quit)
  ├→ Play
      ↓
      CharacterSelect (Kid / Monster / Snowman + skins)
      ↓
      HubScreen (decoration, upgrades, start run)
      ├→ Decorate (FurnitureUI)
      ├→ Upgrades (UpgradeTreeUI)
      ├→ Recipes (RecipeListUI)
      └→ Start New Run
          ↓
          GameplayScene (RoomManager + HordeManager + PlayerController)
          ├→ Each Room: Explore, fight, collect nutrition
          ├→ Every 5 Rooms: Miniboss
          ├→ Final Boss (if reached): Sugar King
          └→ Run Ends (Victory or Death)
              ↓
              RunResultsScreen (points earned, unlocks, replay or hub)
              ├→ Replay Run
              └→ Return to Hub
```

### 7.2 HUD Elements (In-Game)

- **Top-left:** Character portrait + health bar
- **Top-right:** Room counter (e.g., "Room 3/15") + elapsed time
- **Center-bottom:** Inventory display (8 slots, show current nutrition items with icons)
- **Right-side:** Active synergies list (show name + buff icon)
- **Bottom-right:** Horde status (number of vegetables alive + health bars)
- **Mini-map:** Small corner map showing room layout + player/enemy positions

### 7.3 Accessibility

- **Colorblind Mode:** Alternate palette (deuteranopia, protanopia variants)
- **Text Scaling:** Large text option for all UI
- **Controller Support:** Full gamepad input (WASD + Mouse for debugging only)
- **Subtitle Toggle:** For SFX descriptions (like "[Buff Sound]")
- **Screen Reader:** Basic support for menu navigation

---

## 8. DEVELOPMENT PHASES & MILESTONES

### Phase 1: Foundation (Weeks 1-2)
- [ ] Godot project setup, folder structure, autoloads
- [ ] Player character controller (basic movement, collision)
- [ ] One tilemap room with static enemies
- [ ] Nutrition item pickup system
- [ ] Basic player health & damage system

### Phase 2: Horde System (Weeks 3-4)
- [ ] Vegetable unit spawning & squad management
- [ ] Horde AI (simple chase-attack behavior)
- [ ] Nutrition buff system (apply buffs to vegetables)
- [ ] Basic combat loop (player + horde vs. enemies)

### Phase 3: Synergies & Balance (Weeks 5-6)
- [ ] Synergy detection & calculation
- [ ] Synergy UI display
- [ ] First pass at data-driven buff values (JSON)
- [ ] Playtesting & balance tuning

### Phase 4: Room Progression (Weeks 7-8)
- [ ] RoomManager with room progression (Act 1, 2, 3)
- [ ] Procedural or hand-crafted room pools
- [ ] Miniboss encounters
- [ ] Difficulty scaling per room

### Phase 5: Hub & Persistence (Weeks 9-10)
- [ ] Hub scene (Café, Garden, or Dorm)
- [ ] Decoration placement system
- [ ] Upgrade tree UI & logic
- [ ] Save/load system (JSON persistence)

### Phase 6: Polish & Content (Weeks 11-12)
- [ ] All 5 enemy types implemented & balanced
- [ ] All 15+ nutrition items with unique sprites
- [ ] Particle effects, screen shake, juice
- [ ] Music & SFX integration
- [ ] Bug fixes & optimization

### Phase 7: Testing & Release Prep (Weeks 13-14)
- [ ] Full playthrough testing
- [ ] Balance tuning (difficulty curve)
- [ ] Performance optimization
- [ ] Build for Windows/Mac/Linux
- [ ] Marketing assets (trailer, screenshots, GIFs)

---

## 9. SUCCESS CRITERIA (V1 MVP)

- [ ] Roguelite loop playable end-to-end (character select → 15 rooms → victory/death → hub → repeat)
- [ ] 3 playable characters with unique abilities
- [ ] 15+ collectible nutrition items (good & bad)
- [ ] 5+ enemy types (nutrition-themed)
- [ ] Vegetable horde AI with autonomous combat
- [ ] Synergy system working (min. 5 synergies implemented)
- [ ] Hub with decoration & upgrade tree
- [ ] Save/load persistent progress
- [ ] All music & SFX integrated
- [ ] Playtime: 10-15 minutes per run
- [ ] No game-breaking bugs; stable on Windows/Mac/Linux

---

## 10. POST-LAUNCH ROADMAP (Optional)

**V1.1:**
- Unlock new characters (robot, alien, shadow creature)
- Add recipe system (combine items for custom buffs)
- Cozy decorative hub expansion

**V1.2:**
- Leaderboard system (runs cleared, fastest time, highest points)
- Daily/weekly challenges
- New enemy types & boss variations

**V2.0 (Future):**
- Multiplayer co-op (2 players, shared horde)
- Story mode with NPCs & narrative
- Advanced synergy system (more complex interactions)
- Custom difficulty modes

---

## 11. REFERENCES & INSPIRATION

**Game Design References:**
- Vampire Survivors (wave-based action, buff stacking)
- Hades (roguelite + cozy hub progression)
- Into the Breach (squad-based tactical combat)
- Spiritfarer (cozy aesthetic + meaningful progression)
- Overcooked (cooperative squad mechanics)

**Market Context:**
- Roguelite genre exploded in 2024-2025 (50+ major releases)
- Cozy games rising as stress-relief (Gen Z mental health focus)
- Educational + fun angle (health/nutrition themes = parental approval)
- Clip culture design (TikTok, YouTube Shorts, Twitch)

---

## 12. NOTES FOR THE ARCHITECT

1. **Start with the gameplay loop first.** Get one room, one character, one enemy type, and the horde system working before worrying about hub progression.

2. **Data-driven design.** All buffs, synergies, enemy stats, and nutrition items should live in JSON files, not hardcoded. This makes balance tuning fast.

3. **Use EventBus pattern.** Decouple systems with signals. When a buff activates, emit a signal; UI listens and updates. When a synergy triggers, emit a signal; audio plays a sound.

4. **Horde AI is the core.** Invest time in making the vegetable units feel smart and responsive. This is what makes combat feel good.

5. **Placeholder art is fine early.** Don't make pixel art perfect in Week 1. Build systems first, polish art in Phase 6.

6. **Test balance early & often.** Run a playthrough every Friday. Track: Which items feel overpowered? Which synergies are boring? Are rooms too hard/easy?

7. **Save system should be simple.** One JSON file. No encryption needed for V1.

8. **Think in clips.** Every mechanic should have a "wow" moment for TikTok: A clutch synergy activation, a boss kill with 1 HP left, a satisfying "crunch" eating sound. Design for that.

9. **Avoid scope creep.** This spec is for V1 MVP only. Multiplayer, story modes, and advanced features are post-launch.

10. **Community first.** Plan speedrun-friendly timings early. Build leaderboards from the start (even if they're simple).

---

## 13. QUESTIONS FOR CLARIFICATION

Before the architect begins, confirm:

1. **Godot Version:** 4.x? (Latest stable, e.g., 4.2 or 4.3?)
2. **Art Style:** Pixel art, hand-drawn, or hybrid?
3. **Hub Choice:** Café, Garden, or Dorm? (Pick one for V1 to reduce scope.)
4. **Room Generation:** Procedural or hand-crafted room pools?
5. **Difficulty:** Target age group? (All ages vs. 8+ vs. family-friendly?)
6. **Release Timeline:** 3 months, 6 months, longer?
7. **Team Size:** Solo dev, small team, external contractors?
8. **Platform Priority:** Windows first, or simultaneous Mac/Linux?

---

## END OF SPECIFICATION

**This document is ready for a specialist architecture agent to build a detailed technical plan, system design docs, and development breakdown.**
