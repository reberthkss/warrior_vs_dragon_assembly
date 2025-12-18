# ============================================
# RENDERING.ASM - Graphics & Display Functions
# ============================================
# This file contains all rendering functions including
# sprite drawing, rectangles, HP bars, and screen updates.

.text

# ----------------------------------------------------------------
# MAIN RENDERING FUNCTION
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

    # 4. Health Bars
    # Player Bar (100 HP max = 50 pixels max)
    lw $t0, playerHP
    blez $t0, skip_hp_player
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
    blez $t0, skip_hp_monster
    div $t0, $t0, 20    # Scale (1000 HP = 50 pixels)
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
    lw $a0, debtCounter
    syscall
    li $v0, 4
    la $a0, msg_estus_count
    syscall
    li $v0, 1
    lw $a0, estusFlaskCount
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
    la $a0, newline
    syscall
    
    # Debt Counter (Unified)
    li $v0, 4
    la $a0, msg_monster_debt
    syscall
    li $v0, 1
    lw $a0, debtCounter
    syscall
    li $v0, 4
    la $a0, msg_debt_limit
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    # Estus Flask Effect Status
    lw $t0, estusFlaskActive
    beqz $t0, skip_estus_status
    li $v0, 4
    la $a0, msg_estus_active
    syscall
    li $v0, 1
    lw $a0, estusFlaskCounter
    syscall
    li $v0, 4
    la $a0, msg_rounds_left
    syscall
    skip_estus_status:
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
