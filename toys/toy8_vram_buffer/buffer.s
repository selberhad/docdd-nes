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
    ; Queue tile 1: (1,1) = $2021 = $10
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue1
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX
    LDA #$20
    STA BUFFER_DATA,X
    LDA #$21
    STA BUFFER_DATA+1,X
    LDA #$10
    STA BUFFER_DATA+2,X
    INC BUFFER_COUNT

skip_queue1:
    ; Queue tile 2: (15,10) = $214F = $20
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue2
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX
    LDA #$21
    STA BUFFER_DATA,X
    LDA #$4F
    STA BUFFER_DATA+1,X
    LDA #$20
    STA BUFFER_DATA+2,X
    INC BUFFER_COUNT

skip_queue2:
    ; Queue tile 3: (0,0) = $2000 = $30
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue3
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX
    LDA #$20
    STA BUFFER_DATA,X
    LDA #$00
    STA BUFFER_DATA+1,X
    LDA #$30
    STA BUFFER_DATA+2,X
    INC BUFFER_COUNT

skip_queue3:
    ; Queue tile 4: (31,29) = $23BF = $40
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue4
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX
    LDA #$23
    STA BUFFER_DATA,X
    LDA #$BF
    STA BUFFER_DATA+1,X
    LDA #$40
    STA BUFFER_DATA+2,X
    INC BUFFER_COUNT

skip_queue4:
    ; Queue tile 5: (10,5) = $20AA = $50
    LDX BUFFER_COUNT
    CPX #MAX_ENTRIES
    BCS skip_queue5
    TXA
    ASL
    STA temp
    TXA
    CLC
    ADC temp
    TAX
    LDA #$20
    STA BUFFER_DATA,X
    LDA #$AA
    STA BUFFER_DATA+1,X
    LDA #$50
    STA BUFFER_DATA+2,X
    INC BUFFER_COUNT

skip_queue5:
    JMP skip_queue5          ; Infinite loop

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
