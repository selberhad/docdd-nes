# Timing and Interrupts

**Source**: Priority 2 NESdev Wiki pages (Cycle reference chart, Cycle counting, NMI thread, Interrupt forwarding)

Practical patterns for cycle budgeting, precise timing delays, NMI handler organization, and interrupt management.

---

## Cycle Reference (NTSC Focus)

### Key Timing Values

**NTSC (2C02) - Most Common**:
- **CPU speed**: 1.789773 MHz (~1.79 MHz)
- **Scanline**: 113⅔ CPU cycles (341 PPU dots ÷ 3)
- **HBlank**: 28⅓ CPU cycles (85 PPU dots ÷ 3)
- **Vblank duration**: 2273⅓ CPU cycles (20 scanlines)
- **Frame**: 29,780.5 CPU cycles (or 29,780⅔ if rendering disabled)
- **PPU dots per CPU cycle**: 3

**PAL (2C07)**:
- **CPU speed**: 1.662607 MHz (~1.66 MHz)
- **Scanline**: 106 9/16 CPU cycles (341 PPU dots ÷ 3.2)
- **Vblank duration**: 7459⅞ CPU cycles (70 scanlines)
- **Frame**: 33,247.5 CPU cycles
- **PPU dots per CPU cycle**: 3.2

**Dendy (PAL clone with NTSC-like timing)**:
- **CPU speed**: 1.773448 MHz
- **Scanline**: 113⅔ CPU cycles (same as NTSC)
- **Frame**: 35,464 CPU cycles

### OAM DMA Timing

**OAM DMA ($4014) always costs**:
- **513 cycles** if started on even CPU cycle
- **514 cycles** if started on odd CPU cycle (gets aligned)

**Pattern**: Budget 514 cycles for safety; DMA happens regardless of CPU alignment

---

## Cycle Counting Techniques

### Instruction Timing Rules of Thumb

1. **Minimum 2 cycles per instruction** (opcode fetch)
2. **+1 cycle per memory access** (operand fetch, read, write)
3. **+1 cycle for page crossing** on indexed reads (e.g., LDA abs,X)
4. **+1 cycle for read-modify-write** (ASL, INC, etc. - dummy write)
5. **+1 cycle for stack push** (PHA, PHP)
6. **+2 cycles for stack pull** (+1 to increment SP, +1 to read)

**Examples**:
```
NOP           = 2 cycles (opcode + wait)
LDA #$00      = 2 cycles (opcode + operand)
LDA $00       = 3 cycles (opcode + operand + read ZP)
STA $2000     = 4 cycles (opcode + 2-byte operand + write)
LDA $2000,X   = 4 cycles (5 if page crosses)
INC $00       = 5 cycles (opcode + operand + read + dummy write + write)
JSR           = 6 cycles (opcode + operand + 2 stack writes)
RTS           = 6 cycles (opcode + 2 stack reads + PC increment)
```

### Short Delay Patterns

**2-12 cycle delays** (no side effects):

```asm
; 2 cycles
  NOP

; 3 cycles
  BIT $00        ; Clobbers NVZ flags, reads ZP
  ; OR
  BCC *+2        ; Requires known carry state

; 4 cycles
  NOP
  NOP

; 5 cycles
  CLC            ; Or CLV
  BCC *+2        ; Or BVC

; 6 cycles
  NOP
  NOP
  NOP

; 7 cycles
  PHP
  PLP            ; Modifies 1 byte of stack

; 12 cycles
  JSR subroutine ; Followed immediately by RTS
  RTS
```

**Longer delays**: Use loop or lookup table

```asm
; Variable delay (5 + A*5 cycles)
delay_5a:
  sec
delay_loop:
  sbc #1
  bcs delay_loop
  rts

; Exact 100-cycle delay
  lda #19        ; 2 cycles
  jsr delay_5a   ; 5 + 19*5 = 100 cycles
```

### Clockslide Technique

**Concept**: Delay by exact cycle count based on entry point (odd/even address)

**Pattern**:
```asm
; CMP-based clockslide
clockslide:
  .byte $C9, $C9, $C9, $C9, $C5, $EA

; Disassembled from even address:
;   CMP #$C9  (2 cycles)
;   CMP #$C9  (2 cycles)
;   CMP $EA   (3 cycles)
;   Total: 7 cycles, 6 bytes

; Disassembled from odd address (entry +1):
;   CMP #$C9  (2 cycles)
;   CMP #$C5  (2 cycles)
;   NOP       (2 cycles)
;   Total: 6 cycles, 5 bytes
```

**Usage**: Use with RTS trick or indirect jump to enter at precise address

```asm
; Delay by (A) cycles
variable_delay:
  clc
  adc #<clockslide_table
  sta jump_addr+1
  lda #>clockslide_table
  sta jump_addr+2
jump_addr:
  jmp $0000        ; Self-modified to clockslide entry point
```

---

## NMI Handler Patterns

### Three Main Game Loop Organizations

#### 1. Main Only (Simplest)

