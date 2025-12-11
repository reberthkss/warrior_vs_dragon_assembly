# Warrior vs Dragon - MIPS Assembly Game

## Project Overview
A turn-based battle game written in MIPS Assembly featuring a warrior fighting against a dragon. The game includes graphical rendering on a 256x256 display and implements a unique "Debt" mechanic alongside traditional HP-based combat.

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
   - Victory/Defeat when HP ≤ 0

2. **Debt System**
   - Player Debt: Starts at 0
   - Monster Debt: Starts at 0
   - Debt Limit: 5000
   - Debt increases by 500 on successful attacks
   - Victory/Defeat when debt ≥ 5000

3. **Turn-Based Combat**
   - Player attacks first (turn = 0)
   - Dragon attacks second (turn = 1)
   - Input: Press Enter (ASCII 10) to attack

#### Player Attacks
- **Hit Chance**: 80% (miss if random < 20)
- **Critical Chance**: 15% (if random ≥ 85)
- **Normal Damage**: 10-19
- **Critical Damage**: 25
- **Special**: If dragon is flying, hit chance reduced to 50% and critical to 10%

#### Dragon Attacks
The dragon randomly chooses one of three attacks (33% each):

1. **Fire Breath**
   - Hit Chance: 30% (miss if random ≥ 30)
   - Critical Chance: 5% (if random ≥ 25 and < 30)
   - Normal Damage: 20-35
   - Critical Damage: 50
   - Increases player debt by 500 on hit

2. **Stomp**
   - Stuns the player
   - Player loses next turn
   - No damage or debt
   - Stun resets after skipped turn

3. **Fly**
   - Increases dragon evasion
   - Reduces player hit chance to 50% next turn
   - Reduces player critical chance to 10% next turn
   - No damage or debt
   - Effect resets after player's next attack

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
- Dragon HP ≤ 0: "VICTORY!"
- Dragon Debt ≥ 5000: "VICTORY BY DEBT! The dragon is in debt!"

#### Defeat Conditions
- Player HP ≤ 0: "DEFEAT..."
- Player Debt ≥ 5000: "DEFEAT BY DEBT! You are too much in debt!"

### Status Display (Terminal Output)
```
--- BATTLE STATUS ---
Player - HP: [value] | Debt: [value]
Dragon - HP: [value] | Debt: [value]
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
- `game_loop`: Main game loop with victory/debt checks
- `player_turn`: Handles player input and attack
- `monster_turn`: Dragon AI and attack selection
- `calculate_attack_damage`: Player attack with evasion check
- `calculate_dragon_damage`: Dragon fire breath attack

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
playerDebt:     0
monsterDebt:    0
debtLimit:      5000
turn:           0    # 0=Player, 1=Monster
playerStunned:  0    # 0=Normal, 1=Stunned
dragonFlying:   0    # 0=Ground, 1=Flying
```

## Important Implementation Details

1. **Debt Application**: Debt only increases when attacks deal damage (not on misses)
2. **Dragon Balance**: Low hit rate (30%) compensated by high damage (20-35)
3. **Pixel Addressing**: `Base + (y * 256 + x) * 4` using bit shifts for efficiency
4. **Stun Mechanic**: Player skips entire turn, dragon gets consecutive attacks
5. **Fly Mechanic**: Effect persists only for next player turn, then resets

## Language
All code, comments, and messages are in English.

## Development Notes
- Original code was in Portuguese and was fully translated
- Monster HP increased to 1000 to balance high damage output
- HP bars use different scaling: Player (÷2), Dragon (÷20)
- Dragon has three distinct attack patterns for variety
