# ============================================
# BATTLE.ASM - Combat Logic & Damage Calculations
# ============================================
# This file contains all player/dragon attack functions,
# damage calculations, and compound interest mechanics.

.text
    # Ensure main is the entry point (prevents battle.asm from being executed first)
    j main

# ----------------------------------------------------------------
# PLAYER ATTACKS
# ----------------------------------------------------------------
player_prepare_shield:
    lw $t0, warriorShield
    bgtz $t0, cancel_shield
    
    li $v0, 4
    la $a0, msg_player_shield
    syscall
    
    # Set shield to 50 HP absorption
    li $t1, 50
    sw $t1, warriorShield
    j done_shield_toggle

cancel_shield:
    li $v0, 4
    la $a0, msg_shield_cancel
    syscall
    sw $zero, warriorShield

done_shield_toggle:
    # Reset dragon flying status and player evasion
    sw $zero, dragonFlying
    sw $zero, playerEvasion

    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500 # wait 500ms
    syscall
    j game_loop

# ----------------------------------------------------------------
# SKIP TURN - Player chooses to do nothing
# ----------------------------------------------------------------
player_skip_turn:
    # Display skip message
    li $v0, 4
    la $a0, msg_player_skip
    syscall
    
    # End turn
    li $t0, 1
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500 # wait 500ms
    syscall
    j game_loop

player_net_attack:
    # Check stamina cost (25)
    lw $t0, playerStamina
    lw $t1, staminaCostNet
    blt $t0, $t1, insufficient_stamina
    sub $t0, $t0, $t1
    sw $t0, playerStamina
    
    # Net ability - traps and stuns the dragon (no damage)
    li $v0, 4
    la $a0, msg_player_net
    syscall
    
    # Calculate hit chance (60% base hit rate)
    lw $t8, dragonFlying
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $v0
    # Check if dragon is not flying (normal hit chance)
    beqz $t8, net_normal_hit_check
    # Check if dragon is flying (needs 60+ to hit = 40% success)
    blt $t0, 60, net_missed
    j net_hit
    
    net_normal_hit_check:
    blt $t0, 40, net_missed
    
    net_hit:
    # Set dragon as stunned and trapped
    li $v0, 4
    la $a0, msg_player_net_success
    syscall 
    
    li $t0, 1
    sw $t0, dragonStunned
    sw $t0, dragonOnNet
    
    # No HP damage for net ability, but increases debt counter
    lw $t1, debtCounter
    lw $a0, interestRate
    lw $a1, baseDamage
    jal apply_compound_interest_direct
    move $t1, $v0
    sw $t1, debtCounter
    
    j net_end
    
    net_missed:
    # Net attack missed
    li $v0, 4
    la $a0, msg_miss
    syscall
    
    net_end:
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
    # Check stamina cost (40)
    lw $t0, playerStamina
    lw $t1, staminaCostFlank
    blt $t0, $t1, insufficient_stamina
    sub $t0, $t0, $t1
    sw $t0, playerStamina
    
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
    # Check stamina cost (20)
    lw $t0, playerStamina
    lw $t1, staminaCostSpear
    blt $t0, $t1, insufficient_stamina
    sub $t0, $t0, $t1
    sw $t0, playerStamina
    
    # Lance ability - defensive, increases evasion, lower damage
    li $v0, 4
    la $a0, msg_player_spear
    syscall

    # --- SPEAR ANIMATION ---
    li $t0, 1
    sw $t0, spear_attack_active
    li $t0, 60             # Start spear slightly ahead of warrior
    sw $t0, spearX
    
    # Initial full render to set the stage
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal render_all
    lw $ra, 0($sp)
    addi $sp, $sp, 4

spear_anim_loop:
    # Save $ra as we are calling another function
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Save old X to erase trail later
    lw $s1, spearX
    
    # 1. Advance spear position
    addi $t0, $s1, 10      # Animation speed
    sw $t0, spearX
    
    # 2. Redraw characters (draws spear at NEW position)
    jal render_characters
    
    # 3. Erase the TRAIL left behind at OLD position
    move $a0, $s1
    jal erase_spear_trail
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    # Small delay for smoothness
    li $v0, 32
    li $a0, 10             # Fast animation
    syscall
    
    # Check if reached dragon (X=180)
    lw $t0, spearX
    blt $t0, 180, spear_anim_loop
    
    # Reset animation state
    sw $zero, spear_attack_active
    # --- END ANIMATION ---

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
    # Regenerate dragon stamina at start of turn
    lw $t0, dragonStamina
    lw $t1, staminaRegen
    add $t0, $t0, $t1
    lw $t2, dragonMaxStamina
    blt $t0, $t2, store_dragon_stamina
    move $t0, $t2
    store_dragon_stamina:
    sw $t0, dragonStamina

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
    
    # Reset stun status and net trap
    sw $zero, dragonStunned
    sw $zero, dragonOnNet
    
    # Change to player turn
    li $t0, 0
    sw $t0, turn
    
    li $v0, 32
    li $a0, 1000
    syscall
    j game_loop

dragon_can_act:
    # Reset defense stance when dragon attacks
    sw $zero, dragonDefense
    
    # Check if dragon is preparing Inferno
    lw $t0, dragonPreparingInferno
    bnez $t0, dragon_inferno_unleash

    # Dragon randomly chooses attack type
    # 25% Fire Breath (20), 25% Stomp (30), 25% Fly (25), 25% Inferno (50)
    li $v0, 42
    li $a0, 0
    li $a1, 4
    syscall
    move $t0, $a0

    # Check selected attack and validate stamina
    beq $t0, 0, try_dragon_fire
    beq $t0, 1, try_dragon_stomp
    beq $t0, 2, try_dragon_fly
    beq $t0, 3, try_dragon_inferno
    j try_dragon_fire  # Default fallback

