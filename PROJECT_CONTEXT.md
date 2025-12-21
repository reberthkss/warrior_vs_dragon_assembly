# Warrior vs Dragon - MIPS Assembly Game

## Project Overview
A turn-based battle game written in MIPS Assembly featuring a warrior fighting against a dragon. The game includes graphical rendering on a 256x256 display and implements a unique **Compound Interest Debt** mechanic alongside traditional HP-based combat.

## Project Structure (Modular Architecture)

The project has been refactored into a modular structure for better organization and maintainability:

### File Organization
- **main.asm** - Main game loop, entry point, and turn handler (~192 lines)
- **data.asm** - Game variables, constants, and text messages (~179 lines)
- **battle.asm** - Player/dragon attack functions and damage calculations (~998 lines)
- **quiz.asm** - Quiz system with question handling and validation (~479 lines)
- **rendering.asm** - Graphics rendering engine, sprites, and HP/stamina bars (~603 lines)
- **sprites.asm** - Sprite data for player and dragon (contains all sprite definitions)
- **macros.asm** - Assembly macros for common operations (~352 bytes)
- **include_all.asm** - Module import file (~379 bytes)
- **sprites/converter_sprites.py** - Python utility to convert PNG images to MIPS sprite data

### Module Responsibilities

**main.asm**: Core game flow
- Entry point and initialization
- Main game loop with victory/defeat checks
- Player turn handler and action menu
- Estus Flask regeneration per turn
- Shield restriction logic for offensive actions
- Game over handlers

**data.asm**: Data definitions
- Display configuration and color constants (including stamina bar color)
- Game state variables (HP, debt, turn, status effects, stamina)
- Stamina system variables and costs
- Animation state variables (spear, fireball positions)
- Quiz questions and answers (6 questions in Portuguese)
- All game messages and UI text

**battle.asm**: Combat mechanics
- Player attacks: Sword, Flank, Spear (with animations)
- Dragon attacks: Fire Breath, Stomp, Fly, Inferno (with preparation phase)
- Damage calculation functions with evasion/flying modifiers
- Compound interest system (apply, payment)
- Stamina cost validation for all abilities
- Shield damage absorption system
- Estus Flask healing with regeneration over time
- Dragon fireball animation
- Insufficient stamina handler

**quiz.asm**: Educational quiz feature
- Quiz ability implementation with 6 questions
- Random question selection from unanswered pool
- Answer validation
- Completion tracking (per-question flags)
- Stamina cost (50) for quiz ability

**rendering.asm**: Visual presentation
- Modular rendering: `render_all`, `render_background`, `render_characters`, `render_ui`
- Unit-specific drawing: `draw_player_unit`, `draw_dragon_unit`
- Sprite poses: normal, shield, spear, defeated, inferno, defense, preparing
- HP bar drawing with scaling and damage colors
- Stamina bar drawing (blue, below HP bars)
- Turn cursor indicator (adjusts for flying dragon)
- Animation trail erasure functions
- Battle status display with shield indicator

## Technical Specifications

### Display Configuration
- **Resolution**: 256x256 pixels
- **Display Address**: `0x10040000`
- **Unit Width**: 1 (256 columns per row)
- **Color Format**: 32-bit RGBA

### Game Mechanics

#### Core Systems
1. **HP System**
   - Player: 100 HP (max)
   - Dragon: 1000 HP
   - Defeat when Player HP ≤ 0
   - Victory when Dragon HP ≤ 0

2. **Stamina System** (NEW)
   - Both player and dragon have 100 max stamina
   - Regenerates 15 stamina per turn
   - Each ability has a stamina cost
   - Actions fail if insufficient stamina
   - Visual blue stamina bars on screen

3. **Compound Interest Debt System**
   - Unified Debt Counter: Starts at 0
   - Debt Limit: 10,000
   - **Victory Condition**: Debt Counter ≥ 10,000
   - **Compound Interest Formula**: `newDebt = currentDebt + (currentDebt × 10%) + 100`
   - Player's successful attacks increase debt via compound interest
   - Dragon's successful attacks decrease debt by 5%

