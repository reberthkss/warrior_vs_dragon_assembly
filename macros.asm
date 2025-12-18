# ============================================
# MACROS.ASM - Global Macros
# ============================================
# This file contains all macros used throughout the game

.macro draw_rectangle(%x, %y, %w, %h, %color_label)
    li $a0, %x
    li $a1, %y
    li $a2, %w
    li $v1, %h
    lw $a3, %color_label
    jal func_draw_rect
.end_macro
