; overflow - VRAM Buffer Overflow Test (toy8 Step 5)
; Tests buffer overflow: queue 20 tiles, only 16 should be accepted

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "ZEROPAGE"
temp:       .res 1
tile_count: .res 1

.segment "CODE"

; Buffer structure in RAM $0300-$0330
BUFFER_COUNT = $0300
BUFFER_DATA  = $0301
MAX_ENTRIES  = 16          ; Test overflow at 16 entries

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
    ; Queue 20 tiles in row 0 (cols 0-19)
    ; Tiles: $01, $02, $03, ..., $14
    ; Expected: First 16 queue, last 4 drop

    LDY #0                  ; Y = column counter (0-19)
    STY tile_count

queue_loop:
    ; Check buffer capacity
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue          ; Full, skip

    ; Calculate buffer offset: count * 3
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX

    ; Calculate PPU address: $2000 + column
    ; addr_hi = $20
    LDA #$20
    STA BUFFER_DATA,X

    ; addr_lo = column
    TYA
    STA BUFFER_DATA+1,X

    ; Tile value = column + 1
    TYA
    CLC
    ADC #$01
    STA BUFFER_DATA+2,X

    ; Increment buffer count
    INC BUFFER_COUNT

skip_queue:
    ; Track total queued attempts
    INC tile_count

    ; Next column
    INY
    CPY #20
    BNE queue_loop

infinite:
    JMP infinite

; flush_buffer: Write all queued tiles to nametable during vblank
flush_buffer:
    LDX BUFFER_COUNT
    BEQ flush_done

    LDY #0                  ; Buffer offset

flush_loop:
    ; Set PPUADDR
    BIT $2002               ; Reset latch
    LDA BUFFER_DATA,Y       ; addr_hi
    STA $2006
    INY
    LDA BUFFER_DATA,Y       ; addr_lo
    STA $2006
    INY

    ; Write tile
    LDA BUFFER_DATA,Y       ; tile value
    STA $2007
    INY

    DEX
    BNE flush_loop

    ; Clear buffer
    LDA #0
    STA BUFFER_COUNT

flush_done:
    RTS

nmi_handler:
    JSR flush_buffer
    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
