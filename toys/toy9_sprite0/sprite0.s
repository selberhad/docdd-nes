; sprite0.s - toy9_sprite0
; A minimal ROM to trigger a sprite 0 hit.

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $01, $00 ; 1x 16KB PRG, 1x 8KB CHR, mapper 0, vertical mirroring
    .res 8, $00

.segment "CODE"

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    ; Wait for PPU warmup
    BIT $2002
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; --- PPU Setup ---

    ; Clear RAM
    LDA #0
    LDX #0
clear_ram_loop:
    STA $0000,X
    STA $0100,X
    STA $0200,X
    STA $0300,X
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    INX
    BNE clear_ram_loop

    ; Load palettes
    LDA $2002 ; read PPU status to reset the PPU address latch
    LDA #$3F
    STA $2006 ; write the high byte of PPU address
    LDA #$00
    STA $2006 ; write the low byte of PPU address
    LDX #0
load_palette_loop:
    LDA palette,X
    STA $2007
    INX
    CPX #$20
    BNE load_palette_loop

    ; Write a solid tile to the entire nametable
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
    LDX #4
fill_loop:
    LDY #0
fill_inner:
    LDA #$01
    STA $2007
    INY
    BNE fill_inner
    DEX
    BNE fill_loop

    ; --- Sprite Setup ---

    ; Place sprite 0 at Y=47, X=64
    ; This will overlap with our background tile
    LDA #47
    STA $0200 ; Sprite 0 Y
    LDA #$02
    STA $0201 ; Sprite 0 tile
    LDA #$00
    STA $0202 ; Sprite 0 attributes (palette 0)
    LDA #64
    STA $0203 ; Sprite 0 X

    ; OAM DMA will happen in NMI

    ; Enable rendering
    LDA #%10010000 ; Enable NMI, sprites from $0000, background from $1000
    STA $2000
    LDA #%00011110 ; Enable sprites and background
    STA $2001

    JMP infinite_loop

infinite_loop:
    JMP infinite_loop

nmi_handler:
    ; OAM DMA
    LDA #$00
    STA $2003 ; Set OAM address to 0
    LDA #$02
    STA $4014 ; DMA from $0200
    RTI

irq_handler:
    RTI

; --- Data ---

palette:
    .byte $0F, $01, $11, $21 ; Background palette 0
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $16, $27, $18 ; Sprite palette 0
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    ; Tile 0: Empty
    .res 16, $00
    ; Tile 1: Solid block (for background)
    .res 16, $FF
    ; Tile 2: Solid block (for sprite)
    .res 16, $FF