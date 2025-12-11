.data
    # --- IMPORTING SPRITES (Assets) ---
    .include "sprites.asm"

    # --- ADDRESSES ---
    displayAddress: .word 0x10040000

    # --- GENERAL COLORS ---
    COLOR_GROUND:   .word 0x228B22    # Grass Green
    COLOR_SKY:      .word 0x87CEEB    # Sky Blue
    COLOR_HP_FULL:  .word 0x00FF00    # Life Green
    COLOR_HP_DMG:   .word 0xFF0000    # Damage Red
    COLOR_CURSOR:   .word 0xFFFF00    # Yellow

    # --- GAME VARIABLES ---
    playerHP:       .word 100
    monsterHP:      .word 1000
    playerDebt:     .word 0           # Player Debt
    monsterDebt:    .word 0           # Monster Debt
    debtLimit:      .word 5000        # Debt Limit
    turn:           .word 0           # 0 = Player, 1 = Monster

    # --- MESSAGES ---
    msg_start:      .asciiz "\n--- FULL HD BATTLE (Unit 1) ---\n"
    msg_player_atk: .asciiz "\n[PLAYER] You attacked! "
    msg_monster_atk:.asciiz "\n[DRAGON] The monster breathed fire! "
    msg_damage:     .asciiz "Damage dealt: "
    msg_miss:       .asciiz "ATTACK MISSED!\n"
    msg_crit:       .asciiz "CRITICAL HIT!!! "
    msg_win:        .asciiz "\n*** VICTORY! ***\n"
    msg_lose:       .asciiz "\n*** DEFEAT... ***\n"
    msg_win_debt:   .asciiz "\n*** VICTORY BY DEBT! The dragon is in debt! ***\n"
    msg_lose_debt:  .asciiz "\n*** DEFEAT BY DEBT! You are too much in debt! ***\n"
    msg_status:     .asciiz "\n--- BATTLE STATUS ---\n"
    msg_player_hp:  .asciiz "Player - HP: "
    msg_player_debt:.asciiz " | Debt: "
    msg_monster_hp: .asciiz "Dragon - HP: "
    msg_monster_debt:.asciiz " | Debt: "
    newline:        .asciiz "\n"

# --- MACROS ---
.macro draw_rectangle(%x, %y, %w, %h, %color_label)
    li $a0, %x
    li $a1, %y
    li $a2, %w
    li $v1, %h
    lw $a3, %color_label
    jal func_draw_rect
.end_macro

.text
.globl main

main:
    li $v0, 4
    la $a0, msg_start
    syscall

game_loop:
    # 1. Check Game Over
    # Check HP
    lw $t0, playerHP
    blez $t0, game_over_lose
    lw $t1, monsterHP
    blez $t1, game_over_win
    
    # Check Debt
    lw $t2, playerDebt
    lw $t3, debtLimit
    bge $t2, $t3, game_over_lose_debt
    lw $t2, monsterDebt
    bge $t2, $t3, game_over_win_debt

    # 2. Show Battle Status
    jal show_status

    # 3. Render (Now in Full Res)
    jal render_all

    # 4. Turn Logic
    lw $t0, turn
    beq $t0, 0, player_turn
    beq $t0, 1, monster_turn
    j game_loop

# ----------------------------------------------------------------
# BATTLE LOGIC
# ----------------------------------------------------------------
player_turn:
    li $v0, 12 
    syscall
    move $t0, $v0
    li $t1, 10
    bne $t0, $t1, player_turn

    li $v0, 4
    la $a0, msg_player_atk
    syscall

    jal calculate_attack_damage
    move $s0, $v0
    
    # Reduce Monster HP
    lw $t1, monsterHP
    sub $t1, $t1, $s0
    sw $t1, monsterHP
    
    # Increase Monster Debt by 500 (only if attack hit)
    blez $s0, skip_debt_player
    lw $t1, monsterDebt
    addi $t1, $t1, 500
    sw $t1, monsterDebt
    skip_debt_player:

    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

monster_turn:
    li $v0, 32
    li $a0, 1000
    syscall

    li $v0, 4
    la $a0, msg_monster_atk
    syscall

    jal calculate_dragon_damage
    move $s0, $v0

    # Reduce Player HP
    lw $t1, playerHP
    sub $t1, $t1, $s0
    sw $t1, playerHP
    
    # Increase Player Debt by 500 (only if attack hit)
    blez $s0, skip_debt_monster
    lw $t1, playerDebt
    addi $t1, $t1, 500
    sw $t1, playerDebt
    skip_debt_monster:

    li $t0, 0
    sw $t0, turn
    j game_loop

calculate_attack_damage:ge:
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    blt $t0, 20, attack_missed
    bge $t0, 85, critical_hit

    li $v0, 42
    li $a0, 0
    li $a1, 10
    syscall
    addi $v0, $a0, 10
    j print_damage

critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 25
    j print_damage

attack_missed:
    li $v0, 4
    la $a0, msg_miss
    syscall
    li $v0, 0
    jr $ra

print_damage:
    move $t9, $v0
    li $v0, 4
    la $a0, msg_damage
    syscall
    li $v0, 1
    move $a0, $t9
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    move $v0, $t9
    jr $ra

calculate_dragon_damage:
    # Dragon has only 30% chance to hit (0-29 hits, 30-99 misses)
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    bge $t0, 30, attack_missed  # 70% chance to miss
    bge $t0, 25, dragon_critical_hit  # 5% chance of critical

    # Normal attack
    li $v0, 42
    li $a0, 0
    li $a1, 10
    syscall
    addi $v0, $a0, 10
    j print_damage

dragon_critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 25
    j print_damage

