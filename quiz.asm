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

# ----------------------------------------------------------------
# QUIZ HELPER FUNCTIONS
# ----------------------------------------------------------------
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