try_dragon_fire:
    # Fire costs 20 stamina
    lw $t1, dragonStamina
    lw $t2, staminaCostFire
    blt $t1, $t2, try_dragon_fly  # Try cheaper attack
    sub $t1, $t1, $t2
    sw $t1, dragonStamina
    j do_dragon_fire

try_dragon_stomp:
    # Stomp costs 30 stamina
    lw $t1, dragonStamina
    lw $t2, staminaCostStomp
    blt $t1, $t2, try_dragon_fire  # Try cheaper attack
    sub $t1, $t1, $t2
    sw $t1, dragonStamina
    j dragon_stomp

try_dragon_fly:
    # Fly costs 25 stamina
    lw $t1, dragonStamina
    lw $t2, staminaCostFly
    blt $t1, $t2, dragon_skip_no_stamina  # No stamina for any attack
    sub $t1, $t1, $t2
    sw $t1, dragonStamina
    j dragon_fly

try_dragon_inferno:
    # Inferno costs 50 stamina
    lw $t1, dragonStamina
    lw $t2, staminaCostInferno
    blt $t1, $t2, try_dragon_stomp  # Try cheaper attack
    sub $t1, $t1, $t2
    sw $t1, dragonStamina
    j dragon_inferno_prep

dragon_skip_no_stamina:
    # Dragon has no stamina for any attack, enter defense stance
    li $v0, 4
    la $a0, msg_dragon_skip
    syscall
    
    # Set dragon to defense stance
    li $t0, 1
    sw $t0, dragonDefense
    
    li $t0, 0
    sw $t0, turn
    
    li $v0, 32
    li $a0, 500 # wait 500ms
    syscall
    j game_loop

do_dragon_fire:
    # Fire Breath Attack
    li $v0, 4
    la $a0, msg_monster_atk
    syscall

    # Trigger Fireball Animation
    jal dragon_fireball_animation

    # Check player evasion
    lw $a0, playerEvasion
    jal calculate_dragon_damage
    move $s0, $v0

    # Reduce Player HP (with Shield)
    move $a0, $s0
    jal apply_damage_to_player
    
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

dragon_inferno_prep:
    # Set preparation flag
    li $t1, 1
    sw $t1, dragonPreparingInferno
    
    # Show message
    li $v0, 4
    la $a0, msg_dragon_prepare_inferno
    syscall
    
    # Change turn to player
    li $t0, 0
    sw $t0, turn
    j game_loop

dragon_inferno_unleash:
    # Reset preparation flag
    sw $zero, dragonPreparingInferno
    # Fall through to dragon_inferno
    
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
    
    # Trigger Fireball Animation
    jal dragon_fireball_animation
    
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
    
    # Reduce Player HP (with Shield)
    move $a0, $s0
    jal apply_damage_to_player
    
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

# ----------------------------------------------------------------
# APPLY DAMAGE TO PLAYER (with Shield Absorption)
# $a0 = Raw Damage
# ----------------------------------------------------------------
apply_damage_to_player:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    
    move $s0, $a0          # $s0 = damage to apply
    lw $t0, warriorShield
    
    # Reset shield if it's our turn starting (handled in player_prepare_shield)
    # but here we just process absorption
    
    beqz $t0, skip_shield_logic
    
    # Shield is active
    bge $t0, $s0, shield_fully_absorbs
    
    # Shield partially absorbs
    sub $s0, $s0, $t0      # damage = damage - shield
    sw $zero, warriorShield
    
    li $v0, 4
    la $a0, msg_shield_absorbed
    syscall
    li $v0, 1
    li $a0, 0
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    j skip_shield_logic

shield_fully_absorbs:
    sub $t0, $t0, $s0      # shield = shield - damage
    sw $t0, warriorShield
    li $s0, 0              # damage = 0
    
    li $v0, 4
    la $a0, msg_shield_absorbed
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, newline
    syscall

skip_shield_logic:
    # Apply remaining damage to HP
    lw $t1, playerHP
    sub $t1, $t1, $s0
    sw $t1, playerHP
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
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

# ----------------------------------------------------------------
# DRAGON ANIMATION FUNCTIONS
# ----------------------------------------------------------------
dragon_fireball_animation:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # 1. Start Animation State
    li $t1, 1
    sw $t1, fireball_attack_active
    li $t1, 180            # Initial fireball X (aligned with dragon which is at 180)
    sw $t1, fireballX
    
    # Initial render to show dragon in inferno (attacking) pose
    jal render_all
    
    dfa_loop:
        lw $t0, fireballX
        ble $t0, 50, dfa_done  # Target: player at 50
        
        # Save current X as oldX
        move $s1, $t0
        
        # Advance fireball (move left)
        subi $t0, $t0, 10
        sw $t0, fireballX
        
        # Draw new state (characters)
        jal render_characters
        
        # Erase trail (selective erasure)
        move $a0, $s1
        jal erase_fireball_trail
        
        # Delay (10ms)
        li $a0, 10
        li $v0, 32
        syscall
        
        j dfa_loop
        
    dfa_done:
    li $t1, 0
    sw $t1, fireball_attack_active
    jal render_all         # Restore normal pose and scene
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# INSUFFICIENT STAMINA HANDLER
# ----------------------------------------------------------------
insufficient_stamina:
    li $v0, 4
    la $a0, msg_low_stamina
    syscall
    j player_can_act