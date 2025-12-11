# Warrior vs Dragon - MIPS Assembly Game

## Project Overview
A turn-based battle game written in MIPS Assembly featuring a warrior fighting against a dragon. The game includes graphical rendering on a 256x256 display and implements a unique **Compound Interest Debt** mechanic alongside traditional HP-based combat.

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
The player can choose from 5 different actions each turn:

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

4. **Lance Ability**
   - Defensive stance
   - Hit Chance: 80% (same as normal)
   - Critical Chance: 15% (if random ≥ 85)
   - Normal Damage: 5-9 - **LOWER than normal**
   - Critical Damage: 15
   - **Increases player evasion** (persists for next dragon turn)
   - Applies compound interest on hit
   - Special: If dragon is flying, hit chance reduced to 50%

5. **Quiz Ability (AOC Quiz - Placeholder)**
   - No direct HP damage
   - Applies compound interest directly to debt counter
   - Shows updated debt counter value
   - Resets player evasion and dragon flying status

#### Dragon Attacks
The dragon randomly chooses one of three attacks (33% each):

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
   - No damage or debt effect
   - Stun resets after skipped turn

3. **Fly**
   - Increases dragon evasion
   - Reduces player hit chance to 50% next turn
   - Reduces player critical chance to 10% next turn
   - No damage or debt effect
   - Effect resets after player's next attack

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
- Activated by Lance ability
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
[PLAYER] Choose action: (1) Attack, (2) Sword, (3) Flank, (4) Lance, (5) Quiz - 
```

## File Structure
```
warrior_vs_dragon_assembly/
├── main.asm           # Main game logic and rendering
├── sprites.asm        # Sprite data for warrior and dragon
├── sprites/
│   └── converter_sprites.py  # Sprite conversion utility
└── PROJECT_CONTEXT.md # This file
```

## Key Functions

### Battle Logic
- `game_loop`: Main game loop with HP and debt victory checks
- `player_turn`: Checks stun status then shows action menu
- `player_normal_attack`: Standard attack with compound interest
- `player_sword_attack`: Stuns dragon, applies compound interest
- `player_flank_attack`: High critical chance attack
- `player_lance_attack`: Defensive attack with evasion buff
- `player_quiz_attack`: AOC Quiz placeholder, applies compound interest
- `monster_turn`: Checks dragon stun, then dragon AI attack selection
- `calculate_attack_damage`: Player normal attack with evasion check
- `calculate_flank_damage`: Flank attack damage calculation
- `calculate_lance_damage`: Lance attack damage calculation
- `calculate_dragon_damage`: Dragon fire breath with player evasion check

### Compound Interest System
- `apply_compound_interest`: Applies 10% interest + 100 base to debt counter
- `apply_compound_interest_direct`: Custom interest calculation with parameters
- `apply_dragon_payment`: Reduces debt by 5% when dragon hits

### Graphics Engine
- `render_all`: Main rendering function
- `draw_sprite_pro`: Renders sprites with transparency
- `func_draw_rect`: Draws filled rectangles
- `draw_rectangle`: Macro for rectangle rendering

### Status Management
- `show_status`: Displays HP and debt in terminal

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
playerEvasion:  0      # 0=Normal, 1=Evasion (from Lance)
interestRate:   10     # 10% compound interest
baseDamage:     100    # Base amount added per compound interest
```

## Important Implementation Details

1. **Compound Interest**: Applied when player's attacks hit (damage > 0), formula: `debt = debt + (debt × 0.10) + 100`
2. **Dragon Payment**: When dragon hits, debt is reduced by 5%: `debt = debt - (debt × 0.05)`
3. **Player Actions**: 5 distinct abilities with different risk/reward profiles
4. **Sword Ability**: No HP damage but guarantees compound interest and stuns dragon
5. **Flank Ability**: High-risk high-reward with 40% critical chance and increased damage
6. **Lance Ability**: Defensive option with reduced damage but grants evasion buff
7. **Quiz Ability**: Placeholder for future AOC quiz integration, applies compound interest directly
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
