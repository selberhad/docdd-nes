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

    ; TODO: Add sprites 1-3
    ; TODO: Trigger DMA

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
