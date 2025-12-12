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
    debtCounter:    .word 0           # Compound Debt Counter (0 to 10000)
    debtLimit:      .word 10000       # Victory Limit (Debt-based victory)
    turn:           .word 0           # 0 = Player, 1 = Monster
    playerStunned:  .word 0           # 0 = Not stunned, 1 = Stunned
    dragonFlying:   .word 0           # 0 = On ground, 1 = Flying (increased evasion)
    dragonStunned:  .word 0           # 0 = Not stunned, 1 = Stunned (Sword ability)
    playerEvasion:  .word 0           # 0 = Normal evasion, 1 = Increased evasion (Lance ability)
    
    # Compound Interest Rates
    interestRate:   .word 10          # 10% interest rate
    baseDamage:     .word 100         # Base damage to add to interest
    
    # Quiz System
    quizQuestionIndex: .word 0        # Current question index (0-2)
    quiz_q1_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q2_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q3_completed: .word 0        # 0 = Not completed, 1 = Completed
    quizAllCompleted:  .word 0        # 0 = Questions available, 1 = All completed
    
    # Quiz Questions (3 questions)
    quiz_q1:        .asciiz "\n[QUIZ] Qual componente da CPU e responsavel por realizar operacoes\nmatematicas (como adicao e subtracao) e logicas (como AND e OR)?\n"
    quiz_q1_opt1:   .asciiz "1) Unidade de Controle (UC)\n"
    quiz_q1_opt2:   .asciiz "2) Unidade Logica e Aritmetica (ULA/ALU)\n"
    quiz_q1_opt3:   .asciiz "3) Registradores\n"
    quiz_q1_opt4:   .asciiz "4) Memoria Cache\n"
    quiz_q1_answer: .word 2            # Correct answer is option 2
    
    quiz_q2:        .asciiz "\n[QUIZ] Qual tipo de memoria e conhecido por ser volatil, ou seja,\nperde todos os dados armazenados quando o computador e desligado?\n"
    quiz_q2_opt1:   .asciiz "1) Memoria ROM\n"
    quiz_q2_opt2:   .asciiz "2) Memoria RAM\n"
    quiz_q2_opt3:   .asciiz "3) Pen Drive\n"
    quiz_q2_opt4:   .asciiz "4) Disco Rigido (HD)\n"
    quiz_q2_answer: .word 2            # Correct answer is option 2
    
    quiz_q3:        .asciiz "\n[QUIZ] No modelo de Von Neumann, qual barramento e responsavel por\ntransportar o endereco de memoria onde a CPU deseja ler ou escrever um dado?\n"
    quiz_q3_opt1:   .asciiz "1) Barramento de Entrada/Saida\n"
    quiz_q3_opt2:   .asciiz "2) Barramento de Dados\n"
    quiz_q3_opt3:   .asciiz "3) Barramento de Controle\n"
    quiz_q3_opt4:   .asciiz "4) Barramento de Enderecos\n"
    quiz_q3_answer: .word 4            # Correct answer is option 4

    # --- MESSAGES ---
    msg_start:      .asciiz "\n--- FULL HD BATTLE (Unit 1) ---\n"
    msg_start_info: .asciiz "Victory Conditions: Defeat Dragon OR reach 10,000 Debt!\n"
    msg_player_atk: .asciiz "\n[PLAYER] You attacked! "
    msg_player_sword:.asciiz "\n[PLAYER] You used SWORD! The dragon is STUNNED!\n"
    msg_player_flank:.asciiz "\n[PLAYER] You used FLANK! "
    msg_player_lance:.asciiz "\n[PLAYER] You used LANCE! Your evasion is increased!\n"
    msg_player_quiz:.asciiz "\n--- AOC QUIZ TIME! ---\n"
    msg_quiz_remaining:.asciiz "Questions remaining: "
    msg_quiz_prompt:.asciiz "Your answer (1-4): "
    msg_quiz_correct:.asciiz "\n[CORRECT!] 5x compound interest applied!\n"
    msg_quiz_wrong: .asciiz "\n[WRONG!] -5 HP penalty!\n"
    msg_quiz_all_done:.asciiz "\n[QUIZ] All questions have been answered correctly! Quiz no longer available.\n"
    msg_debt_update:.asciiz "Debt Counter updated: "
    msg_monster_atk:.asciiz "\n[DRAGON] The monster breathed fire! "
    msg_stomp:      .asciiz "\n[DRAGON] The dragon stomped! You are STUNNED!\n"
    msg_fly:        .asciiz "\n[DRAGON] The dragon takes flight! Evasion increased!\n"
    msg_stunned:    .asciiz "[PLAYER] You are stunned and cannot attack this turn!\n"
    msg_dragon_stunned: .asciiz "[DRAGON] The dragon is stunned and cannot attack this turn!\n"
    msg_damage:     .asciiz "Damage dealt: "
    msg_miss:       .asciiz "ATTACK MISSED!\n"
    msg_crit:       .asciiz "CRITICAL HIT!!! "
    msg_choose_action: .asciiz "\n[PLAYER] Choose action: (1) Attack, (2) Sword, (3) Flank, (4) Lance, (5) Quiz - "
    msg_win:        .asciiz "\n*** VICTORY! - Dragon Defeated! ***\n"
    msg_lose:       .asciiz "\n*** DEFEAT... ***\n"
    msg_win_debt:   .asciiz "\n*** VICTORY BY COMPOUND INTEREST! Debt reached 10,000! ***\n"
    msg_lose_debt:  .asciiz "\n*** DEFEAT BY DEBT! You are too much in debt! ***\n"
    msg_status:     .asciiz "\n--- BATTLE STATUS ---\n"
    msg_player_hp:  .asciiz "Player - HP: "
    msg_player_debt:.asciiz " | Debt Counter: "
    msg_monster_hp: .asciiz "\nDragon - HP: "
    msg_monster_debt:.asciiz "\n[DEBT COUNTER: "
    msg_debt_limit: .asciiz " / 10,000]"
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
    li $v0, 4
    la $a0, msg_start_info
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

