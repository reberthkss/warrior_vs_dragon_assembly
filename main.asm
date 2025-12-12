# ============================================
# MAIN.ASM - Warrior vs Dragon Battle Game
# ============================================

# --- INCLUDE DATA & SPRITES ---
.include "data.asm"
.include "sprites.asm"

# --- MACROS ---
.macro draw_rectangle(%x, %y, %w, %h, %color_label)
    li $a0, %x
    li $a1, %y
    li $a2, %w
    li $v1, %h
    lw $a3, %color_label
    jal func_draw_rect
.end_macro

# ----------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------
.text
.globl main

main:
    li $v0, 4
    la $a0, msg_start
    syscall
    li $v0, 4
    la $a0, msg_start_info
    syscall
    
    # Initial pause to let player read
    li $v0, 32
    li $a0, 1000
    syscall

game_loop:
    # 1. Check Game Over
    # Check HP
    lw $t0, playerHP
    blez $t0, game_over_lose
    lw $t1, monsterHP
    blez $t1, game_over_win
    
    # Check Debt Counter (Compound Interest Victory)
    lw $t2, debtCounter
    lw $t3, debtLimit
    bge $t2, $t3, game_over_win_debt

    # 2. Show Battle Status
    jal show_status

    # 3. Render
    jal render_all

    # 4. Turn Logic
    lw $t0, turn
    beq $t0, 0, player_turn
    beq $t0, 1, monster_turn
    j game_loop

# ----------------------------------------------------------------
# PLAYER TURN
# ----------------------------------------------------------------
player_turn:
    # Check if player is stunned
    lw $t0, playerStunned
    beqz $t0, player_can_act
    
    # Player is stunned, skip turn
    li $v0, 4
    la $a0, msg_stunned
    syscall
    
    # Reset stun status
    sw $zero, playerStunned
    
    # Change to monster turn
    li $t0, 1
    sw $t0, turn

    # wait 1 sec
    li $v0, 32
    li $a0, 1000
    syscall
    j game_loop
    
player_can_act:
    # Show action menu
    li $v0, 4
    la $a0, msg_choose_action
    syscall
    
    # Get player input
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Check which action (1=Attack, 2=Sword, 3=Flank, 4=Lance, 5=Quiz)
    li $t1, 1
    beq $t0, $t1, player_normal_attack
    li $t1, 2
    beq $t0, $t1, player_sword_attack
    li $t1, 3
    beq $t0, $t1, player_flank_attack
    li $t1, 4
    beq $t0, $t1, player_lance_attack
    li $t1, 5
    beq $t0, $t1, player_quiz_attack
    j player_can_act  # Invalid input, ask again

# ----------------------------------------------------------------
# GAME OVER
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

exit:
    li $v0, 10
    syscall

# --- INCLUDE GAME MODULES (after main) ---
.include "battle.asm"
.include "quiz.asm"
.include "rendering.asm"
