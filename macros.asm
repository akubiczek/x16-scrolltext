; set interrupt to line LINE
.macro  set_line_int LINE_L, LINE_H
    lda #LINE_L
    sta $9F28 ;IRQLINE_L (Write only)
    
    lda VERA::IEN
    .if (LINE_H > 0)
    ora #%10000000      
    .else
    and #%01111111
    .endif
    sta VERA::IEN  ;IRQLINE_H (bit 8)

.endmacro

; do nothing for #CYCLES cycles
.macro super_nop CYCLES
    lda #$00    ; 2 cycles
:   inc         ; 2 cycles
    cmp #CYCLES / 4 ; 2 cycles
    bne :-      ; 2 + 1 cycles
.endmacro

.macro set_line_color COLOR
    ; configure VRAM access with auto increment (step=2)
    lda #$01
    sta VERA::ADDRx_L
    lda #$EB
    sta VERA::ADDRx_M
    lda #%00100001
    sta VERA::ADDRx_H

    lda #COLOR
    ldy #$00
:
    sta VERA::DATA0
    iny
    cpy #80+SCROLL_STEP ; text line length
    bne :-
.endmacro

; return from interrupt procedure to basic
.macro rti2b
    jmp (default_irq_handler)
.endmacro

; return from interrupt procedure
.macro rti2
    ply
    plx
    pla
    rti
.endmacro