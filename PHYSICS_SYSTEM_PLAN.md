# Comprehensive Physics & Collision System Plan

## Current State Analysis

### Physics Layers (Godot Bit Masks)
- **Layer 1 (bit 0)**: Walls/Environment
- **Layer 2 (bit 1)**: Player CharacterBody2D
- **Layer 3 (bit 2)**: Enemy CharacterBody2D
- **Layer 4 (bit 3)**: Player Hurtbox (Area2D for receiving damage)
- **Layer 5 (bit 4)**: Enemy Hitbox (Area2D for dealing damage)

### Current Collision Setup

#### Player (CharacterBody2D)
- **collision_layer**: 2 (Layer 2)
- **collision_mask**: 5 (Layers 1+3 = Walls + Enemies)
- **Hurtbox (Area2D)**: layer=8, mask=16 (receives damage from enemy hitboxes)

#### Enemy (CharacterBody2D)
- **collision_layer**: 4 (Layer 3)
- **collision_mask**: 3 (Layers 1+2 = Walls + Player)
- **Hitbox (Area2D)**: layer=16, mask=8 (deals damage to player hurtbox)

#### Vegetable Allies (CharacterBody2D)
- **collision_layer**: Not set (defaults to 1)
- **collision_mask**: Not set (defaults to 1)
- Only use `move_and_slide()` for movement

### Current Problems

1. **Mixed Collision Systems**
   - Damage uses Area2D hitbox/hurtbox (correct)
   - Knockback uses velocity modification (partially working)
   - Push uses `move_and_collide()` after `move_and_slide()` (conflicting systems)

2. **Illogical Push Direction**
   - Currently: Player gets pushed in enemy's movement direction on ANY collision
   - Problem: If enemy moves UP and hits player from the SIDE, player shouldn't be pushed UP
   - The push should only occur when enemy hits from the "front" of its movement

3. **Conflicting Movement Calls**
   - `move_and_slide()` in `_handle_movement()`
   - `move_and_collide()` in `_apply_collision_push()`
   - These should not be mixed in the same frame

4. **No Distinction Between**
   - Contact damage (area overlap)
   - Physical collision (body collision)
   - Knockback (temporary force from taking damage)
   - Push (continuous force from physical collision)

---

## Proposed Physics System Design

### Core Principles

1. **Separation of Concerns**
   - **Area2D Hitbox/Hurtbox**: ONLY for damage detection
   - **CharacterBody2D Collision**: ONLY for physical blocking/pushing
   - **Knockback**: Temporary velocity impulse from taking damage
   - **Push**: Continuous force applied during body collision

2. **Directional Push Logic**
   - Enemy pushes player ONLY when hitting from the "front" of movement
   - Use dot product to determine if collision is frontal
   - Threshold: dot(enemy_velocity, collision_normal) > 0.5 means frontal hit

3. **Single Movement System**
   - Use ONLY `move_and_slide()` for all movement
   - Accumulate all forces (input, knockback, push) into velocity
   - No `move_and_collide()` mixing

### Physics Forces Breakdown

```
Final Velocity = Input Velocity + Knockback Velocity + Push Velocity

Where:
- Input Velocity: Player/Enemy movement input (continuous)
- Knockback Velocity: Impulse from taking damage (decays over time)
- Push Velocity: Continuous force from physical collision (applied each frame during collision)
```

### Directional Push Implementation

```gdscript
# Pseudo-code for determining if push should apply
var enemy_to_player = (player_pos - enemy_pos).normalized()
var collision_normal = collision.get_normal()  # Points AWAY from enemy
var enemy_velocity = enemy.velocity.normalized()

# Dot product tells us if enemy is moving "into" the player
var frontal_hit = enemy_velocity.dot(-collision_normal)

# Only push if hitting from front (>0.5 means >60 degree alignment)
if frontal_hit > 0.5:
    apply_push_in_direction(enemy_velocity)
```

### Example Scenarios

**Scenario 1: Enemy moving RIGHT, hits player from LEFT side**
- Enemy velocity: (1, 0)
- Collision normal: (-1, 0) (points left, away from enemy)
- Dot product: (1,0) · (1,0) = 1.0 > 0.5 ✓
- **Result: PUSH APPLIED** (frontal collision)

