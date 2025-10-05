# Mappers — ROM Expansion & Bank Switching

Mappers extend the NES beyond its base 32KB PRG-ROM + 8KB CHR limitations. They add hardware bank switching to access larger ROMs and enable CHR-RAM for dynamic graphics.

---

## Why Mappers Exist

### Base NES Address Space Limits

**Without mapper** (NROM — Mapper 0):
- **PRG-ROM**: 32KB max ($8000-$FFFF)
  - 16KB variant: $C000-$FFFF (mirrors $8000-$BFFF)
- **CHR-ROM/RAM**: 8KB max ($0000-$1FFF in PPU space)

**Problem**: Complex games need more:
- Large games (Super Mario Bros. 3: 384KB PRG)
- Multiple tilesets (different worlds/levels)
- Dynamic graphics (status bars, animations, text rendering)

**Solution**: Mappers add **bank switching** hardware to cartridge.

---

## CHR-ROM vs CHR-RAM Decision

Mappers can provide either **CHR-ROM** (fixed tiles, bank switched) or **CHR-RAM** (CPU-writable tiles). This is a critical early decision.

### CHR-ROM (Fixed Tile Data)

**How it works**: Mapper switches which ROM bank the PPU sees at $0000-$1FFF.

**Advantages**:
- **Fast switching**: No vblank time needed (just write to mapper register)
- **Mid-frame switching**: Can change tiles during rendering (for raster effects)
- **Simpler init**: Tiles available immediately at power-on
- **Common hardware**: Most donor carts have CHR-ROM

**Applications**:
1. **Large static screens**: Title screens >8KB (e.g., Smash TV)
2. **Status bar separation**: Dedicated tileset for HUD (Super Mario Bros. 3)
3. **Artifact blanking**: Hide scrolling seams with blank tiles (Jurassic Park)
4. **Pseudo-3D**: Floor textures per scanline (Cosmic Epsilon)

**Limitation**: Can't create tiles at runtime (no CPU writes to CHR memory).

### CHR-RAM (Dynamic Tile Data)

**How it works**: CPU writes tile data to PPU via $2006/$2007 (or DMA on some mappers).

**Advantages**:
- **Fine-grained control**: Switch individual tiles, not whole banks
- **Compression**: Store compressed tiles in PRG-ROM, decompress to CHR-RAM
- **Runtime generation**:
  - Compositing (Hatris, Cocoron)
  - Variable-width fonts (VWF in RPGs)
  - Drawing programs (Videomation)
  - Vector graphics (Qix, Elite)
- **Flexible juxtaposition**: Any character + any enemy (Final Fantasy)
- **One chip**: No separate CHR-ROM to program

**Applications**:
1. **Compositing**: Stack non-grid-aligned objects (>8 sprites/scanline limit)
2. **Text flexibility**: Proportional fonts, Arabic/Vietnamese scripts
3. **Compression**: RLE/LZ to save ROM (Konami, Codemasters games)
4. **Large character sets**: Chinese/Japanese (>256 glyphs)

**Cost**: Requires vblank time to update tiles (~160 bytes/frame = 10 tiles).

### Decision Matrix

| Feature | CHR-ROM | CHR-RAM |
|---------|---------|---------|
| **Switching speed** | Instant (1 write) | Slow (vblank updates) |
| **ROM size** | Larger (separate CHR chip) | Smaller (tiles in PRG) |
| **Compression** | No | Yes |
| **Runtime gen** | No | Yes |
| **Beginner friendly** | Yes (simpler init) | No (must copy tiles) |

**Rule of thumb**:
- **CHR-ROM**: Action games with pre-made tilesets (platformers, shooters)
- **CHR-RAM**: RPGs, puzzle games, anything needing text/composition

---

## Mapper Progression (Beginner → Advanced)

### NROM (Mapper 0) — Baseline

**Specs**:
- **PRG-ROM**: 16KB or 32KB (no switching)
- **CHR**: 8KB ROM or RAM (no switching)
- **Total capacity**: 40KB

