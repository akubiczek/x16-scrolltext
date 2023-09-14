; ustawia layer1 na taki sam jak layer0 i go włącza
10 POKE $9F2D, PEEK ($9F34)
20 POKE $9F2E, PEEK ($9F35)
30 POKE $9F2F, PEEK ($9F36)
50 POKE $9F29, %00010001 : REM włącz wyświetlanie layer0 zamiast layer1


    lda #$A1
    sta VERA::ADDRx_L
    lda #$EB
    sta VERA::ADDRx_M
    lda #%00000001
    sta VERA::ADDRx_H
    lda #%01100001 ; white char on blue background
    sta VERA::DATA0


10 POKE $9F20, $00 : REM ADDRXL
20 POKE $9F21, $B0 : REM ADDRXM
30 POKE $9F22, PEEK ($9F22) OR %00000001 : REM ADDRXH
40 POKE $9F23, 32 : REM ZAPIS LICZBY DO DATA0