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

    ; Initialize marker byte
    STX $0010           ; Marker = 0 (X still = 0)

    ; Clear vblank flag (unknown state at power-on)
    BIT $2002

    ; Wait for first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1     ; Loop while bit 7 = 0

    ; Set marker 1 (proves first vblank reached)
    LDA #$01
    STA $0010

    ; Wait for second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2     ; Loop while bit 7 = 0

    ; Set marker 2 (warmup complete)
    LDA #$02
    STA $0010

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
