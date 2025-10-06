; toy1_sprite_dma - Validate OAM DMA mechanism
; Tests: Shadow OAM ($0200) → PPU OAM via $4014

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI
    CLD

    ; Initialize sprite 0 in shadow OAM ($0200-$0203)
    LDA #100        ; Y position
    STA $0200
    LDA #$42        ; Tile number
    STA $0201
    LDA #$01        ; Attributes
    STA $0202
    LDA #80         ; X position
    STA $0203

    ; Sprite 1
    LDA #110
    STA $0204
    LDA #$43
    STA $0205
    LDA #$02
    STA $0206
    LDA #90
    STA $0207

    ; Sprite 2
    LDA #120
    STA $0208
    LDA #$44
    STA $0209
    LDA #$03
    STA $020A
    LDA #100
    STA $020B

    ; Sprite 3
    LDA #130
    STA $020C
    LDA #$45
    STA $020D
    LDA #$00
    STA $020E
    LDA #110
    STA $020F

    ; Trigger OAM DMA
    LDA #$02        ; High byte of shadow OAM address
    STA $4014       ; Start DMA transfer
    ; CPU stalled for ~513 cycles during DMA

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CHARS"
    .res 8192, $00