**Scenario 2: Enemy moving UP, hits player from RIGHT side**
- Enemy velocity: (0, -1)
- Collision normal: (1, 0) (points right, away from enemy)
- Dot product: (0,-1) · (-1,0) = 0.0 < 0.5 ✗
- **Result: NO PUSH** (side collision)

**Scenario 3: Enemy moving UP-RIGHT, hits player from BOTTOM-LEFT**
- Enemy velocity: (0.707, -0.707)
- Collision normal: (-0.707, 0.707) (points down-left, away from enemy)
- Dot product: (0.707,-0.707) · (0.707,-0.707) = 0.5 + 0.5 = 1.0 > 0.5 ✓
- **Result: PUSH APPLIED** (frontal collision)

---

## Implementation Plan

### Phase 1: Code Cleanup
**Goal: Remove conflicting systems**

1. **Remove `_apply_collision_push()` entirely**
   - Delete the function
   - Remove call from `_physics_process()`

2. **Consolidate into single velocity system**
   - Keep `knockback_velocity` (from damage)
   - Add `push_velocity` (from collisions)
   - Combine in `_handle_movement()`

3. **Remove unused variables**
   - `collision_push_strength` (will use new push force)

### Phase 2: Implement Directional Push System

1. **Add new player variables**
   ```gdscript
   var push_velocity: Vector2 = Vector2.ZERO
   var push_force: float = 200.0  # Force applied during push
   var push_dot_threshold: float = 0.5  # Minimum alignment for push
   ```

2. **Create `_calculate_push_forces()` function**
   - Called AFTER `move_and_slide()`
   - Iterate through `get_slide_collision_count()`
   - Check if collider is enemy
   - Calculate dot product for directional check
   - Accumulate push forces

3. **Update `_handle_movement()` to combine forces**
   ```gdscript
   func _handle_movement(delta: float) -> void:
       var input_vector = _get_input_vector()
       var input_velocity = input_vector * speed

       # Combine all forces
       velocity = input_velocity + knockback_velocity + push_velocity

       move_and_slide()

       # Calculate push from collisions AFTER movement
       _calculate_push_forces()
   ```

4. **Decay push velocity each frame**
   - Similar to knockback decay
   - Fast decay (cleared almost immediately when not colliding)

### Phase 3: Refine Damage & Knockback Separation

1. **Clarify knockback source**
   - Knockback ONLY from taking damage
   - Triggered in `take_damage()` function
   - Short-lived impulse (current system is fine)

2. **Ensure hitbox/hurtbox independence**
   - Hitbox/Hurtbox continue to handle damage
   - No position/physics changes from area overlap
   - Pure damage detection only

### Phase 4: Balance & Configuration

1. **Add to game_balance.json**
   ```json
   "player": {
       "push_force": 200.0,
       "push_dot_threshold": 0.5,
       "push_decay": 15.0
   }
   ```

2. **Tuning parameters**
   - `push_force`: How strong the push effect is
   - `push_dot_threshold`: How "frontal" collision must be (0.0-1.0)
   - `push_decay`: How quickly push force dissipates

### Phase 5: Testing Scenarios

1. **Enemy approaching from front**: Should push player back
2. **Enemy approaching from side**: Should NOT push (or minimal push)
3. **Multiple enemies surrounding**: Push forces should accumulate directionally
4. **Player moving toward enemy**: Should still be pushed if enemy velocity is stronger
5. **Stationary enemy hit by player**: No push (enemy velocity = 0)

---

## Technical Details

### Collision Detection Flow

```
Frame Start
    ↓
Input Processing → input_velocity
    ↓
Knockback Decay → knockback_velocity
    ↓
Push Decay → push_velocity (from previous frame)
    ↓
Combine Forces → velocity = input + knockback + push
    ↓
move_and_slide() → Godot physics resolution
    ↓
Analyze Collisions → get_slide_collision_count()
    ↓
Calculate New Push Forces → push_velocity (for next frame)
    ↓
Boundary Clamping
    ↓
Frame End
```

### Push Force Calculation (Detailed)

