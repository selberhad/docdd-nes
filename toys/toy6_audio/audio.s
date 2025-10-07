; audio - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "ZEROPAGE"
frame_counter: .res 1

.segment "CODE"

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    INX  ; X = 0
    STX $2000  ; PPUCTRL = 0
    STX $2001  ; PPUMASK = 0
    STX frame_counter  ; Initialize frame counter
    BIT $2002  ; Clear vblank

    ; Wait 2 vblanks
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Initialize APU
    JSR init_apu

    ; Play 400 Hz tone initially
    ; Period = 111860.8 / 400 - 1 = 279
    LDA #<279
    STA $4002        ; Period low byte
    LDA #>279
    STA $4003        ; Period high byte
    LDA #%10111111   ; 50% duty, max volume
    STA $4000

    ; Enable NMI
    LDA #%10000000
    STA $2000

loop:
    ; Check if frame 11 reached (change AFTER frame 10)
    LDA frame_counter
    CMP #11
    BNE @skip_change

    ; Change to 800 Hz
    ; Period = 111860.8 / 800 - 1 = 139
    LDA #<139
    STA $4002
    LDA #>139
    STA $4003

@skip_change:
    JMP loop

; Initialize APU to known state (all channels silent)
; Based on learnings/audio.md
init_apu:
    ; Initialize $4000-$4013
    LDY #$13
@loop:
    LDA @regs,Y
    STA $4000,Y
    DEY
    BPL @loop

    LDA #$0F
    STA $4015    ; Enable all channels
    LDA #$40
    STA $4017    ; Disable IRQ
    RTS

@regs:
    .byte $30,$08,$00,$00  ; Pulse 1
    .byte $30,$08,$00,$00  ; Pulse 2
    .byte $80,$00,$00,$00  ; Triangle
    .byte $30,$00,$00,$00  ; Noise
    .byte $00,$00,$00,$00  ; DMC

nmi_handler:
    INC frame_counter
    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