**Pattern**: Game logic in main loop; NMI only sets flag

```asm
nmi_handler:
  inc nmi_flag   ; Signal vblank occurred
  rti

main_loop:
  lda nmi_flag
  beq main_loop  ; Wait for NMI
  lda #0
  sta nmi_flag

  ; Update game logic
  jsr update_player
  jsr update_enemies

  ; Upload to PPU
  lda #$02
  sta $4014      ; OAM DMA

  jmp main_loop
```

**Pros**: Simple; easy to debug
**Cons**: If logic exceeds 1 frame, music slows down; sprite 0 split can fail

#### 2. NMI Only (Super Mario Bros. Style)

**Pattern**: All logic inside NMI; main loop does nothing

```asm
nmi_handler:
  ; OAM DMA
  lda #$02
  sta $4014

  ; Music
  jsr play_music

  ; Read controller
  jsr read_controller

  ; Game logic
  jsr update_player
  jsr update_enemies
  jsr update_camera

  rti

main_loop:
  jmp main_loop  ; Infinite loop; all work in NMI
```

**Pros**: Consistent timing; music never slows
**Cons**: Must fit all logic in vblank (~2273 cycles); complex games can't fit

#### 3. NMI + Main (Recommended for Complex Games)

**Pattern**: PPU/APU updates in NMI; game logic in main loop

```asm
nmi_handler:
  ; Push registers
  pha
  txa
  pha
  tya
  pha

  ; Check if VRAM update ready
  lda vram_ready
  beq skip_vram

  ; Upload buffered data to PPU
  jsr upload_vram_buffer
  jsr upload_oam

  lda #0
  sta vram_ready

skip_vram:
  ; Set scroll
  lda scroll_x
  sta $2005
  lda scroll_y
  sta $2005

  ; Music
  jsr play_music

  ; (Optional) Sprite 0 hit wait
  jsr wait_sprite0_split

  ; Pull registers
  pla
  tay
  pla
  tax
  pla

  ; Signal NMI occurred
  inc nmi_flag

  rti

main_loop:
  ; Wait for NMI
  lda nmi_flag
  beq main_loop
  lda #0
  sta nmi_flag

  ; Game logic (can exceed 1 frame)
  jsr update_game_state

  ; Prepare VRAM updates in buffer
  jsr prepare_vram_updates

  ; Signal ready for NMI upload
  lda #1
  sta vram_ready

  jmp main_loop
```

**Pros**: Music timing consistent; game logic can exceed 1 frame; sprite 0 split rock-solid
**Cons**: More complex; requires double-buffering and flags

---

## NMI Handler Best Practices

### Priority Order (Critical First)

1. **OAM DMA** (513-514 cycles) - Must happen in vblank
2. **Scroll registers** (~20 cycles) - Must set before rendering starts
3. **VRAM updates** (variable) - Use remaining vblank budget
4. **Music** (~500-1000 cycles) - Can happen during rendering if needed
5. **Sprite 0 hit** (variable) - Wait mid-frame for split

### VRAM Update Budget

**NTSC vblank**: 2273 cycles total
- OAM DMA: 514 cycles
- Scroll/PPUCTRL: 20 cycles
- Music: ~500 cycles
- **Remaining for VRAM**: ~1239 cycles

**Cycle costs**:
- Set PPU address: 8 cycles (2x STA $2006)
- Write 1 byte: 4 cycles (STA $2007)
- Nametable update (30 tiles): 8 + 30*4 = 128 cycles

**Budget**: Can update ~10 nametable tiles OR 1 full column (30 tiles) per frame

### Protecting NMI Handler

**Problem**: If NMI occurs mid-game-logic, PPU state may be inconsistent

**Solution**: Disable NMI during critical sections

```asm
critical_section:
  lda $2000
  and #$7F         ; Clear NMI enable bit
  sta $2000

  ; Do time-sensitive work
  jsr update_mapper_banks

  lda $2000
  ora #$80         ; Re-enable NMI
  sta $2000
  rts
```

**CRITICAL**: Keep NMI disabled for minimum time; music timing suffers

---

## Dynamic NMI Handler (Self-Modifying Code)

### Switchable NMI Handlers

**Use case**: Different game states need different NMI behavior (title screen, gameplay, game over)

**Pattern**: Use trampoline in RAM

```asm
.segment "BSS"
nmi_trampoline: .res 3  ; JMP opcode + 2-byte address

.segment "CODE"

; Change NMI handler to new address in YX
change_nmi_handler:
  lda #$40         ; RTI opcode
  sta nmi_trampoline ; Temporarily disable (RTI immediately)

  stx nmi_trampoline+1 ; Low byte of new handler
  sty nmi_trampoline+2 ; High byte of new handler

  lda #$4C         ; JMP opcode
  sta nmi_trampoline ; Activate new handler

  rts

.segment "VECTORS"
  .addr nmi_trampoline, reset_handler, irq_trampoline
```

**Safety**: Writing RTI first ensures NMI can't jump to partial address if NMI occurs mid-update

