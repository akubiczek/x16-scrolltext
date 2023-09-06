.segment "INIT"
.segment "ONCE"
.segment "ZEROPAGE"
irq_line:           .byte $00
check_count:        .byte $00

default_irq_handler: .addr $0000

ADDRx_L = $9f20
ADDRx_M = $9f21
ADDRx_H = $9f22
VDATA_0 = $9f23
H_SCROLL = $9F37


.macro wait_loop 
        ldy #$00
    @outer_loop:
        lda #$00
    @loop:
        inc
        cmp #$a0
        bne @loop
        iny
        cpy #$01
        bne @outer_loop
.endmacro

.macro print_accu
    ldx #$00
    stx ADDRx_L
    ldx #$b0
    stx ADDRx_M
    ldx #%00100001
    stx ADDRx_H
    sta VDATA_0
.endmacro

.segment "CODE"

    stz check_count
    ; preserve_default_irq  
    lda $0314
    sta default_irq_handler
    lda $0315
    sta default_irq_handler+1
    jsr set_custom_irq_handler
    rts ; exit to basic

set_custom_irq_handler:

    ; set my handler
    sei
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315

    ; set_interrupt_to_line_01D6:
    lda #$D6
    sta $9F28
    sta irq_line
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

    lda #$30
    sta H_SCROLL
    wait_loop
    stz H_SCROLL

    ; lda check_count
    ; inc
    ; sta check_count    
    ; cmp #$02
    ; bne skip_irq_change
    ; stz check_count

    lda irq_line
    cmp #$D6
    beq @set_50
    lda #$D6
    jmp @save_line
@set_50:
    lda #$00
@save_line:
    print_accu
    sta $9F28
    sta irq_line
    

skip_irq_change:
    lda #$02
    sta $9F27
    ply
    plx
    pla
    rti

vsync_interrupt:
    jmp (default_irq_handler)
