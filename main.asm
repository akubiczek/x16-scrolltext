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

    .asciiz "                                           1234567890+ABC STRING PLUS! THIS WHAT I MEAN TO BE, GREAT, GREAT IDEA :)                                                                                "

default_irq_handler: .addr $0000

ADDRx_L = $9f20
ADDRx_M = $9f21
ADDRx_H = $9f22
VDATA_0 = $9f23

;     ldy #$00
; @outer_loop:
;     lda #$00
; @loop:
;     inc
;     cmp #$ff
;     bne @loop
;     iny
;     cpy #$0a
;     bne @outer_loop

.segment "CODE"

    jsr reset_text_pointer

    stz h_scroll
    stz should_shift

    jsr set_custom_irq_handler
    jsr copy_text_to_screen
    rts ; exit to basic

increase_text_pointer:
    lda message_pointer
    inc
    sta message_pointer
    bne @skip
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

scroll_text:
    lda h_scroll
    cmp #$08
    bne @skip
    lda #$ff
    sta should_shift
    rts
@skip:
    inc
    sta h_scroll
    sta $9F37
    rts

shift_characters:
    stz should_shift
    stz h_scroll
    jsr increase_text_pointer
    jsr copy_text_to_screen
    rts

set_custom_irq_handler:
    ; preserve_default_irq
    lda $0314
    sta default_irq_handler
    lda $0315
    sta default_irq_handler+1

    ; set my handler
    sei
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315

    ; set_interrupt_to_line_xxx:
    lda #$D6
    sta $9F28
    lda $9F26
    ora #%10000000
    sta $9F26

    ; enable_line_interrupt:
    lda $9F26
    ora #$02
    sta $9F26

    cli
    rts

custom_irq_handler:
    lda $9F27
    and #$02
    beq vsync_interrupt

    ; Whatever code you need to do
    ; on the line interrupt...

    lda int_line
    cmp #$ff
    beq odd_interrupt
    jsr scroll_text
    lda #$ff
    sta int_line
    ; set_interrupt_to_line_yyy:
    sei
    lda #$10
    sta $9F28
    lda $9F26
    ora #%10000000
    sta $9F26
    cli
    jmp skip12
odd_interrupt:
    stz int_line
    ; set_interrupt_to_line_xxx:
    lda #$D6
    sta $9F28
    lda $9F26
    ora #%10000000
    sta $9F26    
skip12:
    lda #$02
    sta $9F27
    ply
    plx
    pla
    rti

vsync_interrupt:
    lda $9F27
    and #$01
    beq irq_done

    ; Whatever code your program
    ; wanted to execute...        
    ; stz $9F37

    lda should_shift
    cmp #$ff
    bne @skip
    jsr shift_characters
    

@skip:
    lda #$01
    sta $9F27
irq_done:   
    ply
    plx
    pla
    rti 
    jmp (default_irq_handler)