player_normal_attack:
    li $v0, 4
    la $a0, msg_player_atk
    syscall

    # Check if dragon is flying (increased evasion)
    lw $t0, dragonFlying
    move $a0, $t0
    jal calculate_attack_damage
    move $s0, $v0
    
    # Reset dragon flying status after attack
    sw $zero, dragonFlying
    # Reset player evasion after attack
    sw $zero, playerEvasion
    
    # Reduce Monster HP
    lw $t1, monsterHP
    sub $t1, $t1, $s0
    sw $t1, monsterHP
    
    # Apply Compound Interest on Debt Counter (only if attack hit)
    blez $s0, skip_debt_player
    jal apply_compound_interest
    skip_debt_player:

    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

player_sword_attack:
    # Sword ability - stuns the dragon (no damage)
    li $v0, 4
    la $a0, msg_player_sword
    syscall
    
    # Set dragon as stunned
    li $t0, 1
    sw $t0, dragonStunned
    
    # No HP damage for sword ability, but increases debt counter
    lw $t1, debtCounter
    lw $a0, interestRate
    lw $a1, baseDamage
    jal apply_compound_interest_direct
    move $t1, $v0
    sw $t1, debtCounter
    
    # Reset dragon flying status and player evasion
    sw $zero, dragonFlying
    sw $zero, playerEvasion
    
    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

player_flank_attack:
    # Flank ability - higher critical chance and increased base damage
    li $v0, 4
    la $a0, msg_player_flank
    syscall

    # Check if dragon is flying (increased evasion)
    lw $t0, dragonFlying
    move $a0, $t0
    jal calculate_flank_damage
    move $s0, $v0
    
    # Reset dragon flying status after attack
    sw $zero, dragonFlying
    # Reset player evasion after attack
    sw $zero, playerEvasion
    
    # Reduce Monster HP
    lw $t1, monsterHP
    sub $t1, $t1, $s0
    sw $t1, monsterHP
    
    # Apply Compound Interest on Debt Counter (only if attack hit)
    blez $s0, skip_debt_flank
    jal apply_compound_interest
    skip_debt_flank:

    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

player_lance_attack:
    # Lance ability - defensive, increases evasion, lower damage
    li $v0, 4
    la $a0, msg_player_lance
    syscall

    # Check if dragon is flying (increased evasion)
    lw $t0, dragonFlying
    move $a0, $t0
    jal calculate_lance_damage
    move $s0, $v0
    
    # Reset dragon flying status after attack
    sw $zero, dragonFlying
    # Increase player evasion (NOT reset this turn)
    li $t0, 1
    sw $t0, playerEvasion
    
    # Reduce Monster HP
    lw $t1, monsterHP
    sub $t1, $t1, $s0
    sw $t1, monsterHP
    
    # Apply Compound Interest on Debt Counter (only if attack hit)
    blez $s0, skip_debt_lance
    jal apply_compound_interest
    skip_debt_lance:

    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

