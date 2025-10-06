; nmi - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "CODE"

reset:
    ; CPU init
    SEI              ; Disable IRQ
    CLD              ; Clear decimal mode
    LDX #$FF
    TXS              ; Set up stack

    ; Clear RAM variables
    LDA #$00
    STA $0010        ; frame_counter = 0
    STA $0011        ; sprite_x = 0

    ; Disable rendering
    STA $2000        ; PPUCTRL = 0
    STA $2001        ; PPUMASK = 0
    BIT $2002        ; Clear vblank flag

    ; Wait 2 vblanks for PPU warmup
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Set up OAM sprite (Y, tile, attr, X)
    LDA #$78         ; Y = 120
    STA $0200
    LDA #$00         ; Tile = 0
    STA $0201
    LDA #$00         ; Attributes = 0
    STA $0202
    LDA #$00         ; X = 0 (will be updated by NMI)
    STA $0203

    ; Enable NMI
    LDA #%10000000   ; NMI enable (bit 7)
    STA $2000

    ; Main loop - all work in NMI
loop:
    JMP loop

nmi_handler:
    ; Increment frame counter
    INC $0010

    ; Update sprite X position
    INC $0011
    LDA $0011
    STA $0203        ; OAM byte 3 (X position)

    ; Upload OAM via DMA
    LDA #$02
    STA $4014

    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
