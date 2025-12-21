# ============================================
# QUIZ.ASM - Quiz System Functions
# ============================================
# This file contains the quiz ability logic including
# question selection, answer validation, and completion tracking.

.text

# ----------------------------------------------------------------
# QUIZ ABILITY
# ----------------------------------------------------------------
player_quiz_attack:
    # Check stamina cost (50)
    lw $t0, playerStamina
    lw $t1, staminaCostQuiz
    blt $t0, $t1, insufficient_stamina
    sub $t0, $t0, $t1
    sw $t0, playerStamina
    
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
    
    # Branch based on question index (0, 1, 2, 3, 4, or 5)
    beq $t0, 0, show_quiz_1
    beq $t0, 1, show_quiz_2
    beq $t0, 2, show_quiz_3
    beq $t0, 3, show_quiz_4
    beq $t0, 4, show_quiz_5
    beq $t0, 5, show_quiz_6
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

show_quiz_4:
    # Display question 4
    li $v0, 4
    la $a0, quiz_q4
    syscall
    la $a0, quiz_q4_opt1
    syscall
    la $a0, quiz_q4_opt2
    syscall
    la $a0, quiz_q4_opt3
    syscall
    la $a0, quiz_q4_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q4_answer
    li $t3, 3  # Question index 3
    j check_quiz_answer

show_quiz_5:
    # Display question 5
    li $v0, 4
    la $a0, quiz_q5
    syscall
    la $a0, quiz_q5_opt1
    syscall
    la $a0, quiz_q5_opt2
    syscall
    la $a0, quiz_q5_opt3
    syscall
    la $a0, quiz_q5_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q5_answer
    li $t3, 4  # Question index 4
    j check_quiz_answer

show_quiz_6:
    # Display question 6
    li $v0, 4
    la $a0, quiz_q6
    syscall
    la $a0, quiz_q6_opt1
    syscall
    la $a0, quiz_q6_opt2
    syscall
    la $a0, quiz_q6_opt3
    syscall
    la $a0, quiz_q6_opt4
    syscall
    
    # Get answer
    li $v0, 4
    la $a0, msg_quiz_prompt
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Player's answer
    
    lw $t2, quiz_q6_answer
    li $t3, 5  # Question index 5
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
    beq $s7, 3, mark_q4_complete
    beq $s7, 4, mark_q5_complete
    beq $s7, 5, mark_q6_complete
    
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
    
mark_q4_complete:
    li $t0, 1
    sw $t0, quiz_q4_completed
    j apply_correct_bonus
    
mark_q5_complete:
    li $t0, 1
    sw $t0, quiz_q5_completed
    j apply_correct_bonus
    
mark_q6_complete:
    li $t0, 1
    sw $t0, quiz_q6_completed
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
    
    # Reduce player HP by 5 as penalty (with shield)
    li $a0, 5
    jal apply_damage_to_player
    
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

# ----------------------------------------------------------------
# QUIZ HELPER FUNCTIONS
# ----------------------------------------------------------------
find_next_quiz:
    # Find a random unanswered question
    # Returns question index in $v0 (0-5) or -1 if all completed
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    # Build array of available questions
    # Use $s0 as array pointer, $s1 as counter
    addi $s0, $sp, -24  # Array location on stack
    li $s1, 0           # Counter of available questions
    
    # Check question 1
    lw $t0, quiz_q1_completed
    bnez $t0, check_random_q2
    sw $zero, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_random_q2:
    lw $t0, quiz_q2_completed
    bnez $t0, check_random_q3
    li $t1, 1
    sw $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_random_q3:
    lw $t0, quiz_q3_completed
    bnez $t0, check_random_q4
    li $t1, 2
    sw $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_random_q4:
    lw $t0, quiz_q4_completed
    bnez $t0, check_random_q5
    li $t1, 3
    sw $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_random_q5:
    lw $t0, quiz_q5_completed
    bnez $t0, check_random_q6
    li $t1, 4
    sw $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_random_q6:
    lw $t0, quiz_q6_completed
    bnez $t0, check_all_done
    li $t1, 5
    sw $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s1, $s1, 1
    
    check_all_done:
    beqz $s1, all_quiz_done
    
    # Generate random index from available questions
    li $v0, 42
    li $a0, 0
    move $a1, $s1
    syscall
    move $s2, $a0  # Random index
    
    # Get question number from array
    addi $s3, $sp, -24
    sll $t0, $s2, 2
    add $s3, $s3, $t0
    lw $v0, 0($s3)
    
    j find_next_quiz_end
    
all_quiz_done:
    li $t0, 1
    sw $t0, quizAllCompleted
    li $v0, -1
    
find_next_quiz_end:
    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 20
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
    j check_q4
    count_q3:
    addi $v0, $v0, 1
    
    # Check question 4
    check_q4:
    lw $t0, quiz_q4_completed
    beqz $t0, count_q4
    j check_q5
    count_q4:
    addi $v0, $v0, 1
    
    # Check question 5
    check_q5:
    lw $t0, quiz_q5_completed
    beqz $t0, count_q5
    j check_q6
    count_q5:
    addi $v0, $v0, 1
    
    # Check question 6
    check_q6:
    lw $t0, quiz_q6_completed
    beqz $t0, count_q6
    j count_done
    count_q6:
    addi $v0, $v0, 1
    
    count_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
