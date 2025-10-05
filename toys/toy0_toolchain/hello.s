; Minimal NES ROM - Toolchain Validation (toy0)
; Assembles with ca65, links with ld65 using custom nes.cfg
;
; ca65 syntax notes (vs asm6f used in wiki examples):
; - .segment "NAME" instead of .org $ADDRESS
; - .word instead of .dw (16-bit values)
; - .byte instead of .db (8-bit values)
; - .res instead of .dsb (reserve bytes)
; - Linker maps segments to addresses via nes.cfg

; =============================================================================
; HEADER Segment - iNES header (16 bytes)
; =============================================================================
.segment "HEADER"
    .byte "NES", $1A    ; iNES magic bytes (NES<EOF>)
    .byte $01           ; 1x 16KB PRG-ROM bank
    .byte $01           ; 1x 8KB CHR-ROM bank
    .byte $00           ; Mapper 0 (NROM), horizontal mirroring
    .byte $00           ; Mapper 0 upper nibble, no special features
    .res 8, $00         ; Padding (unused iNES 1.0 bytes)

; =============================================================================
; CODE Segment - Main program code (loads to $8000-$FFF9 via nes.cfg)
; =============================================================================
.segment "CODE"

reset:
    SEI                 ; Disable interrupts (Set Interrupt disable)
    CLD                 ; Clear decimal mode (not used on NES, but good practice)
loop:
    JMP loop            ; Infinite loop - ROM does nothing but not crash

nmi_handler:            ; NMI (vblank) - unused in this minimal ROM
irq_handler:            ; IRQ/BRK - unused in this minimal ROM
    RTI                 ; Return from interrupt

; =============================================================================
; VECTORS Segment - Hardware interrupt vectors (loads to $FFFA-$FFFF)
; =============================================================================
.segment "VECTORS"
    .word nmi_handler   ; $FFFA-$FFFB: NMI vector (vblank interrupt)
    .word reset         ; $FFFC-$FFFD: RESET vector (power-on/reset)
    .word irq_handler   ; $FFFE-$FFFF: IRQ/BRK vector (not used on NES typically)

; =============================================================================
; CHARS Segment - CHR-ROM graphics data (loads to CHR ROM space)
; =============================================================================
.segment "CHARS"
    .res 8192, $00      ; 8KB of zeroes (empty CHR-ROM, no graphics needed)
                        ; Stock nes.cfg expects 8KB CHR, even if unused