# ----------------------------------------------------------------
# UPDATED GRAPHICS ENGINE (Resolution 256x256)
# ----------------------------------------------------------------
render_all:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # 1. Clear Screen
    # Sky: occupies top to line 200 (of 256)
    draw_rectangle(0, 0, 256, 200, COLOR_SKY)
    # Ground: line 200 to 256
    draw_rectangle(0, 200, 256, 56, COLOR_GROUND)

    # 2. Draw Warrior
    # Positioned on ground (Y=190 approx)
    li $a0, 50             # X
    li $a1, 185            # Y
    la $a2, sprite_player
    jal draw_sprite_pro

    # 3. Draw Dragon
    # Positioned on ground right side
    li $a0, 180            # X
    li $a1, 185            # Y
    la $a2, sprite_dragon
    jal draw_sprite_pro

    # 4. Health Bars (Increased for new resolution)
    # Player Bar
    lw $t0, playerHP
    div $t0, $t0, 2     # Scale (100 HP = 50 pixels)
    mflo $a2
    blez $a2, skip_hp_player
    li $a0, 50
    li $a1, 175
    li $v1, 4           # Height 4 pixels
    lw $a3, COLOR_HP_FULL
    jal func_draw_rect
    skip_hp_player:

    # Dragon Bar
    lw $t0, monsterHP
    div $t0, $t0, 2
    mflo $a2
    blez $a2, skip_hp_monster
    li $a0, 180
    li $a1, 175
    li $v1, 4
    lw $a3, COLOR_HP_FULL
    jal func_draw_rect
    skip_hp_monster:

    # 5. Cursor
    lw $t0, turn
    beq $t0, 1, cursor_dragon
    draw_rectangle(60, 160, 10, 5, COLOR_CURSOR) # Near player
    j end_render
    cursor_dragon:
    draw_rectangle(190, 160, 10, 5, COLOR_CURSOR) # Near dragon

end_render:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# FUNCTION: DRAW SPRITE PRO (Unit Width 1 -> 256 columns)
# ----------------------------------------------------------------
draw_sprite_pro:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t3, 0($a2)       # Width
    lw $t4, 4($a2)       # Height
    addi $a2, $a2, 8     # Skip header

    move $t0, $a0        # X
    move $t1, $a1        # Y
    move $t8, $t3        # Save width

loop_pro_y:
    blez $t4, end_sprite_pro
    move $t0, $a0        # Reset X
    move $t3, $t8        # Reset width counter

    loop_pro_x:
        blez $t3, next_line_pro
        
        lw $t5, 0($a2)   # Color
        addi $a2, $a2, 4
        
        beqz $t5, skip_pixel_pro

        # --- FULL HD CORRECTION (Width 256) ---
        # Formula: Base + (y * 256 + x) * 4
        # Tip: Multiply by 256 equals Shift Left 8 (2^8 = 256)
        
        sll $t6, $t1, 8      # y * 256
        add $t6, $t6, $t0    # + x
        sll $t6, $t6, 2      # * 4
        li $t7, 0x10040000   # Base
        add $t6, $t6, $t7
        
        sw $t5, 0($t6)

    skip_pixel_pro:
        addi $t0, $t0, 1
        addi $t3, $t3, -1
        j loop_pro_x

next_line_pro:
    addi $t1, $t1, 1
    addi $t4, $t4, -1
    j loop_pro_y

end_sprite_pro:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# FUNCTION: RECTANGLE (Unit Width 1 -> 256 columns)
# ----------------------------------------------------------------
func_draw_rect:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
    move $t3, $v1
    move $t4, $a3

    loop_y_rect:
        blez $t3, end_draw_rect
        move $t0, $a0
        move $t2, $a2
        
        loop_x_rect:
            blez $t2, next_line_rect
            
            # --- FULL HD CORRECTION (Width 256) ---
            sll $t5, $t1, 8     # y * 256
            add $t5, $t5, $t0   # + x
            sll $t5, $t5, 2     # * 4
            li $t6, 0x10040000
            add $t5, $t5, $t6
            
            sw $t4, 0($t5)
            
            addi $t0, $t0, 1
            addi $t2, $t2, -1
            j loop_x_rect
            
        next_line_rect:
        addi $t1, $t1, 1
        addi $t3, $t3, -1
        j loop_y_rect

    end_draw_rect:
    jr $ra

# ----------------------------------------------------------------
# FUNCTION: SHOW BATTLE STATUS
# ----------------------------------------------------------------
show_status:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Title
    li $v0, 4
    la $a0, msg_status
    syscall
    
    # Player Status
    li $v0, 4
    la $a0, msg_player_hp
    syscall
    li $v0, 1
    lw $a0, playerHP
    syscall
    li $v0, 4
    la $a0, msg_player_debt
    syscall
    li $v0, 1
    lw $a0, playerDebt
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    # Dragon Status
    li $v0, 4
    la $a0, msg_monster_hp
    syscall
    li $v0, 1
    lw $a0, monsterHP
    syscall
    li $v0, 4
    la $a0, msg_monster_debt
    syscall
    li $v0, 1
    lw $a0, monsterDebt
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# FINS DE JOGO
# ----------------------------------------------------------------
game_over_win:
    li $v0, 4
    la $a0, msg_win
    syscall
    j exit

game_over_lose:
    li $v0, 4
    la $a0, msg_lose
    syscall
    j exit

game_over_win_debt:
    li $v0, 4
    la $a0, msg_win_debt
    syscall
    j exit

game_over_lose_debt:
    li $v0, 4
    la $a0, msg_lose_debt
    syscall
    j exit

exit:
    li $v0, 10
    syscall