```gdscript
func _calculate_push_forces() -> void:
    # Reset push velocity (will be recalculated)
    var accumulated_push = Vector2.ZERO

    for i in range(get_slide_collision_count()):
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()

        # Only enemies can push
        if not collider or not collider.is_in_group("enemies"):
            continue

        # Get enemy velocity
        var enemy_vel = collider.velocity if "velocity" in collider else Vector2.ZERO
        if enemy_vel.length_squared() < 1.0:  # Stationary enemies don't push
            continue

        var enemy_vel_norm = enemy_vel.normalized()
        var collision_normal = collision.get_normal()

        # Calculate if this is a frontal hit
        # collision_normal points AWAY from the enemy (toward player)
        # We want to know if enemy is moving INTO the player
        var dot_product = enemy_vel_norm.dot(-collision_normal)

        if dot_product > push_dot_threshold:
            # This is a frontal collision - apply push
            var push_strength = dot_product  # 0.5 to 1.0
            accumulated_push += enemy_vel_norm * push_force * push_strength

    # Set push velocity for next frame
    push_velocity = accumulated_push
```

### Variables to Add

**PlayerController.gd**
```gdscript
# Physics forces
var push_velocity: Vector2 = Vector2.ZERO
var push_force: float = 200.0
var push_dot_threshold: float = 0.5
var push_decay: float = 15.0  # How fast push dissipates when not colliding
```

### Variables to Remove

**PlayerController.gd**
```gdscript
var collision_push_strength: float = 150.0  # REMOVE - replaced by push_force
```

### Functions to Modify

1. **`_physics_process(delta)`**
   - Remove: `_apply_collision_push()` call
   - Add: `_decay_push(delta)` call

2. **`_handle_movement(delta)`**
   - Add push_velocity to velocity calculation
   - Add `_calculate_push_forces()` call after `move_and_slide()`

3. **`_load_game_balance()`**
   - Load push_force, push_dot_threshold, push_decay

### Functions to Add

1. **`_calculate_push_forces()`** - Calculate push from current collisions
2. **`_decay_push(delta)`** - Decay push velocity when not colliding

### Functions to Remove

1. **`_apply_collision_push()`** - Completely replace with new system

---

## Benefits of This Design

1. **Physically Intuitive**
   - Enemy only pushes when hitting from the direction it's moving
   - Side/rear collisions don't create unrealistic pushes

2. **Clean Separation**
   - Damage system (Area2D) completely separate from physics
   - All movement uses single `move_and_slide()` call
   - All forces accumulate into one velocity vector

3. **Configurable**
   - Easy to tune push strength
   - Adjustable directional threshold
   - Balance between realism and gameplay

4. **Predictable**
   - Clear force calculation each frame
   - No conflicting movement systems
   - Easier to debug and understand

5. **Extensible**
   - Easy to add more force types (wind, explosions, etc.)
   - Can apply same system to vegetables if needed
   - Foundation for more complex physics interactions

---

## Migration Path

### Step 1: Backup Current System
- Current code works (even if not perfect)
- Can revert if needed

### Step 2: Implement New Variables
- Add push_velocity, push_force, etc.
- Load from game_balance.json

### Step 3: Replace Push System
- Remove old `_apply_collision_push()`
- Add new `_calculate_push_forces()`
- Update `_handle_movement()`

### Step 4: Test & Iterate
- Test all scenarios
- Adjust thresholds and forces
- Balance gameplay vs realism

### Step 5: Apply to Other Entities (Optional)
- Vegetables could push each other
- Enemies could push each other
- Player could push lighter entities

---

## Open Questions for User

1. **Should player be able to push enemies?**
   - Currently: No (enemies don't check player collisions for push)
   - Could: Player with higher speed/momentum could push lighter enemies

2. **Should vegetables experience push?**
   - Currently: No collision physics with other entities
   - Could: Add collision layers for vegetable-enemy blocking

3. **Push force scaling?**
   - Should push force scale with enemy speed?
   - Should heavier/larger enemies push harder?

4. **Multiple enemy push accumulation?**
   - Current plan: Forces accumulate (can be pushed by multiple enemies)
   - Alternative: Cap maximum push force

5. **Push during invincibility?**
   - Should player still be pushed while invincible (no damage)?
   - Currently: Invincibility only prevents damage, not physics
