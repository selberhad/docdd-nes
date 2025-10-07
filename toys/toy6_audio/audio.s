; audio - NES ROM skeleton

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

    ; Initialize APU
    JSR init_apu

    ; Play 440 Hz tone (A note)
    ; Period = 111860.8 / 440 - 1 = 253
    LDA #<253
    STA $4002        ; Period low byte
    LDA #>253
    STA $4003        ; Period high byte
    LDA #%10111111   ; 50% duty, max volume
    STA $4000

loop:
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
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
