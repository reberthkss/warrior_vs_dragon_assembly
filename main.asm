# ============================================
# MAIN.ASM - Warrior vs Dragon Battle Game
# ============================================

# --- INCLUDE ALL MODULES (centralized) ---
.include "include_all.asm"

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
    # 1. Apply Estus Flask regeneration if active
    jal apply_estus_regen
    
    # 2. Check Game Over
    # Check HP
    lw $t0, playerHP
    blez $t0, game_over_lose
    lw $t1, monsterHP
    blez $t1, game_over_win
    
    # Check Debt Counter (Compound Interest Victory)
    lw $t2, debtCounter
    lw $t3, debtLimit
    bge $t2, $t3, game_over_win_debt

    # 3. Show Battle Status
    jal show_status

    # 4. Render
    jal render_all

    # 5. Turn Logic
    lw $t0, turn
    beq $t0, 0, player_turn
    beq $t0, 1, monster_turn
    j game_loop

# ----------------------------------------------------------------
# PLAYER TURN
# ----------------------------------------------------------------
player_turn:
    # Increment turn counter at start of player's turn (new round)
    lw $t0, turnCounter
    addi $t0, $t0, 1
    sw $t0, turnCounter
    
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
    
    # Check which action (1=Shield, 2=Sword, 3=Flank, 4=Spear, 5=Quiz, 6=Estus Flask)
    li $t1, 1
    beq $t0, $t1, player_prepare_shield
    
    # --- SHIELD RESTRICTIONS FOR OFFENSIVE ACTIONS ---
    lw $t2, warriorShield
    beqz $t2, not_shielded
    
    # Check if choice is offensive or restricted (2, 3, 4, or 5)
    li $t1, 2
    beq $t0, $t1, shield_error
    li $t1, 3
    beq $t0, $t1, shield_error
    li $t1, 4
    beq $t0, $t1, shield_error
    li $t1, 5
    beq $t0, $t1, shield_error
    j not_shielded

shield_error:
    li $v0, 4
    la $a0, msg_shield_error
    syscall
    j player_can_act

not_shielded:
    li $t1, 2
    beq $t0, $t1, player_sword_attack
    li $t1, 3
    beq $t0, $t1, player_flank_attack
    li $t1, 4
    beq $t0, $t1, player_lance_attack
    li $t1, 5
    beq $t0, $t1, player_quiz_attack
    li $t1, 6
    beq $t0, $t1, player_use_estus
    j player_can_act  # Invalid input, ask again

# ----------------------------------------------------------------
# GAME OVER
# ----------------------------------------------------------------
game_over_win:
    # Final render to show dragon defeated
    jal render_all
    
    li $v0, 4
    la $a0, msg_win
    syscall
    j exit

game_over_lose:
    # Final render to show defeated state
    jal render_all
    
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