**When to use**: Simple games (<32KB code + 8KB graphics).

**Limitation**: Can't exceed 32KB PRG or 8KB CHR.

### UNROM (Mapper 2) — Simple Bank Switching

**Specs**:
- **PRG-ROM**: 64KB, 128KB, or 256KB (UOROM variant)
  - Switchable: 16KB at $8000-$BFFF (banks 0-15)
  - Fixed: 16KB at $C000-$FFFF (last bank)
- **CHR-RAM**: 8KB (no switching, CPU must load tiles)

**Bank switching**:
```asm
; Write to $8000-$FFFF to switch banks
; Bits 0-2 (UNROM) or 0-3 (UOROM) select bank number
; CRITICAL: Must handle bus conflict (see below)

banktable:  ; Lookup table for bus conflict prevention
  .byte $00, $01, $02, $03, $04, $05, $06, $07  ; UNROM (0-6 switchable, 7 fixed)

bankswitch_y:
  sty current_bank   ; save for NMI handler restore
  tya
  sta banktable, y   ; read from table, write same value (avoids bus conflict)
  rts

; Usage:
  ldy #$02
  jsr bankswitch_y   ; switch to bank 2
```

**Bus conflict workaround**: UNROM uses discrete logic (not ASIC). CPU and ROM both drive data bus when writing to $8000-$FFFF. **Value written MUST match ROM contents at destination address**. Solution: Lookup table where `table[N] = N`.

**Fixed bank strategy**:
- Put **vectors, reset code, NMI/IRQ handlers, bankswitch routine** in fixed bank ($C000-$FFFF)
- Put **game logic, levels, data** in switchable banks

**When to use**:
- Need >32KB PRG
- Want CHR-RAM (dynamic graphics)
- Don't need CHR bank switching
- Simple programming model

**iNES header** (UNROM with CHR-RAM):
```asm
.segment "HEADER"
  .byte "NES", $1A
  .byte 8         ; 8 × 16KB = 128KB PRG-ROM
  .byte 0         ; 0 = CHR-RAM (not ROM)
  .byte $20, $08  ; Mapper 2, horizontal mirroring, NES 2.0
  .byte $00       ; No submapper
  .byte $00       ; PRG ROM not 4 MiB+
  .byte $00       ; No PRG RAM
  .byte $07       ; 8192 (64 × 2^7) bytes CHR RAM
  .byte $00       ; NTSC
  .byte $00       ; No special PPU
```

### MMC1 (Mapper 1) — Nintendo's First ASIC

**Specs**:
- **PRG-ROM**: Up to 512KB
  - Three modes:
    1. Fixed $C000 (like UNROM)
    2. Fixed $8000
    3. 32KB mode
- **CHR**: ROM (up to 128KB, 4KB/8KB banks) or RAM (8KB)
- **Mirroring control**: Horizontal, vertical, or one-screen
- **PRG-RAM**: Optional 8KB-32KB

**Serial write protocol** (5-bit shift register):
```asm
; Write same value 5 times with bit 0 shifted right each time
; Example: Write $0E to control register ($8000-$9FFF)

  lda #$0E      ; vertical mirroring, fixed $C000, 8KB CHR
  sta $8000     ; write bit 0
  lsr a
  sta $8000     ; write bit 1
  lsr a
  sta $8000     ; write bit 2
  lsr a
  sta $8000     ; write bit 3
  lsr a
  sta $8000     ; write bit 4 (completes write)

; Quick setup for UNROM-style (fixed $C000, CHR-RAM):
  lda #$0E      ; or $0F for horizontal mirroring
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
  lsr a
  sta $8000
```

**Registers**:
- **$8000-$9FFF**: Control (mirroring, PRG mode, CHR mode)
- **$A000-$BFFF**: CHR bank 0
- **$C000-$DFFF**: CHR bank 1
- **$E000-$FFFF**: PRG bank

