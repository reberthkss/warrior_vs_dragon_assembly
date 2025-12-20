# Warrior vs Dragon - MIPS Assembly Game

## Project Overview
A turn-based battle game written in MIPS Assembly featuring a warrior fighting against a dragon. The game includes graphical rendering on a 256x256 display and implements a unique **Compound Interest Debt** mechanic alongside traditional HP-based combat.

## Project Structure (Modular Architecture)

The project has been refactored into a modular structure for better organization and maintainability:

### File Organization
- **main.asm** - Main game loop, entry point, and turn handler (143 lines)
- **data.asm** - Game variables, constants, and text messages (139 lines)
- **battle.asm** - Player/dragon attack functions and damage calculations (694 lines)
- **quiz.asm** - Quiz system with question handling and validation (473 lines)
- **rendering.asm** - Graphics rendering engine, sprites, and HP bars (315 lines)
- **sprites.asm** - Sprite data for player and dragon (unchanged)
- **sprites/converter_sprites.py** - Python utility to convert images to MIPS sprites

### Module Responsibilities

**main.asm**: Core game flow
- Entry point and initialization
- Main game loop with victory/defeat checks
- Player turn handler and action menu
- Game over handlers

**data.asm**: Data definitions
- Display configuration and color constants
- Game state variables (HP, debt, turn, status effects)
- Quiz questions and answers (6 questions in Portuguese)
- All game messages and UI text

**battle.asm**: Combat mechanics
- Player attacks: Normal, Sword, Flank, Lance
- Dragon attacks: Fire Breath, Stomp, Fly
- Damage calculation functions
- Compound interest system (apply, payment)

**quiz.asm**: Educational quiz feature
- Quiz ability implementation with 6 questions
- Random question selection from unanswered pool
- Answer validation
- Completion tracking (per-question flags)

**rendering.asm**: Visual presentation
- Screen rendering (sky, ground, sprites)
- HP bar drawing with scaling
- Turn cursor indicator
- Battle status display

## Technical Specifications

### Display Configuration
- **Resolution**: 256x256 pixels
- **Display Address**: `0x10040000`
- **Unit Width**: 1 (256 columns per row)
- **Color Format**: 32-bit RGBA

### Game Mechanics

#### Core Systems
1. **HP System**
   - Player: 100 HP
   - Dragon: 1000 HP
   - Defeat when Player HP ≤ 0
   - Victory when Dragon HP ≤ 0

2. **Compound Interest Debt System**
   - Unified Debt Counter: Starts at 0
   - Debt Limit: 10,000
   - **Victory Condition**: Debt Counter ≥ 10,000
   - **Compound Interest Formula**: `newDebt = currentDebt + (currentDebt × 10%) + 100`
   - Player's successful attacks increase debt via compound interest
   - Dragon's successful attacks decrease debt by 5%

3. **Turn-Based Combat**
   - Player chooses action first (turn = 0)
   - Dragon attacks second (turn = 1)
   - **Input**: Number (1-5) to select action

#### Player Actions
The player can choose from 6 different actions each turn:

1. **Normal Attack**
   - Hit Chance: 80% (miss if random < 20)
   - Critical Chance: 15% (if random ≥ 85)
   - Normal Damage: 10-19
   - Critical Damage: 25
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50% and critical to 10%

2. **Sword Ability**
   - Stuns the dragon (dragon loses next turn)
   - No direct HP damage
   - Applies compound interest to debt counter
   - Resets dragon flying status and player evasion

3. **Flank Ability**
   - Hit Chance: 80% (same as normal)
   - Critical Chance: 40% (if random ≥ 60) - **HIGHER than normal**
   - Normal Damage: 15-24 - **HIGHER than normal**
   - Critical Damage: 30
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50%

4. **Spear Ability**
   - Defensive stance
   - Hit Chance: 80% (same as normal)
   - Critical Chance: 15% (if random ≥ 85)
   - Normal Damage: 5-9 - **LOWER than normal**
   - Critical Damage: 15
   - **Increases player evasion** (persists for next dragon turn)
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50%

5. **Quiz Ability (Computer Architecture Quiz)**
   - **6 Educational Questions** in Portuguese about computer architecture and hardware
   - **Random Selection**: Questions are randomly selected from unanswered pool
   - Questions can only be answered correctly once each
   - Displays remaining questions counter
   - **Correct Answer**: 5x compound interest applied (massive boost!)
   - **Wrong Answer**: -5 HP penalty + 1x compound interest
   - **Completion Tracking**: Each question marked as completed when answered correctly
   - **Quiz Questions**:
     1. Which CPU component performs mathematical and logical operations? (Answer: ULA/ALU)
     2. Which memory type is volatile and loses data when powered off? (Answer: RAM)
     3. In Von Neumann model, which bus transports memory addresses? (Answer: Address Bus)
     4. What is the smallest unit of information a computer can process? (Answer: Bit)
     5. Which component is exclusively an input device? (Answer: Teclado/Keyboard)
     6. What unit measures processor clock speed frequency? (Answer: Gigahertz/GHz)
   - Shows "Questoes restantes: X" before each quiz
