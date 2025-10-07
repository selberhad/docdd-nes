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

    ; Write palette entries to test multiple scenarios

    ; Test 1: Basic write + backdrop mirroring
    ; Write to $3F10 (sprite pal 0, entry 0) - should mirror to $3F00
    BIT $2002       ; Reset PPUADDR latch
    LDA #$3F
    STA $2006       ; PPUADDR high byte
    LDA #$10
    STA $2006       ; PPUADDR low byte ($3F10)
    LDA #$2D        ; Green
    STA $2007       ; Writes to $3F10, mirrors to $3F00

    ; Test 2: Unused entry mirroring
    ; Write to $3F04 (BG pal 1, entry 0 - unused) - should mirror to $3F00
    BIT $2002       ; Reset PPUADDR latch
    LDA #$3F
    STA $2006
    LDA #$04
    STA $2006       ; PPUADDR = $3F04
    LDA #$16        ; Blue
    STA $2007       ; Writes to $3F04, should mirror to $3F00

    ; Test 3: Region mirroring
    ; Write to $3F01 - will be readable at $3F21, $3F41, etc.
    BIT $2002
    LDA #$3F
    STA $2006
    LDA #$01
    STA $2006       ; PPUADDR = $3F01
    LDA #$30        ; White
    STA $2007       ; Writes to $3F01

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
