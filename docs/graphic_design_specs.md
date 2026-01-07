# NutriRun - Graphic Design Specifications

## Game Overview

**NutriRun** is a 2D top-down roguelite game with a nutrition/health theme. Players control characters who eat healthy foods to gain power-ups while fighting junk-food themed enemies.

**Target Audience:** Family-friendly (ages 8-18+)
**Art Style:** Pixel Art
**Visual Direction:** Neon + Pastels - vibrant, energetic, cozy arcade feel

---

## Asset Request #1: Enemy Sprite

### Description
Create one enemy character sprite. The enemy should be **virus/disease themed** - representing unhealthy elements that attack the player.

**Suggested enemy concept:** A menacing virus or germ creature

### Specifications
- **Canvas Size:** 32x32 pixels (matches current enemy_size in code)
- **Format:** PNG with transparency
- **Style:** Pixel art, cute but menacing

### Vibe & Direction
- Should look like a "bad guy" but in a playful way (not scary - family-friendly)
- Virus/disease inspired design (spiky corona shape, blob-like germ, bacterial creature)
- Distinct silhouette - easily recognizable at a glance
- Color palette: Sickly greens, purples, toxic yellows, or angry reds

### Reference Ideas
- Spiky virus ball with angry eyes (corona-style shape)
- Blob-like germ creature with tentacles
- Bacterial rod shape with menacing expression
- Toxic slime creature

---

## Asset Request #2: Player Character ("Kid")

### Description
Create the main player character - "The Kid". This is the balanced starter character that most players will see first.

### Specifications
- **Canvas Size:** 32x32 pixels (matches current player size in code: player_half_size=16)
- **Format:** PNG with transparency
- **Style:** Pixel art, anime-inspired silhouette

### Character Concept
- Young, energetic kid (could be any gender - keep it neutral/inclusive)
- Athletic or sporty vibe - this character runs and fights!
- Friendly, heroic appearance
- Should look like a protagonist players want to root for

### Vibe & Direction
- Bright, vibrant colors - neon accents work great (lime green, cyan, purple, orange)
- Clear, readable silhouette from a top-down perspective
- Expressive even at small size
- Could have a simple outfit (t-shirt, shorts, sneakers) or something more stylized

---

## Asset Request #3: Map Tiles (Tileset)

### Description
Create a basic tileset for the game's arena/room floors and boundaries.

**Note:** Currently the game uses a single ColorRect for the floor (no tile system yet). These tiles will be used to replace that with proper tilemap art.

### Specifications
- **Tile Size:** 32x32 pixels each (standard Godot tilemap size)
- **Format:** PNG (can be individual tiles or a sprite sheet)
- **Style:** Pixel art, seamless tiling

### Tiles Needed
1. **Floor tile(s)** - The main ground players walk on (1-3 variations for visual interest)
2. **Wall/boundary tiles** - Edges of the arena (top, bottom, left, right, corners)
3. **Simple decorations** (optional) - Small details like cracks, stains, or accent tiles

### Vibe & Direction
- Dark base color for floors (dark blues, slate, charcoal)
- Neon accents on walls/edges (glowing trim, colorful highlights)
- Clean and not too busy - gameplay clarity is important
- Think "neon arcade" or "futuristic gym" aesthetic

---

## Asset Request #4: Animation Guidelines

For future animations, here are the specifications to keep in mind:

### Movement Animations Needed

**Idle Animation**
- 2-4 frames
- Subtle movement (breathing, slight bounce)
- Loop seamlessly

**Walk/Run Cycle**
- 4-6 frames for walk, 6-8 frames for run
- Smooth, energetic movement
- Should feel responsive and fun

### Direction Handling

The game uses **4-directional or 8-directional** movement. For a basic implementation:

**4 Directions (minimum):**
- Down (facing camera)
- Up (facing away)
- Left
- Right

**8 Directions (ideal):**
- Add diagonal variants (down-left, down-right, up-left, up-right)

### Sprite Sheet Format

Preferred layout for animation sprite sheets:
```
[Frame1][Frame2][Frame3][Frame4]...  <- Direction 1 (Down)
[Frame1][Frame2][Frame3][Frame4]...  <- Direction 2 (Left)
[Frame1][Frame2][Frame3][Frame4]...  <- Direction 3 (Right)
[Frame1][Frame2][Frame3][Frame4]...  <- Direction 4 (Up)
```

**Frame timing:** ~100-150ms per frame for walk, ~80-100ms for run

---

## Color Palette Reference

These are suggested colors, not strict requirements:

**Neon Accents:**
- Lime Green: #4ADE80
- Cyan: #38BDF8
- Purple: #C084FC
- Orange: #FB923C

**Background/Base:**
- Dark Slate: #0F172A
- Charcoal variations

**Pastels (for softer elements):**
- Soft cream, light peach, pale blue, soft purple

---

## File Delivery

Please deliver assets as:
- Individual PNG files with transparency
- Named clearly (e.g., `enemy_sugar_slug.png`, `player_kid.png`, `tiles_floor_01.png`)
- Original working files if possible (for future edits)

---

## Code Reference (Current Sizes)

These sizes are from the actual codebase:

| Entity | File | Size |
|--------|------|------|
| Player | `scripts/gameplay/PlayerController.gd:36` | 32x32 (player_half_size=16) |
| Enemy | `scripts/enemies/EnemyBase.gd:216` | 32x32 (enemy_size=32) |
| Nutrition Items | `scripts/entities/NutritionPickup.gd:57` | 24-32 (varies by rarity) |
| Vegetable Units | `scripts/gameplay/VegetableUnit.gd:176` | 28x28 |
| Inventory Slots | `scenes/ui/inventory_slot.tscn:6` | 48x48 (UI display) |

---

## Questions?

Feel free to take creative liberties! These specs are guidelines, not strict rules. The goal is to bring the game to life with personality and charm. If you have ideas that diverge from these specs but would look great, go for it!
