; palette - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "CODE"

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    INX  ; X = 0
    STX $2000  ; PPUCTRL = 0
    STX $2001  ; PPUMASK = 0
    BIT $2002  ; Clear vblank

    ; Wait 2 vblanks
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Write palette entries
    ; Set PPUADDR to $3F00 (backdrop color)
    BIT $2002       ; Reset PPUADDR latch
    LDA #$3F
    STA $2006       ; PPUADDR high byte
    LDA #$00
    STA $2006       ; PPUADDR low byte ($3F00)

    ; Write $0F to $3F00 (black)
    LDA #$0F
    STA $2007       ; PPUDATA writes to $3F00, auto-increments

    ; Write $30 to $3F01 (white) - auto-incremented from previous write
    LDA #$30
    STA $2007       ; PPUDATA writes to $3F01

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