6. **Estus Flask (Heal)**
   - **Limited Resource**: 2 charges total
   - **Immediate Heal**: Restores 25 HP
   - **Regeneration**: Restores 25 HP per round for 2 additional rounds
   - Consumes player turn
   - Cannot be used if another Estus effect is already active

#### Dragon Attacks
The dragon randomly chooses one of four attacks (25% each):

1. **Fire Breath**
   - Hit Chance: 30% (miss if random ≥ 30)
   - Critical Chance: 5% (if random ≥ 25 and < 30)
   - Normal Damage: 20-35
   - Critical Damage: 50
   - Reduces debt counter by 5% on hit
   - Special: If player has evasion (from Lance), dragon needs 50+ to hit (50% hit chance)

2. **Stomp**
   - Stuns the player
   - Player loses next turn
   - Reduces debt counter by 5%
   - Stun resets after skipped turn

3. **Fly**
   - Increases dragon evasion
   - Reduces player hit chance to 50% next turn
   - Reduces player critical chance to 10% next turn
   - No damage or debt effect
   - Effect resets after player's next attack

4. **Inferno**
   - Devastating fire attack
   - **High Hit Chance**: 80% (ignores most evasion)
   - **Massive Damage**: 45-65 HP
   - Reduces debt counter by 5% on hit

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
- Reduces dragon's hit chance from 30% to 50% miss rate
- Persists for the next dragon turn
- Resets after dragon attacks or player uses another ability

**Dragon Flying** (`dragonFlying`)
- Activated by Fly attack
- Reduces player's hit chance to 50%
- Reduces player's critical chance to 10%
- Resets after player's next attack

### Graphics System

#### Color Palette
- Ground: `0x228B22` (Grass Green)
- Sky: `0x87CEEB` (Sky Blue)
- HP Bar: `0x00FF00` (Life Green)
- Cursor: `0xFFFF00` (Yellow)

#### Rendering
- Sky: Y 0-199
- Ground: Y 200-255
- Warrior Sprite: X=50, Y=185
- Dragon Sprite: X=180, Y=185
- Player HP Bar: X=50, Y=175, Height=4, Width=(HP/2) pixels max 50
- Dragon HP Bar: X=180, Y=175, Height=4, Width=(HP/20) pixels max 50
- Turn Cursor: Near active character

#### Sprite System
- Sprites stored with header: [Width, Height, Pixel Data]
- Transparent pixels: Color value 0x00000000
- Sprites imported from `sprites.asm`

### Game States

#### Victory Conditions
- Dragon HP ≤ 0: "VICTORY! - Dragon Defeated!"
- Debt Counter ≥ 10,000: "VICTORY BY COMPOUND INTEREST! Debt reached 10,000!"

#### Defeat Conditions
- Player HP ≤ 0: "DEFEAT..."

### Status Display (Terminal Output)
```
--- BATTLE STATUS ---
Player - HP: [value]
Dragon - HP: [value]
[DEBT COUNTER: [value] / 10,000]
```

### Action Menu
```
[PLAYER] Choose: (1)Attack (2)Sword (3)Flank (4)Spear (5)Quiz (6)Estus - 
```

## Key Functions by Module

### Main Game Loop (main.asm)
- `main`: Entry point, displays welcome messages
- `game_loop`: Main game loop with HP and debt victory checks
- `player_turn`: Checks stun status then shows action menu
- `player_can_act`: Displays action menu and handles player input
- `game_over_win`: Victory by dragon defeat
- `game_over_lose`: Defeat by player death
- `game_over_win_debt`: Victory by reaching 10,000 debt
- `exit`: Program termination

### Battle System (battle.asm)
- `player_normal_attack`: Standard attack with compound interest
- `player_sword_attack`: Stuns dragon, applies compound interest
- `player_flank_attack`: High critical chance attack
- `player_spear_attack`: Defensive attack with evasion buff
- `player_use_estus`: Consumable healing item (immediate + regen)
- `apply_estus_regen`: Handles round-by-round regeneration
- `monster_turn`: Checks dragon stun, then dragon AI attack selection
- `dragon_can_act`: Dragon attack AI (Fire Breath, Stomp, Fly, or Inferno)
- `dragon_stomp`: Stuns player and reduces debt by 5%
- `dragon_fly`: Increases dragon evasion for next turn
- `dragon_inferno`: High damage fire attack, reduces debt by 5%
- `calculate_attack_damage`: Player normal attack with evasion check
- `calculate_flank_damage`: Flank attack damage calculation
- `calculate_spear_damage`: Spear attack damage calculation
- `calculate_dragon_damage`: Dragon fire breath with player evasion check
- `apply_compound_interest`: Applies 10% interest + 100 base to debt counter
- `apply_compound_interest_direct`: Custom interest calculation with parameters
- `apply_dragon_payment`: Reduces debt by 5% when dragon hits or stomps

