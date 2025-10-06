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

    ; Debug marker 1: Reset entered
    LDA #$01
    STA $0012

    ; Disable PPU
    LDX #$00
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Initialize button state (NES doesn't zero RAM!)
    STX $0010           ; buttons = 0
    STX $0011           ; loop counter = 0

    ; Debug marker 2: PPU disabled
    LDA #$02
    STA $0012

    ; Clear vblank flag
    BIT $2002

    ; Debug marker 3: Starting vblank wait 1
    LDA #$03
    STA $0012

    ; Wait first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1

    ; Debug marker 4: Vblank 1 done
    LDA #$04
    STA $0012

    ; Wait second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; Debug marker 5: Vblank 2 done, entering loop
    LDA #$05
    STA $0012

    ; PPU ready, fall through to main loop

loop:
    ; Debug: increment frame counter to prove loop is running
    INC $0011           ; $0011 = loop iteration counter

    JSR read_controller1
    JMP loop

read_controller1:
    ; Step 1: Strobe controller
    LDA #$01
    STA $4016           ; Start strobe
    LDA #$00
    STA $4016           ; End strobe (latches state)

    ; Clear button byte before reading
    STA $0010           ; A still = 0 from above

    ; Step 2: Read 8 buttons
    LDX #$08            ; 8 buttons to read
read_loop:
    LDA $4016           ; Read bit 0
    LSR                 ; Shift bit 0 to carry
    ROL $0010           ; Rotate carry into buttons
    DEX
    BNE read_loop

    RTS

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CHARS"
    .res 8192, $00
