.data
    # --- IMPORTANDO OS SPRITES (Assets) ---
    .include "sprites.asm"

    # --- ENDEREÇOS ---
    displayAddress: .word 0x10040000

    # --- CORES GERAIS ---
    COR_FUNDO:      .word 0x228B22    # Verde Grama
    COR_CEU:        .word 0x87CEEB    # Azul Ceu
    COR_HP_CHEIO:   .word 0x00FF00    # Verde Vida
    COR_HP_DANO:    .word 0xFF0000    # Vermelho Dano
    COR_CURSOR:     .word 0xFFFF00    # Amarelo

    # --- VARIÁVEIS DE JOGO ---
    playerHP:       .word 100
    monsterHP:      .word 1000
    playerDebt:     .word 0           # Dívida do Jogador
    monsterDebt:    .word 0           # Dívida do Monstro
    debtLimit:      .word 5000        # Limite de Dívida
    turno:          .word 0           # 0 = Jogador, 1 = Monstro

    # --- TEXTOS ---
    msg_inicio:     .asciiz "\n--- BATALHA FULL HD (Unit 1) ---\n"
    msg_player_atk: .asciiz "\n[JOGADOR] Voce atacou! "
    msg_monster_atk:.asciiz "\n[DRAGAO] O monstro cuspiu fogo! "
    msg_dano:       .asciiz "Dano causado: "
    msg_miss:       .asciiz "ERROU O ATAQUE!\n"
    msg_crit:       .asciiz "CRITICO!!! "
    msg_win:        .asciiz "\n*** VITORIA! ***\n"
    msg_lose:       .asciiz "\n*** DERROTA... ***\n"
    msg_win_debt:   .asciiz "\n*** VITORIA POR DIVIDA! O dragao esta endividado! ***\n"
    msg_lose_debt:  .asciiz "\n*** DERROTA POR DIVIDA! Voce esta muito endividado! ***\n"
    msg_status:     .asciiz "\n--- STATUS DA BATALHA ---\n"
    msg_player_hp:  .asciiz "Jogador - HP: "
    msg_player_debt:.asciiz " | Divida: "
    msg_monster_hp: .asciiz "Dragao  - HP: "
    msg_monster_debt:.asciiz " | Divida: "
    newline:        .asciiz "\n"

# --- MACROS ---
.macro desenhar_retangulo(%x, %y, %w, %h, %cor_label)
    li $a0, %x
    li $a1, %y
    li $a2, %w
    li $v1, %h
    lw $a3, %cor_label
    jal func_desenhar_rect
.end_macro

.text
.globl main

main:
    li $v0, 4
    la $a0, msg_inicio
    syscall

loop_jogo:
    # 1. Verificar Fim de Jogo
    # Verificar HP
    lw $t0, playerHP
    blez $t0, game_over_lose
    lw $t1, monsterHP
    blez $t1, game_over_win
    
    # Verificar Dívida
    lw $t2, playerDebt
    lw $t3, debtLimit
    bge $t2, $t3, game_over_lose_debt
    lw $t2, monsterDebt
    bge $t2, $t3, game_over_win_debt

    # 2. Mostrar Status da Batalha
    jal mostrar_status

    # 3. Renderizar (Agora em Full Res)
    jal renderizar_tudo

    # 4. Lógica de Turnos
    lw $t0, turno
    beq $t0, 0, turno_jogador
    beq $t0, 1, turno_monstro
    j loop_jogo

# ----------------------------------------------------------------
# LÓGICA DE BATALHA
# ----------------------------------------------------------------
turno_jogador:
    li $v0, 12 
    syscall
    move $t0, $v0
    li $t1, 10
    bne $t0, $t1, turno_jogador

    li $v0, 4
    la $a0, msg_player_atk
    syscall

    jal calcular_dano_ataque
    move $s0, $v0
    
    # Reduzir HP do monstro
    lw $t1, monsterHP
    sub $t1, $t1, $s0
    sw $t1, monsterHP
    
    # Aumentar Dívida do monstro em 500 (apenas se o ataque acertou)
    blez $s0, skip_debt_player
    lw $t1, monsterDebt
    addi $t1, $t1, 500
    sw $t1, monsterDebt
    skip_debt_player:

    li $t0, 1
    sw $t0, turno
    
    li $v0, 32
    li $a0, 500
    syscall
    j loop_jogo

turno_monstro:
    li $v0, 32
    li $a0, 1000
    syscall

    li $v0, 4
    la $a0, msg_monster_atk
    syscall

    jal calcular_dano_ataque
    move $s0, $v0

    # Reduzir HP do jogador
    lw $t1, playerHP
    sub $t1, $t1, $s0
    sw $t1, playerHP
    
    # Aumentar Dívida do jogador em 500 (apenas se o ataque acertou)
    blez $s0, skip_debt_monster
    lw $t1, playerDebt
    addi $t1, $t1, 500
    sw $t1, playerDebt
    skip_debt_monster:

    li $t0, 0
    sw $t0, turno
    j loop_jogo

