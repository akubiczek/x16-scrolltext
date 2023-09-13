.include "vera.inc"
.include "macros.asm"

.segment "ONCE"
.segment "CODE"

    jsr set_custom_irq_handler
    rts

; ----------------------------------------------- ;
set_custom_irq_handler:
    sei

    ; set my handler
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315

    ; enable LINE interrupt
    lda #%00000010 ; set LINE bits in IEN register
    sta VERA::IEN    

    ; set interrupt to line $1D6
    set_line_int $D6, $01

    cli
    rts

; ----------------------------------------------- ;
custom_irq_handler:
    lda VERA::SCANLINE_L
    cmp #$D6 
    bne odd_interrupt ; branch if it's not the line $1D6 

    lda #$0F
    sta VERA::L1_HSCROLL_L ; scroll screen 16 pixels left 

    lda #%00000010 ; clear LINE interrupt status
    sta $9F27

    ; swap interrupt to another line
    set_line_int $00, $00

    ply
    plx
    pla
    rti

; ----------------------------------------------- ;
odd_interrupt:
    stz VERA::L1_HSCROLL_L ; reset screen scroll

    lda #%00000010 ; clear LINE interrupt status
    sta $9F27

    ; bring interrupt back to line $1D6
    set_line_int $D6, $01

    ply
    plx
    pla
    rti