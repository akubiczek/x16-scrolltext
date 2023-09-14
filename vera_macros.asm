; wait until the LINE scanline is reached
.macro macro_vera_wait_for_line LINE
:   lda VERA::SCANLINE_L
    cmp #LINE
    bne :-
.endmacro

; wait until a scanline number stored in accumulator is reached
.macro macro_vera_wait_for_line_acc
:   cmp VERA::SCANLINE_L
    bne :-
.endmacro

; set display scaling
.macro macro_vera_scale_2x
    lda #$40 ; #64 - output 2 output pixels for every input pixel
    sta VERA::DC_HSCALE
    sta VERA::DC_VSCALE
.endmacro

; reset display scaling
.macro macro_vera_scale_1x
    lda #$80 ; #128 - no scale
    sta VERA::DC_HSCALE
    sta VERA::DC_VSCALE
.endmacro

.macro macro_vera_show_layer1
    lda #%00100001
    sta VERA::DC_VIDEO
.endmacro

.macro macro_vera_show_layer0
    lda #%00010001
    sta VERA::DC_VIDEO
.endmacro