**Bank switching** (PRG):
```asm
mmc1_load_prg_bank:
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  rts

; Usage:
  lda #$05
  jsr mmc1_load_prg_bank  ; switch to bank 5
```

**Interrupt safety**: If NMI/IRQ interrupts during 5-write sequence, mapper state is corrupt.

**Solutions**:
1. **Retry flag**:
   - Clear flag before writes
   - Check flag after writes, retry if interrupted
   - NMI/IRQ sets flag when it resets mapper

2. **Save/restore + reset**:
   - Save bank number before every switch
   - Reset mapper ($8000 = $80) before writing
   - Restore bank on NMI/IRQ exit

**Power-on quirk**: Some MMC1 revisions don't guarantee fixed-$C000 mode at power-on.

**Workaround**: Put reset stub at end of every 16KB bank:
```asm
reset_stub:
  sei
  ldx #$FF
  txs
  stx $8000   ; reset mapper to known state
  jmp reset   ; jump to actual init code in $C000-$FFFF

; At end of each bank ($xFFa-$xFFF):
  .addr nmiHandler, reset_stub, irqHandler
```

**When to use**:
- Need >128KB PRG (beyond UNROM)
- Need CHR-ROM bank switching (multiple tilesets)
- Want PRG-RAM (save games)
- Willing to handle serial protocol complexity

---

## Converting NROM → CHR-RAM (Step-by-Step)

Starting with NROM-256 (32KB PRG + 8KB CHR-ROM):

1. **Check PRG space**: Need 8300+ bytes free (for CHR data in PRG-ROM)

2. **Remove CHR-ROM from build**:
   ```asm
   ; Delete: .incbin "mytiles.chr"
   ; Or remove: copy /b game.prg+mytiles.chr game.nes
   ```

3. **Update iNES header**:
   ```asm
   .byte 0   ; CHR banks = 0 (signifies CHR-RAM)
   ; NES 2.0: Also set .byte $07 for CHR-RAM size (8KB)
   ```

4. **Add CHR copy routine** (in init code, before turning on PPU):
   ```asm
   copy_mytiles_chr:
     lda #<mytiles_chr
     sta src
     lda #>mytiles_chr
     sta src+1

     ldy #0
     sty PPUMASK   ; turn off rendering
     sty PPUADDR   ; set destination $0000
     sty PPUADDR
     ldx #32       ; 32 pages × 256 bytes = 8KB
   loop:
     lda (src),y
     sta PPUDATA
     iny
     bne loop
     inc src+1     ; next page
     dex
     bne loop
     rts

   .segment "RODATA"
   mytiles_chr: .incbin "mytiles.chr"
   ```

5. **Rebuild**: Should be 32,784 bytes (16 header + 32,768 PRG)

**Note**: NROM board physically expects CHR-ROM chip. For CHR-RAM, use **BNROM** (iNES Mapper 34) or rewire NROM board.

---

## Mapper Selection Guide

| Need | Mapper | Complexity | Notes |
|------|--------|------------|-------|
| ≤32KB PRG + 8KB CHR | **NROM** | Trivial | No switching |
| ≤256KB PRG + CHR-RAM | **UNROM** | Easy | Simple bankswitch, bus conflict |
| ≤512KB PRG, CHR-ROM banks | **MMC1** | Medium | Serial protocol, interrupt issues |
| ≤512KB PRG, complex needs | **MMC3** | Hard | IRQ counter, advanced features |

**Beginner recommendation**: Start NROM, move to UNROM when you exceed 32KB.

**Practical workflow**:
1. Prototype in NROM (simple, fast iteration)
2. Migrate to UNROM when ROM limit hit (minor code changes)
3. Consider MMC1/MMC3 only when you need:
   - CHR-ROM switching (multiple tilesets)
   - PRG-RAM (save games)
   - IRQ timer (raster effects)

---

## Common Mapper Patterns

### Fixed Bank Strategy (UNROM/MMC1)

