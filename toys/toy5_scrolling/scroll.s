; scroll - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "CODE"

reset:
    SEI              ; Disable IRQ
    CLD              ; Clear decimal mode
    LDX #$FF
    TXS              ; Set up stack

    ; Clear scroll variables
    LDA #$00
    STA $10          ; scroll_x = 0
    STA $11          ; scroll_y = 0

    ; Disable rendering
    STA $2000        ; PPUCTRL = 0
    STA $2001        ; PPUMASK = 0
    BIT $2002        ; Clear vblank flag

    ; Wait 2 vblanks for PPU warmup (toy2 pattern)
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Enable NMI
    LDA #%10000000   ; NMI enable (bit 7)
    STA $2000

    ; Main loop - Pattern 2: NMI only (all work in NMI)
loop:
    JMP loop

nmi_handler:
    ; Increment scroll position (auto-scroll right)
    INC $10          ; scroll_x += 1

    ; Reset PPU address latch
    BIT $2002

    ; Write PPUSCROLL (X, then Y)
    LDA $10          ; scroll_x
    STA $2005        ; PPUSCROLL X
    LDA $11          ; scroll_y (always 0)
    STA $2005        ; PPUSCROLL Y

    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