player_quiz_attack:
    # Quiz ability - player must answer a question correctly
    # Check if all quizzes are completed
    lw $t0, quizAllCompleted
    bnez $t0, quiz_all_completed
    
    li $v0, 4
    la $a0, msg_player_quiz
    syscall
    
    # Count and display remaining questions
    jal count_remaining_questions
    move $t9, $v0  # Save count
    
    li $v0, 4
    la $a0, msg_quiz_remaining
    syscall
    li $v0, 1
    move $a0, $t9
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    # Find next available question (not yet completed)
    jal find_next_quiz
    move $t0, $v0  # $v0 contains question index (0-2) or -1 if all done
    
    # Check if all questions completed
    li $t1, -1
    beq $t0, $t1, quiz_all_completed
    
    # Branch based on question index (0, 1, or 2)
    beq $t0, 0, show_quiz_1
    beq $t0, 1, show_quiz_2
    beq $t0, 2, show_quiz_3
    j game_loop

quiz_all_completed:
    # All questions answered correctly
    li $v0, 4
    la $a0, msg_quiz_all_done
    syscall
    
    # Don't consume turn, let player choose another action
    li $v0, 32
    li $a0, 1000
    syscall
    j player_can_act

show_quiz_1:
    # Display question 1
    li $v0, 4
    la $a0, quiz_q1
    syscall
    la $a0, quiz_q1_opt1
    syscall
    la $a0, quiz_q1_opt2
    syscall
    la $a0, quiz_q1_opt3
    syscall
    la $a0, quiz_q1_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q1_answer
    li $t3, 0  # Question index 0
    j check_quiz_answer

show_quiz_2:
    # Display question 2
    li $v0, 4
    la $a0, quiz_q2
    syscall
    la $a0, quiz_q2_opt1
    syscall
    la $a0, quiz_q2_opt2
    syscall
    la $a0, quiz_q2_opt3
    syscall
    la $a0, quiz_q2_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q2_answer
    li $t3, 1  # Question index 1
    j check_quiz_answer

show_quiz_3:
    # Display question 3
    li $v0, 4
    la $a0, quiz_q3
    syscall
    la $a0, quiz_q3_opt1
    syscall
    la $a0, quiz_q3_opt2
    syscall
    la $a0, quiz_q3_opt3
    syscall
    la $a0, quiz_q3_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q3_answer
    li $t3, 2  # Question index 2
    j check_quiz_answer

check_quiz_answer:
    # $t1 = player's answer, $t2 = correct answer, $t3 = question index (0, 1, or 2)
    move $s7, $t3  # Save question index
    bne $t1, $t2, quiz_wrong
    
    # Correct answer - apply compound interest 5 TIMES (5x multiplier)
    li $v0, 4
    la $a0, msg_quiz_correct
    syscall
    
    # Mark this question as completed
    beq $s7, 0, mark_q1_complete
    beq $s7, 1, mark_q2_complete
    beq $s7, 2, mark_q3_complete
    
mark_q1_complete:
    li $t0, 1
    sw $t0, quiz_q1_completed
    j apply_correct_bonus
    
mark_q2_complete:
    li $t0, 1
    sw $t0, quiz_q2_completed
    j apply_correct_bonus
    
mark_q3_complete:
    li $t0, 1
    sw $t0, quiz_q3_completed
    j apply_correct_bonus

apply_correct_bonus:
    # Apply compound interest 5 times for massive debt growth
    jal apply_compound_interest
    jal apply_compound_interest
    jal apply_compound_interest
    jal apply_compound_interest
    jal apply_compound_interest
    j quiz_finish

quiz_wrong:
    # Wrong answer - apply only single compound interest and lose 5 HP
    li $v0, 4
    la $a0, msg_quiz_wrong
    syscall
    
    # Reduce player HP by 5 as penalty
    lw $t0, playerHP
    addi $t0, $t0, -5
    sw $t0, playerHP
    
    # Apply compound interest once
    jal apply_compound_interest
    j quiz_finish

quiz_finish:
    # Display updated debt counter
    li $v0, 4
    la $a0, msg_debt_update
    syscall
    li $v0, 1
    lw $a0, debtCounter
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    # Reset player evasion and dragon flying
    sw $zero, playerEvasion
    sw $zero, dragonFlying
    
    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop

