.include "vera.inc"
.include "macros.asm"

.segment "INIT"
.segment "ONCE"
.segment "ZEROPAGE"
message_pointer:    .addr $0000
h_scroll:           .byte $00

.segment "DATA"
message:
    .repeat $20, i
        .charmap $41 + i, $41 + i - $40
    .endrepeat

    .asciiz "                                                                              THIS IS NOT COMMODORE 64, THIS IS COMMANDER X16. MODERN, YET 8-BIT COMPUTER!                                                                                "

default_irq_handler: .addr $0000

SCROLL_STEP = $02 ; number of characters (must be even number)
IRQ_LINE = $D6

.segment "CODE"

    jsr reset_text_pointer
    jsr set_colors_of_offscreen_chars
    jsr copy_text_to_screen
    stz h_scroll
    jsr set_custom_irq_handler
    rts ; exit to basic

; ----------------------------------------------- ;
set_custom_irq_handler:
    sei

    ; preserve_default_irq
    lda $0314
    sta default_irq_handler
    lda $0315
    sta default_irq_handler+1    

    ; set my handler
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315

    ; enable LINE and VSYNC interrupt
    lda #%00000010 ; set LINE and VSYNC bits in IEN register
    sta VERA::IEN    

    ; set interrupt to line $1D6
    set_line_int IRQ_LINE, $01

    cli
    rts

; ----------------------------------------------- ;
custom_irq_handler:
    lda VERA::SCANLINE_L
    cmp #IRQ_LINE
    bne odd_interrupt ; branch if it's not the line $1D6 

    jsr scroll_text

    lda #%00000010 ; clear LINE interrupt status
    sta VERA::ISR

    ; swap interrupt to another line
    set_line_int $DF, $01

    jmp (default_irq_handler)


; ----------------------------------------------- ;
odd_interrupt:
    lda #$00
    stz VERA::L1_HSCROLL_L ; reset screen scroll

    lda h_scroll
    cmp #$08 * SCROLL_STEP
    bne @skip_shift_chars

    jsr shift_characters

@skip_shift_chars:

    lda #%00000010 ; clear LINE interrupt status
    sta VERA::ISR

    ; swap interrupt to another line
    set_line_int IRQ_LINE, $01

    rti2 ; return from interrupt procedure


; ----------------------------------------------- ;
scroll_text:
    lda h_scroll
    cmp #$08 * SCROLL_STEP
    bne @skip
    stz h_scroll
    stz VERA::L1_HSCROLL_L
    rts
@skip:
    inc
    inc
    sta h_scroll
    sta VERA::L1_HSCROLL_L ;scroll screen 
    rts


; ----------------------------------------------- ;
; shifts characters by one to the left
shift_characters:
    jsr increase_text_pointer
    jsr copy_text_to_screen
    rts

increase_text_pointer:
    .repeat SCROLL_STEP
    inc message_pointer
    .endrepeat
    bne @skip
    inc message_pointer+1
@skip:    
    rts


; ----------------------------------------------- ;
copy_text_to_screen:

    ; configure VRAM access with auto increment (step=2)
    lda #$00
    sta VERA::ADDRx_L
    lda #$eb
    sta VERA::ADDRx_M
    lda #%00100001
    sta VERA::ADDRx_H

    ldy #$00
loop:
    lda (message_pointer),y
    cmp #$00
    beq reset_text_pointer
    sta VERA::DATA0
    iny
    cpy #80+SCROLL_STEP ; text line length
    bne loop
end:    
    rts


; ----------------------------------------------- ;
reset_text_pointer:
    ; set pointer to point the beggining of the message
    lda #<message
    sta message_pointer
    lda #>message
    sta message_pointer+1    
    rts


; ----------------------------------------------- ;
set_colors_of_offscreen_chars:
    lda #$A1
    sta VERA::ADDRx_L
    lda #$EB
    sta VERA::ADDRx_M
    lda #%00000001
    sta VERA::ADDRx_H
    lda #%01100001 ; white char on blue background
    sta VERA::DATA0

    lda #$A3
    sta VERA::ADDRx_L
    lda #$EB
    sta VERA::ADDRx_M
    lda #%00000001
    sta VERA::ADDRx_H
    lda #%01100001 ; white char on blue background
    sta VERA::DATA0

    rts