4. **Turn-Based Combat**
   - Player chooses action first (turn = 0)
   - Dragon attacks second (turn = 1)
   - Turn counter tracks current round number
   - **Input**: Number (0-6) to select action

#### Player Actions
The player can choose from 7 different actions each turn:

0. **Skip Turn**
   - Player takes no action
   - Useful for stamina regeneration
   - Stamina Cost: 0

1. **Shield (Defense)**
   - Activates 50 HP damage absorption shield
   - **Blocks offensive actions** while active (2-5)
   - Toggle: Use again to cancel shield
   - Stamina Cost: 0
   - Visual: Displays warrior with shield sprite

2. **Sword Ability**
   - Stuns the dragon (dragon loses next turn)
   - No direct HP damage
   - Applies compound interest to debt counter
   - Resets dragon flying status and player evasion
   - Stamina Cost: 25

3. **Flank Ability**
   - Hit Chance: 80% (miss if random < 20)
   - Critical Chance: 40% (if random ≥ 60) - **HIGHER than normal**
   - Normal Damage: 15-24 - **HIGHER than normal**
   - Critical Damage: 30
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50%
   - Stamina Cost: 40

4. **Spear Ability**
   - Animated spear projectile attack
   - Hit Chance: 80% (same as normal)
   - Critical Chance: 15% (if random ≥ 85)
   - Normal Damage: 5-9 - **LOWER than normal**
   - Critical Damage: 15
   - **Increases player evasion** (persists for next dragon turn)
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50%
   - Stamina Cost: 20
   - Visual: Flying spear animation with trail erasure

5. **Quiz Ability (Computer Architecture Quiz)**
   - **6 Educational Questions** in Portuguese about computer architecture and hardware
   - **Random Selection**: Questions are randomly selected from unanswered pool
   - Questions can only be answered correctly once each
   - Displays remaining questions counter
   - **Correct Answer**: 5x compound interest applied (massive boost!)
   - **Wrong Answer**: -5 HP penalty (with shield absorption) + 1x compound interest
   - **Completion Tracking**: Each question marked as completed when answered correctly
   - **Quiz Questions**:
     1. Which CPU component performs mathematical and logical operations? (Answer: ULA/ALU)
     2. Which memory type is volatile and loses data when powered off? (Answer: RAM)
     3. In Von Neumann model, which bus transports memory addresses? (Answer: Address Bus)
     4. What is the smallest unit of information a computer can process? (Answer: Bit)
     5. Which component is exclusively an input device? (Answer: Teclado/Keyboard)
     6. What unit measures processor clock speed frequency? (Answer: Gigahertz/GHz)
   - Shows "Questoes restantes: X" before each quiz
   - Stamina Cost: 50

6. **Estus Flask (Heal)**
   - **Limited Resource**: 2 charges total
   - **Immediate Heal**: Restores 25 HP
   - **Regeneration**: Restores 25 HP per round for 2 additional rounds
   - Consumes player turn
   - Cannot be used if another Estus effect is already active
   - Stamina Cost: 0

#### Dragon Attacks
The dragon randomly chooses one of four attacks (25% each), with stamina validation:

1. **Fire Breath** (Cost: 20 stamina)
   - Animated fireball projectile
   - Hit Chance: 35% (miss if random ≥ 35)
   - Critical Chance: 15% (if random ≥ 20 and < 35)
   - Normal Damage: 25-40 (increased from original)
   - Critical Damage: 60
   - Reduces debt counter by 5% on hit
   - Special: If player has evasion, dragon needs 50+ to hit (50% hit chance)

2. **Stomp** (Cost: 30 stamina)
   - Stuns the player
   - Player loses next turn
   - Reduces debt counter by 5%
   - Stun resets after skipped turn

