# ============================================
# DATA.ASM - Game Data, Variables & Messages
# ============================================
# This file contains all game variables, constants,
# and text messages used throughout the game.

.data
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
    turnCounter:    .word 1           # Current turn number (starts at 1)
    playerStunned:  .word 0           # 0 = Not stunned, 1 = Stunned
    dragonFlying:   .word 0           # 0 = On ground, 1 = Flying (increased evasion)
    dragonStunned:  .word 0           # 0 = Not stunned, 1 = Stunned (Sword ability)
    playerEvasion:  .word 0           # 0 = Normal evasion, 1 = Increased evasion (Spear ability)
    spear_attack_active: .word 0      # 0 = normal, 1 = spear animation in progress
    spearX:              .word 0      # X position of spear during animation
    
    # Consumable Items - Estus Flask (Dark Souls Reference)
    estusFlaskCount: .word 2          # Number of Estus Flasks available (limited resource)
    estusFlaskHeal:  .word 25         # HP restored per flask (balanced with dragon damage)
    estusFlaskRounds:.word 2          # Number of rounds flask effect lasts (risk/reward)
    estusFlaskActive:.word 0          # 0 = Inactive, 1 = Active flask effect
    estusFlaskCounter:.word 0         # Counts down remaining rounds
    
    # Compound Interest Rates
    interestRate:   .word 10          # 10% interest rate
    baseDamage:     .word 100         # Base damage to add to interest
    
    # Quiz System
    quizQuestionIndex: .word 0        # Current question index (0-2)
    quiz_q1_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q2_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q3_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q4_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q5_completed: .word 0        # 0 = Not completed, 1 = Completed
    quiz_q6_completed: .word 0        # 0 = Not completed, 1 = Completed
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
    
    quiz_q4:        .asciiz "\n[QUIZ] Qual e a menor unidade de informacao que um computador\ndigital pode entender e processar?\n"
    quiz_q4_opt1:   .asciiz "1) Byte\n"
    quiz_q4_opt2:   .asciiz "2) Hertz\n"
    quiz_q4_opt3:   .asciiz "3) Pixel\n"
    quiz_q4_opt4:   .asciiz "4) Bit\n"
    quiz_q4_answer: .word 4            # Correct answer is option 4
    
    quiz_q5:        .asciiz "\n[QUIZ] Qual dos seguintes componentes e classificado exclusivamente\ncomo um dispositivo de Entrada (Input)?\n"
    quiz_q5_opt1:   .asciiz "1) Impressora\n"
    quiz_q5_opt2:   .asciiz "2) Monitor\n"
    quiz_q5_opt3:   .asciiz "3) Teclado\n"
    quiz_q5_opt4:   .asciiz "4) Caixas de Som\n"
    quiz_q5_answer: .word 3            # Correct answer is option 3
    
    quiz_q6:        .asciiz "\n[QUIZ] Qual unidade de medida e comumente utilizada para expressar\na velocidade de clock (frequencia) de um processador moderno?\n"
    quiz_q6_opt1:   .asciiz "1) DPI (Dots Per Inch)\n"
    quiz_q6_opt2:   .asciiz "2) Gigawatts (GW)\n"
    quiz_q6_opt3:   .asciiz "3) Gigabytes (GB)\n"
    quiz_q6_opt4:   .asciiz "4) Gigahertz (GHz)\n"
    quiz_q6_answer: .word 4            # Correct answer is option 4

    # --- MESSAGES ---
    msg_start:      .asciiz "\n>>>=== FULL HD BATTLE (Unit 1) ===<<<\n"
    msg_start_info: .asciiz "[!] Victory Conditions: Defeat Dragon OR reach 10,000 Debt!\n"
    msg_player_atk: .asciiz "\n>>> [PLAYER] You attacked! "
    msg_player_sword:.asciiz "\n>>> [PLAYER] You used SWORD!\n"
    msg_player_sword_success:.asciiz."\n*** The dragon is STUNNED! ***\n"
    msg_player_flank:.asciiz "\n>>> [PLAYER] You used FLANK! "
    msg_player_spear:.asciiz "\n>>> [PLAYER] You used SPEAR! Your evasion is increased!\n"
    msg_player_quiz:.asciiz "\n*** --- AOC QUIZ TIME! --- ***\n"
    msg_quiz_remaining:.asciiz "[?] Questoes restantes: "
    msg_quiz_prompt:.asciiz ">>> Your answer (1-4): "
    msg_quiz_correct:.asciiz "\n[OK] CORRECT! 5x compound interest applied! $$$\n"
    msg_quiz_wrong: .asciiz "\n[X] WRONG! -5 HP penalty!\n"
    msg_quiz_all_done:.asciiz "\n[*] All questions answered correctly! Quiz no longer available.\n"
    msg_debt_update:.asciiz "[$] Debt Counter updated: "
    msg_monster_atk:.asciiz "\n<<< [DRAGON] The monster breathed fire! "
    msg_stomp:      .asciiz "\n<<< [DRAGON] The dragon stomped! You are STUNNED!\n"
    msg_fly:        .asciiz "\n<<< [DRAGON] The dragon takes flight! Evasion increased!\n"
    msg_inferno:    .asciiz "\n<<< [DRAGON] The dragon unleashes INFERNO! Devastating attack!\n"
    msg_stunned:    .asciiz "[!] [PLAYER] You are stunned and cannot attack this turn!\n"
    msg_dragon_stunned: .asciiz "[!] [DRAGON] The dragon is stunned and cannot attack this turn!\n"
    msg_damage:     .asciiz ">> Damage dealt: "
    msg_miss:       .asciiz "-- ATTACK MISSED! --\n"
    msg_crit:       .asciiz "*** CRITICAL HIT!!! *** "
    msg_choose_action: .asciiz "\n[PLAYER] Choose: (1)Attack (2)Sword (3)Flank (4)Spear (5)Quiz (6)Estus - "
    msg_win:        .asciiz "\n*** VICTORY! - Dragon Defeated! ***\n"
    msg_lose:       .asciiz "\n*** DEFEAT... ***\n"
    msg_win_debt:   .asciiz "\n*** VICTORY BY COMPOUND INTEREST! Debt reached 10,000! ***\n"
    msg_lose_debt:  .asciiz "\n*** DEFEAT BY DEBT! You are too much in debt! ***\n"
    msg_status:     .asciiz "\n====== BATTLE STATUS ======\n"
    msg_turn_num:   .asciiz "Turn: "
    msg_player_hp:  .asciiz "[Player] HP: "
    msg_player_debt:.asciiz " | Debt: "
    msg_estus_count:.asciiz " | Estus: "
    msg_monster_hp: .asciiz "\n[Dragon] HP: "
    msg_monster_debt:.asciiz "\n[$ DEBT COUNTER: "
    msg_debt_limit: .asciiz " / 10,000]\n"
    msg_estus_used:.asciiz "\n[+] Drank Estus Flask! Regenerating "
    msg_estus_heal: .asciiz " HP per round for 2 rounds!\n"
    msg_no_estus: .asciiz "\n[!] ERROR: You have no Estus Flasks left!\n"
    msg_hp_restored:.asciiz "[+] HP Restored: "
    msg_estus_active:.asciiz "[ESTUS ACTIVE] Rounds remaining: "
    msg_rounds_left:.asciiz "\n"
    newline:        .asciiz "\n"
