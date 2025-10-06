; toy3_controller - Validate controller read pattern
; Tests: 3-step strobe + read, button state byte format

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode

    ; Initialize stack
    LDX #$FF
    TXS

    ; Disable PPU
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Initialize button state (NES doesn't zero RAM!)
    STX $0010           ; buttons = 0

    ; Clear vblank flag
    BIT $2002

    ; Wait first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1

    ; Wait second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; PPU ready, fall through to main loop

loop:
    ; TODO: Read controller
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CHARS"
    .res 8192, $00