3. **Fly** (Cost: 25 stamina)
   - Increases dragon evasion
   - Reduces player hit chance to 50% next turn
   - Reduces player critical chance to 10% next turn
   - No damage or debt effect
   - Effect resets after player's next attack
   - Visual: Dragon rendered at higher Y position

4. **Inferno** (Cost: 50 stamina)
   - **Two-Phase Attack**: Preparation turn → Attack turn
   - Shows "gathering fire" message during preparation
   - Devastatting fire attack on next dragon turn
   - **High Hit Chance**: 80% (20% miss chance)
   - **Massive Damage**: 45-65 HP
   - Reduces debt counter by 5% on hit
   - Visual: Special dragon pose during preparation

5. **Defense Stance** (No cost - fallback)
   - Triggered when dragon has no stamina for any attack
   - Dragon enters defense stance
   - Visual: Displays `sprite_dragon_defense`

#### Status Effects

**Player Stunned** (`playerStunned`)
- Cannot act during their turn
- Turn is skipped automatically
- Dragon gets consecutive attacks
- Resets after skipped turn

**Dragon Stunned** (`dragonStunned`)
- Cannot act during their turn (from Sword ability)
- Turn is skipped automatically
- Player gets consecutive turns
- Resets after skipped turn

**Player Evasion** (`playerEvasion`)
- Activated by Spear ability
- Reduces dragon's hit chance from 35% to 50% miss rate
- Persists for the next dragon turn
- Resets after dragon attacks or player uses another ability

**Dragon Flying** (`dragonFlying`)
- Activated by Fly attack
- Reduces player's hit chance to 50%
- Reduces player's critical chance to 10%
- Resets after player's next attack
- Visual: Dragon and HP/stamina bars rendered at higher Y position

**Dragon Defense** (`dragonDefense`)
- Activated when dragon has no stamina
- Dragon uses defense stance sprite
- Resets when dragon attacks next turn

**Warrior Shield** (`warriorShield`)
- Activated by Shield action (value: 50)
- Absorbs incoming damage until depleted
- **Blocks offensive actions** while active
- Visual: Warrior with shield sprite

**Dragon Preparing Inferno** (`dragonPreparingInferno`)
- Set when dragon initiates Inferno
- On next dragon turn, unleashes full Inferno attack
- Visual: Special preparation sprite

### Graphics System

#### Color Palette
- Ground: `0x228B22` (Grass Green)
- Sky: `0x87CEEB` (Sky Blue)
- HP Bar: `0x00FF00` (Life Green)
- HP Bar Damaged: `0xFF0000` (Red - when player HP = 0)
- Stamina Bar: `0x3399FF` (Blue)
- Cursor: `0xFFFF00` (Yellow)

#### Rendering Architecture
The rendering system is modular:
- `render_all` → calls background, characters, UI
- `render_background` → sky and ground rectangles
- `render_characters` → player and dragon units with pose logic
- `render_ui` → HP bars, stamina bars, turn cursor

#### Screen Layout
- Sky: Y 0-199
- Ground: Y 200-255
- Warrior Sprite: X=50, Y=185 (normal) / Y=195 (defeated)
- Dragon Sprite: X=180, Y=185 (ground) / Y=140 (flying) / Y=175 (defeated)
- Player HP Bar: X=50, Y=175, Height=4, Width=(HP/2) pixels max 50
- Player Stamina Bar: X=50, Y=180, Height=3, Width=(stamina/2) pixels
- Dragon HP Bar: X=180, Y=175 (ground) / Y=130 (flying), Height=4, Width=(HP/20) pixels max 50
- Dragon Stamina Bar: X=180, Y=180 (ground) / Y=135 (flying), Height=3
- Turn Cursor: Near active character (adjusts for flying)