calcular_dano_ataque:
    li $v0, 42
    li $a0, 0
    li $a1, 100
    syscall
    move $t0, $a0
    blt $t0, 20, ataque_errou
    bge $t0, 85, ataque_critico

    li $v0, 42
    li $a0, 0
    li $a1, 10
    syscall
    addi $v0, $a0, 10
    j imprime_dano

ataque_critico:
    li $v0, 4
    la $a0, msg_crit
    syscall
    li $v0, 25
    j imprime_dano

ataque_errou:
    li $v0, 4
    la $a0, msg_miss
    syscall
    li $v0, 0
    jr $ra

imprime_dano:
    move $t9, $v0
    li $v0, 4
    la $a0, msg_dano
    syscall
    li $v0, 1
    move $a0, $t9
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    move $v0, $t9
    jr $ra

# ----------------------------------------------------------------
# MOTOR GRÁFICO ATUALIZADO (Resolução 256x256)
# ----------------------------------------------------------------
renderizar_tudo:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # 1. Limpar Tela
    # Céu: ocupa topo até linha 200 (de 256)
    desenhar_retangulo(0, 0, 256, 200, COR_CEU)
    # Chão: linha 200 até 256
    desenhar_retangulo(0, 200, 256, 56, COR_FUNDO)

    # 2. Desenhar Guerreiro
    # Posicionado no chão (Y=190 aprox)
    li $a0, 50             # X
    li $a1, 185            # Y
    la $a2, sprite_player
    jal desenhar_sprite_pro

    # 3. Desenhar Dragão
    # Posicionado no chão lado direito
    li $a0, 180            # X
    li $a1, 185            # Y
    la $a2, sprite_dragon
    jal desenhar_sprite_pro

    # 4. Barras de Vida (Aumentadas para resolução nova)
    # Barra Player
    lw $t0, playerHP
    div $t0, $t0, 2     # Escala (100 HP = 50 pixels)
    mflo $a2
    blez $a2, skip_hp_player
    li $a0, 50
    li $a1, 175
    li $v1, 4           # Altura 4 pixels
    lw $a3, COR_HP_CHEIO
    jal func_desenhar_rect
    skip_hp_player:

    # Barra Dragão
    lw $t0, monsterHP
    div $t0, $t0, 2
    mflo $a2
    blez $a2, skip_hp_monster
    li $a0, 180
    li $a1, 175
    li $v1, 4
    lw $a3, COR_HP_CHEIO
    jal func_desenhar_rect
    skip_hp_monster:

    # 5. Cursor
    lw $t0, turno
    beq $t0, 1, cursor_dragao
    desenhar_retangulo(60, 160, 10, 5, COR_CURSOR) # Perto do player
    j fim_render
    cursor_dragao:
    desenhar_retangulo(190, 160, 10, 5, COR_CURSOR) # Perto do dragão

fim_render:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# FUNÇÃO: DESENHAR SPRITE PRO (Unit Width 1 -> 256 colunas)
# ----------------------------------------------------------------
desenhar_sprite_pro:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t3, 0($a2)       # Largura
    lw $t4, 4($a2)       # Altura
    addi $a2, $a2, 8     # Pula cabeçalho

    move $t0, $a0        # X
    move $t1, $a1        # Y
    move $t8, $t3        # Salva largura

loop_pro_y:
    blez $t4, fim_sprite_pro
    move $t0, $a0        # Reseta X
    move $t3, $t8        # Reseta contador largura

    loop_pro_x:
        blez $t3, prox_linha_pro
        
        lw $t5, 0($a2)   # Cor
        addi $a2, $a2, 4
        
        beqz $t5, skip_pixel_pro

        # --- CORREÇÃO FULL HD (Largura 256) ---
        # Formula: Base + (y * 256 + x) * 4
        # Dica: Multiplicar por 256 é igual a Shift Left 8 (2^8 = 256)
        
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

prox_linha_pro:
    addi $t1, $t1, 1
    addi $t4, $t4, -1
    j loop_pro_y

fim_sprite_pro:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------------------
# FUNÇÃO: RETANGULO (Unit Width 1 -> 256 colunas)
# ----------------------------------------------------------------
func_desenhar_rect:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
    move $t3, $v1
    move $t4, $a3

    loop_y_rect:
        blez $t3, fim_desenho_rect
        move $t0, $a0
        move $t2, $a2
        
        loop_x_rect:
            blez $t2, proxima_linha_rect
            
            # --- CORREÇÃO FULL HD (Largura 256) ---
            sll $t5, $t1, 8     # y * 256
            add $t5, $t5, $t0   # + x
            sll $t5, $t5, 2     # * 4
            li $t6, 0x10040000
            add $t5, $t5, $t6
            
            sw $t4, 0($t5)
            
            addi $t0, $t0, 1
            addi $t2, $t2, -1
            j loop_x_rect
            
        proxima_linha_rect:
        addi $t1, $t1, 1
        addi $t3, $t3, -1
        j loop_y_rect

    fim_desenho_rect:
    jr $ra

# ----------------------------------------------------------------
# FUNÇÃO: MOSTRAR STATUS DA BATALHA
# ----------------------------------------------------------------
mostrar_status:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Título
    li $v0, 4
    la $a0, msg_status
    syscall
    
    # Status do Jogador
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
    
    # Status do Dragão
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