**Fixed bank** ($C000-$FFFF) contains:
- Interrupt vectors (NMI, RESET, IRQ)
- Reset/init code
- Bankswitch routine
- Common subroutines (controller read, OAM DMA, etc.)

**Switchable banks** ($8000-$BFFF) contain:
- Level data
- Enemy logic
- Menu screens
- Compressed graphics (for CHR-RAM)

**Critical**: Never `jsr` to switchable bank from fixed bank (or vice versa) unless you restore the bank afterward.

### NMI Bank Restore (UNROM)

If NMI handler switches banks (e.g., for sound engine):

```asm
; Main code:
  sty current_bank   ; save before switch

; NMI handler (end):
  ldy current_bank
  jsr bankswitch_nosave  ; restore without updating current_bank
```

### Bus Conflict Prevention

**UNROM issue**: Discrete logic means CPU and ROM both drive bus on writes to $8000-$FFFF.

**Solutions**:
1. **Lookup table** (standard):
   ```asm
   banktable: .byte $00, $01, $02, $03, $04, $05, $06, $07
   sta banktable, y  ; read ROM value, write same value
   ```

2. **Remap table** (for non-consecutive banks like UN1ROM):
   ```asm
   banktable: .byte $00, $04, $08, $0C, $10, $14, $18  ; UN1ROM format
   lda banktable, y
   sta banktable, y
   ```

**ASIC mappers** (MMC1, MMC3, etc.) don't have bus conflicts.

### Interrupt-Safe MMC1 Writes

**Problem**: 5-write sequence can be interrupted mid-write.

**Solution 1** (retry flag):
```asm
mmc1_write:
  lda #0
  sta interrupted_flag

  lda value
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000

  lda interrupted_flag
  bne mmc1_write  ; retry if interrupted
  rts

; In NMI/IRQ:
  lda #$80
  sta $8000         ; reset mapper
  inc interrupted_flag
```

**Solution 2** (always reset):
```asm
mmc1_write:
  lda #$80
  sta $8000   ; reset mapper to known state

  lda value
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  lsr a
  sta $E000
  rts
```

---

## Mapper-Specific Gotchas

### UNROM
- **Bus conflicts**: Must use lookup table or face crashes
- **No CHR switching**: If you need multiple tilesets, use CHR-RAM + manual copies
- **Fixed bank MUST contain vectors**: Reset stub not needed (unlike MMC1)

### MMC1
- **Serial protocol**: 5 writes per register (easy to mess up)
- **Interrupts**: Can corrupt mid-write (use retry logic)
- **Power-on mode**: Some revisions need reset stub in all banks
- **Write timing**: Wait 2 CPU cycles between writes on early revisions (rare issue)

### General
- **Mirroring**: UNROM is hardwired (horizontal OR vertical), MMC1 is switchable
- **PRG-RAM**: Not all boards have it (check donor cart compatibility)
- **CHR-RAM vs CHR-ROM**: Physical board rewiring may be needed

---

## Key Takeaways

1. **Mappers = bank switching hardware** to exceed 32KB PRG / 8KB CHR limits
2. **CHR-ROM vs CHR-RAM** is a critical early decision (speed vs flexibility)
3. **UNROM = beginner-friendly** (simple bankswitch, bus conflict workaround)
4. **MMC1 = more powerful** (serial protocol, interrupt complexity)
5. **Fixed bank strategy**: Keep common code/vectors in fixed bank
6. **Bus conflicts**: UNROM needs lookup table; MMC1 doesn't
7. **Interrupts**: MMC1 writes need retry logic if NMI/IRQ can interrupt

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Programming_mappers](https://www.nesdev.org/wiki/Programming_mappers)
- [CHR-ROM_vs_CHR-RAM](https://www.nesdev.org/wiki/CHR-ROM_vs_CHR-RAM)
- [Programming_UNROM](https://www.nesdev.org/wiki/Programming_UNROM)
- [Programming_MMC1](https://www.nesdev.org/wiki/Programming_MMC1)