#### Sprite System
- Sprites stored with header: [Width, Height, Pixel Data]
- Transparent pixels: Color value 0x00000000
- Available sprites:
  - `sprite_player` - Normal warrior stance
  - `sprite_player_defeated` - Fallen warrior
  - `warrior_shield` - Warrior with shield
  - `warrior_spear` - Warrior throwing spear
  - `spear` - Flying spear projectile
  - `sprite_dragon` - Normal dragon
  - `sprite_dragon_defeated` - Fallen dragon
  - `sprite_dragon_inferno` - Dragon breathing fire
  - `sprite_dragon_preparing_inferno` - Dragon gathering fire
  - `sprite_dragon_defense` - Dragon in defense stance
  - `fireball` - Dragon's fireball projectile

### Animation System

**Spear Animation** (`spear_attack_active`, `spearX`)
- Spear moves from X=60 towards X=180 (dragon position)
- Animation speed: 10 pixels per frame
- Trail erasure at old position
- Triggers damage calculation on completion

**Fireball Animation** (`fireball_attack_active`, `fireballX`)
- Fireball moves from X=180 towards X=50 (player position)
- Animation speed: 10 pixels per frame (moving left)
- Trail erasure at trailing edge (X+48)
- Dragon shown in inferno pose during animation

### Game States

#### Victory Conditions
- Dragon HP ≤ 0: "VICTORY! - Dragon Defeated!"
- Debt Counter ≥ 10,000: "VICTORY BY COMPOUND INTEREST! Debt reached 10,000!"

#### Defeat Conditions
- Player HP ≤ 0: "DEFEAT..."

### Status Display (Terminal Output)
```
====== BATTLE STATUS ======
Turn: [number]
[Player] HP: [value] | Stamina: [value] [SHIELD: X] | Debt: [value] | Estus: [count]
[Dragon] HP: [value] | Stamina: [value]
[$ DEBT COUNTER: [value] / 10,000]
[ESTUS ACTIVE] Rounds remaining: [count] (if active)
```

### Action Menu
```
[PLAYER] Choose: (0)Skip (1)Shield (2)Sword (3)Flank (4)Spear (5)Quiz (6)Estus -
```

## Key Functions by Module

### Main Game Loop (main.asm)
- `main`: Entry point, displays welcome messages
- `game_loop`: Main game loop with HP and debt victory checks, Estus regen
- `player_turn`: Regenerates stamina, checks stun status then shows action menu
- `player_can_act`: Displays action menu and handles player input
- `get_player_input`: Validates input and routes to action handlers
- `shield_error`: Displays error when trying offensive action with shield
- `game_over_win`: Victory by dragon defeat
- `game_over_lose`: Defeat by player death
- `game_over_win_debt`: Victory by reaching 10,000 debt
- `exit`: Program termination

### Battle System (battle.asm)
- `player_skip_turn`: Player does nothing
- `player_sword_attack`: Stuns dragon, applies compound interest
- `player_flank_attack`: High critical chance attack
- `player_lance_attack`: Defensive attack with evasion buff and animation
- `spear_anim_loop`: Handles spear projectile animation
- `player_use_estus`: Consumable healing item (immediate + regen)
- `apply_estus_regen`: Handles round-by-round regeneration
- `monster_turn`: Regenerates stamina, checks dragon stun, then AI attack selection
- `dragon_can_act`: Dragon attack AI with stamina validation
- `try_dragon_fire/stomp/fly/inferno`: Stamina validation for each attack
- `dragon_skip_no_stamina`: Fallback to defense stance
- `do_dragon_fire`: Fire breath with fireball animation
- `dragon_stomp`: Stuns player and reduces debt by 5%
- `dragon_fly`: Increases dragon evasion for next turn
- `dragon_inferno_prep`: Initiates two-phase Inferno attack
- `dragon_inferno_unleash`: Executes prepared Inferno
- `dragon_inferno`: High damage fire attack, reduces debt by 5%
- `dragon_fireball_animation`: Animated fireball projectile
- `calculate_attack_damage`: Player normal attack with evasion check
- `calculate_flank_damage`: Flank attack damage calculation
- `calculate_lance_damage`: Spear attack damage calculation
- `calculate_dragon_damage`: Dragon fire breath with player evasion check
- `apply_compound_interest`: Applies 10% interest + 100 base to debt counter
- `apply_compound_interest_direct`: Custom interest calculation with parameters
- `apply_dragon_payment`: Reduces debt by 5% when dragon hits or stomps
- `apply_damage_to_player`: Applies damage with shield absorption
- `insufficient_stamina`: Handler for low stamina actions