### Quiz System (quiz.asm)
- `player_quiz_attack`: Educational quiz with 6 questions, completion tracking
- `quiz_all_completed`: Handler when all questions answered
- `show_quiz_1`, `show_quiz_2`, `show_quiz_3`, `show_quiz_4`, `show_quiz_5`, `show_quiz_6`: Display individual quiz questions
- `check_quiz_answer`: Validates answer and marks question as completed on success
- `apply_correct_bonus`: Applies 5x compound interest for correct answer
- `quiz_wrong`: Applies -5 HP penalty and 1x compound interest
- `quiz_finish`: Updates debt display and switches turn
- `find_next_quiz`: Randomly selects an unanswered question from available pool
- `count_remaining_questions`: Counts how many questions are still available

### Graphics Engine (rendering.asm)
- `render_all`: Main rendering function (sky, ground, sprites, HP bars, cursor)
- `draw_sprite_pro`: Renders sprites with transparency support
- `func_draw_rect`: Draws filled rectangles
- `show_status`: Displays HP and debt counter in terminal

## Game Variables
```assembly
playerHP:       100
monsterHP:      1000
debtCounter:    0      # Unified compound interest debt counter
debtLimit:      10000  # Victory threshold
turn:           0      # 0=Player, 1=Monster
playerStunned:  0      # 0=Normal, 1=Stunned (from Stomp)
dragonStunned:  0      # 0=Normal, 1=Stunned (from Sword)
dragonFlying:   0      # 0=Ground, 1=Flying (evasion buff)
playerEvasion:  0      # 0=Normal, 1=Evasion (from Spear)
estusFlaskCount: 2     # Charges of Estus Flask
estusFlaskActive: 0    # Current status of regeneration
interestRate:   10     # 10% compound interest
baseDamage:     100    # Base amount added per compound interest
```

## Important Implementation Details

1. **Compound Interest**: Applied when player's attacks hit (damage > 0), formula: `debt = debt + (debt × 0.10) + 100`
2. **Dragon Payment**: When dragon hits, debt is reduced by 5%: `debt = debt - (debt × 0.05)`
3. **Player Actions**: 5 distinct abilities with different risk/reward profiles
4. **Sword Ability**: No HP damage but guarantees compound interest and stuns dragon
5. **Flank Ability**: High-risk high-reward with 40% critical chance and increased damage
6. **Spear Ability**: Defensive option with reduced damage but grants evasion buff
7. **Estus Flask**: Consumable healing item with progressive restoration over 3 rounds
8. **Quiz Ability**: 6 educational questions about computer architecture and hardware
   - Random selection from unanswered questions
   - 5x compound interest on correct answers
   - -5 HP penalty on wrong answers
   - Each question can only be answered correctly once
8. **Dragon Balance**: Low hit rate (30%) compensated by very high damage (20-35)
9. **Evasion Mechanics**: Both player (Lance) and dragon (Fly) can activate evasion buffs
10. **Stun Mechanics**: Both combatants can be stunned, causing them to skip their turn entirely
11. **Pixel Addressing**: `Base + (y * 256 + x) * 4` using bit shifts for efficiency
12. **HP Bars Scaling**: Player (÷2), Dragon (÷20) to fit 50 pixel max width
13. **Debt Victory**: Primary victory strategy is reaching 10,000 debt through compound interest
14. **No Player Debt Defeat**: Only victory conditions exist for debt counter (removed player defeat by debt)

## Language
All code, comments, and messages are in English.

## Development Notes
- Original code was in Portuguese and was fully translated to English
- Monster HP set to 1000 to balance high damage output
- HP bars use different scaling: Player (÷2), Dragon (÷20)
- Dragon has three distinct attack patterns for variety
- **Major Update**: Replaced dual debt system with unified compound interest debt counter
- **Major Update**: Added 5-action player combat system with distinct abilities
- **Major Update**: Introduced bidirectional stun mechanics (both player and dragon can be stunned)
- **Major Update**: Added player evasion mechanic through Lance ability
- **Strategic Depth**: Multiple viable strategies (aggressive compound interest growth vs. defensive play)
- **Balance**: Dragon reduces debt on hit to prevent runaway compound interest growth
