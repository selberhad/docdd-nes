; buffer - VRAM Buffer System (toy8)
; Tests queue + flush pattern for nametable updates during vblank

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "ZEROPAGE"
temp:       .res 1

.segment "CODE"

; Buffer structure in RAM $0300-$032F
; $0300:       buffer_count (0-16)
; $0301-$0303: Entry 0 (addr_hi, addr_lo, tile_value)
; $0304-$0306: Entry 1 (addr_hi, addr_lo, tile_value)
; ...
; $032E-$0330: Entry 15 (addr_hi, addr_lo, tile_value)

BUFFER_COUNT = $0300
BUFFER_DATA  = $0301
MAX_ENTRIES  = 16

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    INX  ; X = 0
    STX $2000  ; PPUCTRL = 0
    STX $2001  ; PPUMASK = 0
    BIT $2002  ; Clear vblank

    ; Initialize buffer
    LDA #0
    STA BUFFER_COUNT

    ; Wait 2 vblanks
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Enable NMI
    LDA #%10000000
    STA $2000

    JMP main

main:
    JMP main

nmi_handler:
    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