### Quiz System (quiz.asm)
- `player_quiz_attack`: Educational quiz with 6 questions, completion tracking
- `quiz_all_completed`: Handler when all questions answered
- `show_quiz_1` through `show_quiz_6`: Display individual quiz questions
- `check_quiz_answer`: Validates answer and marks question as completed on success
- `apply_correct_bonus`: Applies 5x compound interest for correct answer
- `quiz_wrong`: Applies -5 HP penalty (with shield) and 1x compound interest
- `quiz_finish`: Updates debt display and switches turn
- `find_next_quiz`: Randomly selects an unanswered question from available pool
- `count_remaining_questions`: Counts how many questions are still available

### Graphics Engine (rendering.asm)
- `render_all`: Main rendering function (calls modular sub-functions)
- `render_background`: Draws sky and ground
- `render_characters`: Draws player and dragon units
- `render_ui`: Draws HP bars, stamina bars, and turn cursor
- `draw_player_unit`: Renders player with pose logic (normal, shield, spear, defeated)
- `draw_dragon_unit`: Renders dragon with pose logic (normal, flying, inferno, prep, defense, defeated)
- `draw_hp_bars`: Draws HP bars with scaling and damage colors
- `draw_stamina_bars`: Draws blue stamina bars below HP bars
- `draw_turn_cursor`: Draws yellow cursor near active combatant
- `erase_spear_trail`: Cleans up spear animation trail
- `erase_fireball_trail`: Cleans up fireball animation trail
- `draw_sprite_pro`: Renders sprites with transparency support
- `func_draw_rect`: Draws filled rectangles
- `show_status`: Displays HP, stamina, shield, and debt counter in terminal

## Game Variables
```assembly
# Core Combat
playerHP:       100
monsterHP:      1000
debtCounter:    0      # Unified compound interest debt counter
debtLimit:      10000  # Victory threshold
turn:           0      # 0=Player, 1=Monster
turnCounter:    1      # Current round number

# Status Effects
playerStunned:  0      # 0=Normal, 1=Stunned (from Stomp)
dragonStunned:  0      # 0=Normal, 1=Stunned (from Sword)
dragonFlying:   0      # 0=Ground, 1=Flying (evasion buff)
dragonDefense:  0      # 0=Normal, 1=Defense stance
playerEvasion:  0      # 0=Normal, 1=Evasion (from Spear)
warriorShield:  0      # Shield HP (0=inactive, 50=active)

# Stamina System
playerStamina:      100
playerMaxStamina:   100
dragonStamina:      100
dragonMaxStamina:   100
staminaRegen:       15     # Per turn

# Stamina Costs (Player)
staminaCostShield:  0
staminaCostSword:   25
staminaCostFlank:   40
staminaCostSpear:   20
staminaCostQuiz:    50
staminaCostEstus:   0

# Stamina Costs (Dragon)
staminaCostFire:    20
staminaCostStomp:   30
staminaCostFly:     25
staminaCostInferno: 50

# Animation State
spear_attack_active:     0
spearX:                  0
fireball_attack_active:  0
fireballX:               0
dragonPreparingInferno:  0

# Items
estusFlaskCount:  2      # Charges of Estus Flask
estusFlaskActive: 0      # Current status of regeneration
estusFlaskCounter: 0     # Rounds remaining

# Interest
interestRate:   10     # 10% compound interest
baseDamage:     100    # Base amount added per compound interest
```