find_next_quiz:
    # Find the next unanswered question
    # Returns question index in $v0 (0-2) or -1 if all completed
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check question 1
    lw $t0, quiz_q1_completed
    beqz $t0, return_q1
    
    # Check question 2
    lw $t0, quiz_q2_completed
    beqz $t0, return_q2
    
    # Check question 3
    lw $t0, quiz_q3_completed
    beqz $t0, return_q3
    
    # All completed
    li $t0, 1
    sw $t0, quizAllCompleted
    li $v0, -1
    j find_next_quiz_end
    
return_q1:
    li $v0, 0
    j find_next_quiz_end
    
return_q2:
    li $v0, 1
    j find_next_quiz_end
    
return_q3:
    li $v0, 2
    
find_next_quiz_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

count_remaining_questions:
    # Count how many questions are not yet completed
    # Returns count in $v0
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $v0, 0  # Counter
    
    # Check question 1
    lw $t0, quiz_q1_completed
    beqz $t0, count_q1
    j check_q2
    count_q1:
    addi $v0, $v0, 1
    
    # Check question 2
    check_q2:
    lw $t0, quiz_q2_completed
    beqz $t0, count_q2
    j check_q3
    count_q2:
    addi $v0, $v0, 1
    
    # Check question 3
    check_q3:
    lw $t0, quiz_q3_completed
    beqz $t0, count_q3
    j count_done
    count_q3:
    addi $v0, $v0, 1
    
    count_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

monster_turn:
    li $v0, 32
    li $a0, 1000
    syscall

    # Check if dragon is stunned
    lw $t0, dragonStunned
    beqz $t0, dragon_can_act
    
    # Dragon is stunned, skip turn
    li $v0, 4
    la $a0, msg_dragon_stunned
    syscall
    
    # Reset stun status
    sw $zero, dragonStunned
    
    # Change to player turn
    li $t0, 0
    sw $t0, turn
    
    li $v0, 32
    li $a0, 1000
    syscall
    j game_loop

dragon_can_act:
    # Dragon randomly chooses attack type
    # 33% Fire Breath, 33% Stomp, 33% Fly
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    move $t0, $a0
    
    beq $t0, 1, dragon_stomp
    beq $t0, 2, dragon_fly
    
    # Fire Breath Attack
    li $v0, 4
    la $a0, msg_monster_atk
    syscall

    # Check player evasion
    lw $a0, playerEvasion
    jal calculate_dragon_damage
    move $s0, $v0

    # Reduce Player HP
    lw $t1, playerHP
    sub $t1, $t1, $s0
    sw $t1, playerHP
    
    # Apply Dragon Debt Payment (only if attack hit)
    # Dragon pays 5% of current debt
    blez $s0, skip_debt_monster
    jal apply_dragon_payment
    skip_debt_monster:

    # Reset player evasion after dragon attack
    sw $zero, playerEvasion

    li $t0, 0
    sw $t0, turn
    j game_loop

dragon_stomp:
    # Stomp attack - stuns the player
    li $v0, 4
    la $a0, msg_stomp
    syscall
    
    # Set player as stunned
    li $t0, 1
    sw $t0, playerStunned
    
    # Apply Dragon Debt Payment (stomp also reduces debt by 5%)
    jal apply_dragon_payment
    
    li $t0, 0
    sw $t0, turn
    j game_loop

dragon_fly:
    # Fly attack - increases dragon evasion
    li $v0, 4
    la $a0, msg_fly
    syscall
    
    # Set dragon as flying (increased evasion)
    li $t0, 1
    sw $t0, dragonFlying
    
    # No HP damage, no debt for fly
    
    li $t0, 0
    sw $t0, turn
    j game_loop

calculate_attack_damage:
    # $a0 = 1 if dragon is flying (reduced hit chance), 0 otherwise
    move $t9, $a0  # Save flying status
    
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    
    # If dragon is flying, player needs 50+ to hit (50% miss instead of 20%)
    beqz $t9, normal_hit_check
    blt $t0, 50, attack_missed
    bge $t0, 90, critical_hit
    j normal_damage
    
    normal_hit_check:
    blt $t0, 20, attack_missed
    bge $t0, 85, critical_hit

    normal_damage:
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
    # $a0 = 1 if player has evasion (reduced hit chance), 0 otherwise
    # Dragon has only 30% chance to hit (0-29 hits, 30-99 misses)
    # If player has evasion, dragon needs 50+ to hit (50% miss instead of 70%)
    move $t9, $a0  # Save evasion status
    
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    
    # If player has evasion, dragon needs 50+ to hit
    beqz $t9, dragon_normal_hit_check
    blt $t0, 50, attack_missed
    bge $t0, 95, dragon_critical_hit
    j dragon_normal_damage
    
    dragon_normal_hit_check:
    bge $t0, 30, attack_missed  # 70% chance to miss
    bge $t0, 25, dragon_critical_hit  # 5% chance of critical

    dragon_normal_damage:
    # Normal attack - High damage (20-35)
    li $v0, 42
    li $a0, 0
    li $a1, 16
    syscall
    addi $v0, $a0, 20
    j print_damage

