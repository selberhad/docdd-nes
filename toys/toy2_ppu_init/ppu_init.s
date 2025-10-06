; toy2_ppu_init - Validate PPU 2-vblank warmup sequence
; Tests: PPUSTATUS polling, vblank wait loops

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode

    ; Initialize stack
    LDX #$FF
    TXS

    ; Disable PPU
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Clear vblank flag (unknown state at power-on)
    BIT $2002

    ; TODO: Wait first vblank
    ; TODO: Wait second vblank

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