**Usage**:
```asm
; Switch to title screen NMI handler
  ldx #<title_nmi
  ldy #>title_nmi
  jsr change_nmi_handler

; Switch to gameplay NMI handler
  ldx #<game_nmi
  ldy #>game_nmi
  jsr change_nmi_handler
```

---

## Interrupt Forwarding (Advanced)

### Use Case: RAM-Based Development

**Problem**: NMI/IRQ vectors in ROM can't be changed; need to update handlers without reflashing cartridge

**Solution**: Vectors point to RAM; ROM forwards interrupts to RAM handlers

### Famicom Disk System Protocol

```
NMI  → JMP ($DFF6 or $DFF8 or $DFFA) (based on $0100 control flag)
Reset → JMP ($DFFC) (if signature at $0102-$0103 matches)
IRQ  → JMP ($DFFE)
```

### Simplified Protocol (Blargg's Romless NES)

```
NMI  → JMP ($07FA)
Reset → JMP ($07FC)
IRQ  → JMP ($07FE)
```

**Implementation**:
```asm
.segment "VECTORS"
  .addr nmi_forward, reset_forward, irq_forward

nmi_forward:
  jmp ($07FA)

reset_forward:
  jmp ($07FC)

irq_forward:
  jmp ($07FE)

; In RAM ($0700-$07FF):
; $07FA-$07FB: Address of actual NMI handler
; $07FC-$07FD: Address of actual reset handler
; $07FE-$07FF: Address of actual IRQ handler
```

**Benefit**: Update handlers by writing to $07FA-$07FF; no ROM changes

---

## Timing-Critical Code Patterns

### Sprite 0 Hit + Scroll Change

**Use case**: Status bar with different scroll than playfield

```asm
nmi_handler:
  ; Set scroll for status bar
  lda #0
  sta $2005
  sta $2005

  ; Wait for sprite 0 hit (status bar bottom)
wait_sprite0:
  bit $2002
  bvs wait_sprite0

  ; Change scroll for playfield
  lda playfield_scroll_x
  sta $2005
  lda playfield_scroll_y
  sta $2005

  rti
```

**Cycle budget**: Sprite 0 hit occurs mid-frame; must complete scroll change before rendering resumes

### Cycle-Exact Music Playback

**Pattern**: Music engine runs at fixed interval (e.g., every 16 frames)

```asm
nmi_handler:
  inc music_timer
  lda music_timer
  cmp #16
  bne skip_music

  jsr update_music  ; Exactly every 16 frames

  lda #0
  sta music_timer

skip_music:
  rti
```

**Benefit**: Consistent music tempo regardless of frame drops

---

## Common Timing Pitfalls

### Pitfall 1: Assuming Frame Timing

**Problem**: NTSC frame is 29,780.5 cycles (0.5 varies per frame due to odd-frame skip)

**Solution**: Don't rely on exact cycle count across frames; use NMI for synchronization

### Pitfall 2: Ignoring PAL

**Problem**: Code tuned for NTSC runs 20% slower on PAL

**Solution**: Detect video standard at boot; scale timers/velocities accordingly

### Pitfall 3: NMI During Critical Code

**Problem**: NMI interrupts mapper bank switch → corrupted graphics

**Solution**: Disable NMI during bank switching or use mutex flag

```asm
switch_bank:
  lda #1
  sta bank_switch_mutex  ; Signal NMI to wait

  lda new_bank
  sta $8000              ; Mapper bank switch

  lda #0
  sta bank_switch_mutex  ; Release mutex

nmi_handler:
  lda bank_switch_mutex
  bne nmi_handler        ; Wait for mutex release
  ; Safe to access banked memory
```

### Pitfall 4: Forgetting PPU Warmup

**Problem**: Reading $2002 immediately after power-on → garbage

**Solution**: Wait ~30,000 cycles after reset before accessing PPU

```asm
reset:
  ; Wait for PPU warmup (2 frames)
  bit $2002
warmup1:
  bit $2002
  bpl warmup1

warmup2:
  bit $2002
  bpl warmup2

  ; Now safe to use PPU
```

---

## Key Takeaways

1. **Vblank budget is PRECIOUS** - 2273 cycles (NTSC) must cover OAM DMA, scroll, VRAM updates, music
2. **Cycle counting enables raster effects** - Sprite 0 hit, palette changes, scroll splits require exact timing
3. **NMI handler organization affects complexity** - Simple games: NMI only; complex games: NMI + main loop
4. **Interrupt forwarding enables rapid development** - Jump through RAM vectors to update handlers without ROM reflash
5. **PAL/NTSC differences matter** - Detect video standard; scale all timing-dependent code

## Reference Files

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Cycle_reference_chart](https://www.nesdev.org/wiki/Cycle_reference_chart)
- [Cycle_counting](https://www.nesdev.org/wiki/Cycle_counting)
- [NMI_thread](https://www.nesdev.org/wiki/NMI_thread)
- [Interrupt_forwarding](https://www.nesdev.org/wiki/Interrupt_forwarding)

