# ============================================
# BATTLE.ASM - Combat Logic & Damage Calculations
# ============================================
# This file contains all player/dragon attack functions,
# damage calculations, and compound interest mechanics.

.text

# ----------------------------------------------------------------
# PLAYER ATTACKS
# ----------------------------------------------------------------
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
    li $a0, 500 # wait 500ms
    syscall
    j game_loop

player_sword_attack:
    # Sword ability - stuns the dragon (no damage)
    li $v0, 4
    la $a0, msg_player_sword
    syscall
    
    # Calculate hit chance (80% base hit rate)
    lw $t8, dragonFlying
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $v0
    
    # Check if dragon is flying (needs 50+ to hit)
    beqz $t8, sword_normal_hit_check
    blt $t0, 50, sword_missed
    j sword_hit
    
    sword_normal_hit_check:
    blt $t0, 20, sword_missed
    
    sword_hit:
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
    
    j sword_end
    
    sword_missed:
    # Sword attack missed
    li $v0, 4
    la $a0, msg_miss
    syscall
    
    sword_end:
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

# ----------------------------------------------------------------
# DRAGON ATTACKS
# ----------------------------------------------------------------
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
    # 25% Fire Breath, 25% Stomp, 25% Fly, 25% Inferno (new devastating attack)
    li $v0, 42
    li $a0, 0
    li $a1, 4
    syscall
    move $t0, $a0
    
    beq $t0, 1, dragon_stomp
    beq $t0, 2, dragon_fly
    beq $t0, 3, dragon_inferno
    
    # Fire Breath Attack (default case 0)
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

dragon_inferno:
    # Inferno attack - devastating fire attack that ignores some defense
    li $v0, 4
    la $a0, msg_inferno
    syscall
    
    # Inferno has higher hit chance and always deals massive damage
    # 80% hit rate (ignores evasion effects mostly)
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    
    blt $t0, 20, inferno_missed  # 20% miss chance
    
    # Inferno always deals 45-65 damage (higher than normal attacks)
    li $v0, 42
    li $a0, 0
    li $a1, 21
    syscall
    addi $v0, $a0, 45
    
    # Show damage
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
    
    move $s0, $t9
    
    # Reduce Player HP
    lw $t1, playerHP
    sub $t1, $t1, $s0
    sw $t1, playerHP
    
    # Apply Dragon Debt Payment
    jal apply_dragon_payment
    
    # Reset evasion
    sw $zero, playerEvasion
    
    li $t0, 0
    sw $t0, turn
    j game_loop
    
    inferno_missed:
    li $v0, 4
    la $a0, msg_miss
    syscall
    
    li $t0, 0
    sw $t0, turn
    j game_loop

# ----------------------------------------------------------------
# DAMAGE CALCULATION FUNCTIONS
# ----------------------------------------------------------------
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
    bge $t0, 35, attack_missed  # 65% chance to miss (increased threat)
    bge $t0, 20, dragon_critical_hit  # 15% chance of critical (increased threat)

    dragon_normal_damage:
    # Normal attack - Increased damage (25-40) - more threatening
    li $v0, 42
    li $a0, 0
    li $a1, 16
    syscall
    addi $v0, $a0, 25
    j print_damage

    dragon_critical_hit:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 60

calculate_flank_damage:
    # $a0 = 1 if dragon is flying (reduced hit chance), 0 otherwise
    # Flank has same hit chance as normal attack but HIGHER critical chance (40%)
    # Base damage is increased: 15-24 instead of 10-19
    # Critical damage: 30 instead of 25
    move $t9, $a0  # Save flying status
    
    li $v0, 42 # Random int
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
# CONSUMABLE ITEMS - ESTUS FLASK (Dark Souls Reference)
# ----------------------------------------------------------------
player_use_estus:
    # Check if player has Estus Flasks
    lw $t0, estusFlaskCount
    blez $t0, no_estus_available
    
    # Check if Estus Flask is already active
    lw $t1, estusFlaskActive
    beqz $t1, estus_not_active
    
    # Estus Flask already active - can't use another
    li $v0, 4
    la $a0, msg_no_estus
    syscall
    j player_turn
    
    estus_not_active:
    # Display Estus Flask use message
    li $v0, 4
    la $a0, msg_estus_used
    syscall
    
    # Show heal amount
    li $v0, 1
    lw $a0, estusFlaskHeal
    syscall
    
    li $v0, 4
    la $a0, msg_estus_heal
    syscall
    
    # Activate Estus Flask
    li $t2, 1
    sw $t2, estusFlaskActive
    lw $t3, estusFlaskRounds
    sw $t3, estusFlaskCounter
    
    # Decrement flask count
    addi $t0, $t0, -1
    sw $t0, estusFlaskCount
    
    # Apply first heal immediately
    lw $t4, playerHP
    lw $t5, estusFlaskHeal
    add $t4, $t4, $t5
    
    # Cap at max HP (100)
    li $t6, 100
    blt $t4, $t6, store_healed_hp_estus
    move $t4, $t6
    store_healed_hp_estus:
    sw $t4, playerHP
    
    # Show HP restored
    li $v0, 4
    la $a0, msg_hp_restored
    syscall
    li $v0, 1
    move $a0, $t5
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    
    # End turn
    li $t7, 1
    sw $t7, turn
    
    li $v0, 32
    li $a0, 500
    syscall
    j game_loop
    
    no_estus_available:
    li $v0, 4
    la $a0, msg_no_estus
    syscall
    j player_turn

# ----------------------------------------------------------------
# APPLY ESTUS FLASK REGEN (called each turn)
# ----------------------------------------------------------------
apply_estus_regen:
    # Check if Estus Flask is active
    lw $t0, estusFlaskActive
    beqz $t0, estus_regen_end
    
    # Apply heal
    lw $t1, playerHP
    lw $t2, estusFlaskHeal
    add $t1, $t1, $t2
    
    # Cap at max HP
    li $t3, 100
    blt $t1, $t3, store_regen_hp_estus
    move $t1, $t3
    store_regen_hp_estus:
    sw $t1, playerHP
    
    # Decrement counter
    lw $t4, estusFlaskCounter
    addi $t4, $t4, -1
    sw $t4, estusFlaskCounter
    
    # Check if flask effect ends
    bgtz $t4, estus_regen_end
    
    # Flask expired
    sw $zero, estusFlaskActive
    sw $zero, estusFlaskCounter
    
    estus_regen_end:
    jr $ra