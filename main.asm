.segment "INIT"
.segment "ONCE"
.segment "ZEROPAGE"
message_pointer:    .addr $0000
h_scroll:           .byte $00
should_shift:       .byte $00
int_line:           .byte $00

.segment "DATA"
message:
    .repeat $20, i
        .charmap $41 + i, $41 + i - $40
    .endrepeat

    .asciiz "X   X                                      THIS IS NOT COMMODORE 64, THIS IS COMMANDER X16. MODERN, YET 8-BIT COMPUTER!                                                                            "

default_irq_handler: .addr $0000

ADDRx_L = $9f20
ADDRx_M = $9f21
ADDRx_H = $9f22
VDATA_0 = $9f23

.segment "CODE"

    jsr reset_text_pointer
    jsr copy_text_to_screen

    stz h_scroll
    stz should_shift

    jsr set_custom_irq_handler
    rts ; exit to basic

; ----------------------------------------------- ;
set_custom_irq_handler:
    ; set my handler
    sei
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315

    ; enable LINE and VSYNC interrupt
    lda #%00000011 ; set LINE and VSYNC bits in IEN register
    sta $9F26    

    ; set interrupt to line $1D6
    lda #$D6
    sta $9F28 ;IRQLINE_L (Write only)
    lda $9F26 
    ora #%10000000  
    sta $9F26 ;IRQLINE_H (bit 8)

    cli
    rts

; ----------------------------------------------- ;
custom_irq_handler:
    lda $9F27
    and #%00000001 ; sets zero-flag when bit 0 at $9F27 is cleared (not VSYNC interrupt)
    bne vsync_interrupt

    jsr scroll_text

    lda #%00000010 ; clear LINE interrupt status
    sta $9F27

    ply
    plx
    pla
    rti

; ----------------------------------------------- ;
vsync_interrupt:
    stz $9F37 ; reset H-SCROLL

    lda should_shift
    cmp #$ff
    bne @skip_shift_chars
    jsr shift_characters

@skip_shift_chars:

    lda #%00000001 ; clear VSYNC interrupt status
    sta $9F27

    ply
    plx
    pla
    rti 

scroll_text:
    lda h_scroll
    cmp #$08
    bne @skip
    lda #$ff
    sta should_shift
    stz h_scroll
    rts
@skip:
    inc
    sta h_scroll
    sta $9F37 ;scroll screen 
    rts

; shifts characters by one to the left, and resets h_scroll
shift_characters:
    stz should_shift
    jsr increase_text_pointer
    jsr copy_text_to_screen
    rts

increase_text_pointer:
    lda message_pointer
    inc
    sta message_pointer
    bne @skip ; goto @skip if message_pointer has not changed to $00
    lda message_pointer+1
    inc
    sta message_pointer+1
@skip:    
    rts

copy_text_to_screen:

    ; configure VRAM access with auto increment (step=2)
    lda #$02
    sta ADDRx_L
    lda #$eb
    sta ADDRx_M
    lda #%00100001
    sta ADDRx_H

    ldy #$00
loop:
    lda (message_pointer),y
    cmp #$00
    beq reset_text_pointer
    sta VDATA_0 
    iny
    cpy #80 ; text line length
    beq end
    jmp loop
end:    
    rts

reset_text_pointer:
    ; set pointer to point the beggining of the message
    lda #<message
    sta message_pointer
    lda #>message
    sta message_pointer+1
    rts