## Important Implementation Details

1. **Compound Interest**: Applied when player's attacks hit (damage > 0), formula: `debt = debt + (debt × 0.10) + 100`
2. **Dragon Payment**: When dragon hits, debt is reduced by 5%: `debt = debt - (debt × 0.05)`
3. **Stamina System**: All abilities have stamina costs; actions fail with message if insufficient stamina
4. **Shield Mechanic**: Absorbs damage, blocks offensive actions while active
5. **Sword Ability**: No HP damage but guarantees compound interest and stuns dragon
6. **Flank Ability**: High-risk high-reward with 40% critical chance and increased damage
7. **Spear Ability**: Defensive option with reduced damage but grants evasion buff, includes animation
8. **Estus Flask**: Consumable healing item with progressive restoration over 3 rounds
9. **Quiz Ability**: 6 educational questions about computer architecture
   - Random selection from unanswered questions
   - 5x compound interest on correct answers
   - -5 HP penalty (with shield absorption) on wrong answers
   - Each question can only be answered correctly once
10. **Dragon Balance**: 35% hit rate compensated by high damage (25-40, crit 60)
11. **Inferno Attack**: Two-phase attack with preparation, 80% hit rate, 45-65 damage
12. **Evasion Mechanics**: Both player (Spear) and dragon (Fly) can activate evasion buffs
13. **Stun Mechanics**: Both combatants can be stunned, causing them to skip their turn entirely
14. **Pixel Addressing**: `Base + (y * 256 + x) * 4` using bit shifts for efficiency
15. **HP Bars Scaling**: Player (÷2), Dragon (÷20) to fit 50 pixel max width
16. **Debt Victory**: Primary victory strategy is reaching 10,000 debt through compound interest
17. **No Player Debt Defeat**: Only victory conditions exist for debt counter (removed player defeat by debt)
18. **Animation System**: Spear and fireball projectiles with trail erasure for smooth animation
19. **Defense Stance**: Dragon enters defense when out of stamina, displays special sprite

## Sprite Assets (sprites/ directory)
- `warrior.png` - Base warrior sprite
- `warrior_defeated.png` - Fallen warrior
- `warrior_spear.png` - Warrior with spear throw pose
- `sprite_warrior_shield.png` - Warrior with shield
- `dragon.png` - Base dragon sprite
- `dragon_defeated.png` - Fallen dragon
- `dragon_fireball.png` - Dragon breathing fire (inferno pose)
- `dragon_defense.png` - Dragon in defense stance
- `sprite_dragon_preparing_inferno.png` - Dragon gathering fire
- `fireball.png` - Fireball projectile
- `spear.png` - Spear projectile
- `converter_sprites.py` - Python script to convert PNG to MIPS assembly

## Language
All code, comments, and messages are in English. Quiz questions are in Portuguese.

## Development Notes
- Original code was in Portuguese and was fully translated to English
- Monster HP set to 1000 to balance high damage output
- HP bars use different scaling: Player (÷2), Dragon (÷20)
- Dragon has four distinct attack patterns for variety plus defense fallback
- **Major Update**: Replaced dual debt system with unified compound interest debt counter
- **Major Update**: Added 7-action player combat system with distinct abilities
- **Major Update**: Introduced bidirectional stun mechanics (both player and dragon can be stunned)
- **Major Update**: Added player evasion mechanic through Spear ability
- **Major Update**: Implemented stamina system for both player and dragon
- **Major Update**: Added shield damage absorption system
- **Major Update**: Implemented animation system for spear and fireball projectiles
- **Major Update**: Added dragon defense stance with dedicated sprite
- **Major Update**: Added inferno preparation phase (two-turn attack)
- **Strategic Depth**: Multiple viable strategies (aggressive compound interest growth vs. defensive play)
- **Balance**: Dragon reduces debt on hit to prevent runaway compound interest growth