dragon_critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 50
    j print_damage

calculate_flank_damage:
    # $a0 = 1 if dragon is flying (reduced hit chance), 0 otherwise
    # Flank has same hit chance as normal attack but HIGHER critical chance (40%)
    # Base damage is increased: 15-24 instead of 10-19
    # Critical damage: 30 instead of 25
    move $t9, $a0  # Save flying status
    
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    
    # If dragon is flying, player needs 50+ to hit (50% miss instead of 20%)
    beqz $t9, flank_normal_hit_check
    blt $t0, 50, attack_missed
    bge $t0, 60, flank_critical_hit  # 40% critical chance (60-99)
    j flank_normal_damage
    
    flank_normal_hit_check:
    blt $t0, 20, attack_missed
    bge $t0, 60, flank_critical_hit  # 40% critical chance (60-99)

    flank_normal_damage:
    # Damage: 15-24
    li $v0, 42
    li $a0, 0
    li $a1, 10
    syscall
    addi $v0, $a0, 15
    j print_damage

flank_critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 30
    j print_damage

calculate_lance_damage:
    # $a0 = 1 if dragon is flying (reduced hit chance), 0 otherwise
    # Lance is defensive: lower damage (5-9), same hit chance as normal attack
    # Critical chance: 15% (same as normal attack)
    # Critical damage: 15 (lower than normal)
    move $t9, $a0  # Save flying status
    
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    
    # If dragon is flying, player needs 50+ to hit (50% miss instead of 20%)
    beqz $t9, lance_normal_hit_check
    blt $t0, 50, attack_missed
    bge $t0, 90, lance_critical_hit
    j lance_normal_damage
    
    lance_normal_hit_check:
    blt $t0, 20, attack_missed
    bge $t0, 85, lance_critical_hit

    lance_normal_damage:
    # Damage: 5-9 (lowest of all attacks)
    li $v0, 42
    li $a0, 0
    li $a1, 5
    syscall
    addi $v0, $a0, 5
    j print_damage

lance_critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 15
    j print_damage

# ----------------------------------------------------------------
# COMPOUND INTEREST FUNCTIONS
# ----------------------------------------------------------------
apply_compound_interest:
    # Apply compound interest to debt counter
    # Formula: newDebt = currentDebt + (currentDebt * rate / 100) + baseDamage
    # Returns with updated debtCounter
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, debtCounter
    lw $t1, interestRate      # Rate = 10
    lw $t2, baseDamage        # Base = 100
    
    # Calculate (currentDebt * rate / 100)
    mul $t3, $t0, $t1         # t3 = debt * 10
    div $t3, $t3, 100         # t3 = (debt * 10) / 100
    
    # Add base damage and interest
    add $t0, $t0, $t3
    add $t0, $t0, $t2
    
    # Cap at debtLimit
    lw $t4, debtLimit
    blt $t0, $t4, store_debt
    move $t0, $t4
    store_debt:
    sw $t0, debtCounter
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

apply_compound_interest_direct:
    # Apply compound interest with given debt and rate
    # $a0 = rate, $a1 = base, returns in $v0
    # Current debt is in $t1 (on entry)
    mul $t3, $t1, $a0
    div $t3, $t3, 100
    add $v0, $t1, $t3
    add $v0, $v0, $a1
    jr $ra

apply_dragon_payment:
    # Dragon pays 5% of current debt counter
    # Formula: newDebt = currentDebt - (currentDebt * 5 / 100)
    lw $t0, debtCounter
    lw $t1, debtCounter
    
    # Calculate (currentDebt * 5 / 100)
    mul $t3, $t1, 5
    div $t3, $t3, 100
    
    # Subtract payment from debt
    sub $t0, $t0, $t3
    
    # Don't let debt go below 0
    bge $t0, 0, store_payment
    li $t0, 0
    store_payment:
    sw $t0, debtCounter
    
    jr $ra

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

    # Dragon Bar (1000 HP max = 50 pixels max)
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

exit:
    li $v0, 10
    syscall