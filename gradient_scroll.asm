.include "vera.inc"
.include "macros.asm"
.include "vera_macros.asm"

.segment "INIT"
.segment "ONCE"
.segment "ZEROPAGE"
message_pointer:        .addr $0000
h_scroll:               .byte $00
scanline_wave_index:    .byte $00

.segment "DATA"
scanline_wave:
    ; .byte $08,$09,$0a,$0c,$0d,$0e,$0e,$0f,$0f,$0f,$0e,$0e,$0d,$0c,$0a,$09,$08,$06,$05,$03,$02,$01,$01,$00,$00,$00,$01,$01,$02,$03,$05,$06
    .byte 214,214,215,215,216,216,218,218,219,219,220,220,220,220,221,221,221,221,221,221,220,220,220,220,219,219,218,218,216,216,215,215,214,214,212,212,211,211,209,209,208,208,207,207,207,207,206,206,206,206,206,206,207,207,207,207,208,208,209,209,211,211,212,212

message:
    .repeat $20, i
        .charmap $41 + i, $41 + i - $40
    .endrepeat

    .asciiz "                                           A TOURIST IN A DREAM. A VISITOR IT SEEMS. A HALF FORGOTTEN SONG.                                     "

default_irq_handler: .addr $0000

SCROLL_STEP = $02 ; number of characters (must be even number)
IRQ_LINE = $D6-$08

.segment "CODE"

    jsr reset_text_pointer
    stz scanline_wave_index
    jsr setup_layer1
    jsr set_colors_of_offscreen_chars
    jsr copy_text_to_screen
    stz h_scroll
    jsr set_custom_irq_handler
    rts ; exit to basic

; ----------------------------------------------- ;
set_custom_irq_handler:
    sei

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
    
    macro_vera_scale_2x
    
    ldy scanline_wave_index
    iny
    sty scanline_wave_index
    cpy #$1F*2
    bne @skip
    stz scanline_wave_index
@skip:    
    lda scanline_wave, y
    macro_vera_wait_for_line_acc

    macro_vera_show_layer0

    lda #%00000010 ; clear LINE interrupt status
    sta VERA::ISR

    ; swap interrupt to another line
    set_line_int $DF, $01

    rti2


; ----------------------------------------------- ;
odd_interrupt:
    stz VERA::L1_HSCROLL_L ; reset screen scroll
    stz VERA::L0_HSCROLL_L

    macro_vera_scale_1x
    macro_vera_show_layer1

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
    stz VERA::L0_HSCROLL_L

    rts
@skip:
    inc
    sta h_scroll
    ; ldy h_scale_index
    ; .repeat 16
    ; iny
    ; .endrepeat
    ; adc (h_scale_pointer), y
    sta VERA::L1_HSCROLL_L ;scroll screen 
    sta VERA::L0_HSCROLL_L

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
    ; first configure address for VRAM Data port 0
    lda VERA::CTRL
    and #%11111110
    sta VERA::CTRL

    lda #$00
    sta VERA::ADDRx_L
    lda #$ea
    sta VERA::ADDRx_M
    lda #%00100001
    sta VERA::ADDRx_H

    ; now configure address for VRAM Data port 1
    lda VERA::CTRL
    ora #%00000001
    sta VERA::CTRL

    lda #$00
    sta VERA::ADDRx_L
    lda #$ec
    sta VERA::ADDRx_M
    lda #%00100001
    sta VERA::ADDRx_H    

    ldy #$00
loop:
    lda (message_pointer),y
    cmp #$00
    beq reset_text_pointer
    sta VERA::DATA0
    sta VERA::DATA1
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
    lda VERA::CTRL
    and #%11111110
    sta VERA::CTRL

    lda #$01
    sta VERA::ADDRx_L
    lda #$EC
    sta VERA::ADDRx_M
    lda #%00100001
    sta VERA::ADDRx_H
    lda #%01100011 ; white char on blue background

    ldy #$00
@loop:
    sta VERA::DATA0
    iny
    cpy #80
    bne @loop    

    rts

; ----------------------------------------------- ;
; layer0 shoud be copy of the layer1 but shifted 1 line in memory
setup_layer1:
    lda VERA::L1_CONFIG
    sta VERA::L0_CONFIG
    lda VERA::L1_MAPBASE
    inc ; shift memory address by 2 lines (512 bytes)
    sta VERA::L0_MAPBASE
    lda VERA::L1_TILEBASE
    sta VERA::L0_TILEBASE

    rts
