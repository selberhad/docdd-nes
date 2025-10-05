# Graphics Techniques

**Source**: Priority 2 NESdev Wiki pages (Detecting video standard, Drawing terrain, Palette change mid-frame)

Practical patterns for graphics rendering, terrain generation, and raster effects.

---

## Detecting Video Standard (NTSC vs PAL)

### Why Detection Matters

**NTSC vs PAL differences**:
- **Frame rate**: 60 Hz (NTSC) vs 50 Hz (PAL) - 20% slower
- **Vblank duration**: ~2273 cycles (NTSC) vs ~7459 cycles (PAL)
- **Music timing**: APU frame counter runs at different rates
- **Physics/animation**: Need to adjust speed for consistent gameplay

### Detection Method 1: PPU Frame Timing

**Concept**: Count CPU cycles during one full frame

```asm
detect_video_standard:
  ; Wait for vblank start
  bit $2002
wait_vblank:
  bit $2002
  bpl wait_vblank

  ; Start cycle counter
  ldx #0
  ldy #0

count_loop:
  ; Each iteration = 13 cycles
  nop  ; 2 cycles
  nop  ; 2 cycles
  nop  ; 2 cycles
  iny  ; 2 cycles
  bne count_loop  ; 3 cycles (2 if not taken)
  inx
  cpx #$FF
  bne count_loop

  ; Check if still in same frame
  bit $2002
  bmi ntsc_detected  ; Still in vblank = NTSC
  ; Fell through to next frame = PAL

ntsc_detected:
  lda #$00
  sta video_system  ; 0 = NTSC
  rts

pal_detected:
  lda #$01
  sta video_system  ; 1 = PAL
  rts
```

**Timing**:
- NTSC: ~29,780 cycles/frame
- PAL: ~33,247 cycles/frame
- If loop completes before vblank ends → PAL (longer frame)

### Detection Method 2: Read Back Test (PPU behavior)

**Concept**: Early 2C02 (NTSC) can't read back palette/sprite RAM; PAL can

```asm
detect_ppu_readback:
  lda $2002        ; Reset address latch
  lda #$3F
  sta $2006
  lda #$00
  sta $2006        ; Set address to $3F00 (palette)

  lda #$3F         ; Write known value
  sta $2007

  lda $2002        ; Reset latch
  lda #$3F
  sta $2006
  lda #$00
  sta $2006        ; Re-set address to $3F00

  lda $2007        ; Dummy read
  lda $2007        ; Actual read

  cmp #$3F
  beq pal_or_new_ntsc
  ; Can't read back = old NTSC 2C02
```

**Limitation**: Only distinguishes OLD NTSC from PAL/new NTSC; not always reliable

### Recommended Strategy

**Use frame timing method** (more reliable across all PPU revisions):
1. Detect at power-on (before game logic starts)
2. Store result in RAM variable
3. Adjust game speed, music rate, and physics based on video_system flag

```asm
; Example: Adjust player speed
update_player:
  lda video_system
  beq ntsc_speed
pal_speed:
  lda player_vel_x
  clc
  adc #$02         ; Faster on PAL to compensate for 50 Hz
  sta player_vel_x
  jmp update_done
ntsc_speed:
  lda player_vel_x
  clc
  adc #$01         ; Normal speed on NTSC 60 Hz
  sta player_vel_x
update_done:
```

---

## Drawing Terrain

### Tile-Based Terrain

**Pattern**: Use nametable to define terrain layout; attribute table for color

#### Metatile System

**Concept**: Group 2x2 or 4x4 tiles into larger "metatiles"; level data stores metatile indices

```
Level data (compressed):
  [metatile_id, metatile_id, metatile_id, ...]

Metatile table:
  metatile_0: [tile_TL, tile_TR, tile_BL, tile_BR, attribute]
  metatile_1: [tile_TL, tile_TR, tile_BL, tile_BR, attribute]
```

**Decompression** (during level load):
```asm
draw_metatile:
  ; Input: A = metatile ID, X = screen X, Y = screen Y
  asl              ; Multiply by 5 (each metatile = 5 bytes)
  asl
  clc
  adc metatile_id  ; A = metatile_id * 5
  tax

  ; Load 4 tile indices from metatile table
  lda metatile_table+0,x  ; Top-left tile
  sta nametable_buffer+0
  lda metatile_table+1,x  ; Top-right tile
  sta nametable_buffer+1
  lda metatile_table+2,x  ; Bottom-left tile
  sta nametable_buffer+32  ; Next row (32 tiles/row)
  lda metatile_table+3,x  ; Bottom-right tile
  sta nametable_buffer+33
```

**Benefit**: 1 byte of level data → 4 tiles + attribute; huge compression

### Scrolling Terrain

**Challenge**: Can't update entire nametable mid-frame; must stream columns/rows

#### Column-Based Streaming (Horizontal Scrolling)

```asm
scroll_right:
  ; When scroll crosses 8-pixel boundary, load new column
  lda scroll_x
  and #$07
  bne no_column_update  ; Only update every 8 pixels

  ; Calculate column to update (scroll_x / 8 mod 32)
  lda scroll_x
  lsr
  lsr
  lsr
  and #$1F
  sta column_index

  ; Stream column during vblank
  jsr load_terrain_column

no_column_update:
  ; Update scroll registers
  lda scroll_x
  sta $2005
  lda scroll_y
  sta $2005
```

**Pattern**: Load 1 column (30 tiles) per frame during vblank; budget ~200 cycles

#### Row-Based Streaming (Vertical Scrolling)

Similar to column streaming, but load 32 tiles (1 row) when scroll_y crosses 8-pixel boundary

**CRITICAL**: Vblank budget is ~2273 cycles (NTSC); can't load full column AND update sprites. Prioritize updates:
1. OAM DMA (513 cycles)
2. Scroll registers (20 cycles)
3. Column/row update (remaining cycles)

### Attribute Table Updates

**Problem**: Attribute bytes control 2x2 metatile areas; changing 1 tile affects neighbors

**Solution**: Update attribute bytes in pairs; ensure metatile boundaries align with attribute boundaries

```
Nametable: 32x30 tiles
Attribute table: 8x8 metatiles (each metatile = 4x4 tiles)

Attribute byte layout (2 bits per 2x2 tile quadrant):
  bits 1-0: top-left quadrant
  bits 3-2: top-right quadrant
  bits 5-4: bottom-left quadrant
  bits 7-6: bottom-right quadrant
```

**Pattern**: When updating metatile, recalculate attribute byte for entire 4x4 tile area

---

## Palette Change Mid-Frame

### Raster Effects with Palette Swaps

**Use case**: Status bar different colors than playfield; water/lava color cycling

#### Technique 1: Sprite 0 Hit + Palette Write

**Pattern**:
1. Place sprite 0 at split point (e.g., scanline 40)
2. Wait for sprite 0 hit
3. Write new palette values to $3F00-$3F1F

```asm
nmi_handler:
  ; ... OAM DMA, scroll updates ...

  ; Wait for sprite 0 hit
wait_split:
  bit $2002
  bvs wait_split

  ; Change palette for playfield
  lda $2002        ; Reset address latch
  lda #$3F
  sta $2006
  lda #$00
  sta $2006        ; Address = $3F00

  lda #$0F         ; New background color
  sta $2007
  lda #$30         ; New palette color 1
  sta $2007
  ; ... update remaining palette entries ...
```

**Timing**: Must complete palette writes before rendering reaches updated area

#### Technique 2: Mapper IRQ (MMC3, etc.)

**Concept**: Scanline counter triggers IRQ; change palette in IRQ handler

```asm
irq_handler:
  ; Save registers
  pha
  txa
  pha
  tya
  pha

  ; Change palette
  lda $2002
  lda #$3F
  sta $2006
  lda #$01
  sta $2006        ; Address = $3F01 (sprite palette 0, color 1)

  lda water_color
  sta $2007        ; Update water color

  ; Restore registers
  pla
  tay
  pla
  tax
  pla
  rti
```

**Benefit**: Precise scanline timing; no sprite 0 hit dependency

#### Technique 3: Color Emphasis Bits

**Concept**: PPUMASK bits 5-7 tint the entire screen (red/green/blue emphasis)

```asm
; Tint screen red for damage effect
  lda #%00100000   ; Red emphasis
  sta $2001

; Restore normal palette
  lda #%00011110   ; BG + sprites enabled, no emphasis
  sta $2001
```

**Use case**: Screen flash effects; underwater tint; damage indicators

**CRITICAL**: Emphasis bits affect ALL colors; can't selectively tint regions

### Palette Animation

**Concept**: Cycle palette values over time for animated effects

```
Frame 0: Palette 0 = [$0F, $12, $22, $30]  ; Blue water
Frame 10: Palette 0 = [$0F, $11, $21, $30] ; Lighter blue
Frame 20: Palette 0 = [$0F, $12, $22, $30] ; Back to blue
```

**Implementation**:
```asm
animate_palette:
  inc palette_timer
  lda palette_timer
  cmp #10
  bne skip_palette_update

  ; Update palette
  lda $2002
  lda #$3F
  sta $2006
  lda #$01
  sta $2006

  ldx palette_frame
  lda palette_anim_table,x
  sta $2007        ; Write new color

  inc palette_frame
  lda palette_frame
  cmp #palette_anim_length
  bne reset_timer
  lda #0
  sta palette_frame

reset_timer:
  lda #0
  sta palette_timer

skip_palette_update:
  rts
```

**Budget**: Palette writes are 2 cycles each; full palette (32 bytes) = ~64 cycles

---

## Graphics Update Patterns

### Double Buffering (Nametables)

**Concept**: Draw to inactive nametable; swap via PPUCTRL

```
Nametable $2000: Currently visible
Nametable $2400: Draw next frame

After drawing complete:
  LDA #$90         ; Enable NMI, select $2400 as base nametable
  STA $2000
```

**Limitation**: Requires horizontal mirroring or 4-screen VRAM (rare)

### Incremental Updates

**Pattern**: Queue small changes; apply during vblank

```asm
; Queue a tile update
queue_tile_update:
  ldx tile_queue_count
  lda tile_x
  sta tile_queue_x,x
  lda tile_y
  sta tile_queue_y,x
  lda tile_number
  sta tile_queue_tile,x
  inc tile_queue_count
  rts

; Process queue during NMI
process_tile_queue:
  ldx #0
process_loop:
  cpx tile_queue_count
  beq queue_done

  ; Calculate nametable address
  lda tile_queue_y,x
  asl
  asl
  asl
  asl
  asl              ; Y * 32
  clc
  adc tile_queue_x,x
  sta $2006        ; Low byte
  lda #$20
  sta $2006        ; High byte ($2000 + offset)

  lda tile_queue_tile,x
  sta $2007        ; Write tile

  inx
  jmp process_loop

queue_done:
  lda #0
  sta tile_queue_count  ; Clear queue
  rts
```

**Budget**: Each tile update = ~20 cycles; can update ~100 tiles/frame if prioritized

---

## Key Takeaways

1. **Video standard detection is ESSENTIAL** - 20% speed difference between NTSC/PAL affects all timing
2. **Metatile systems compress level data** - 1 byte → 4+ tiles; critical for fitting levels in ROM
3. **Scrolling requires streaming** - Can't update full screen; stream columns/rows at 8-pixel boundaries
4. **Palette changes mid-frame need timing** - Use sprite 0 hit or mapper IRQ; budget cycles carefully
5. **Incremental updates maximize vblank** - Queue changes during gameplay; batch apply in NMI

## Reference Files

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Detecting_video_standard](https://www.nesdev.org/wiki/Detecting_video_standard)
- [Drawing_terrain](https://www.nesdev.org/wiki/Drawing_terrain)
- [Palette_change_mid_frame](https://www.nesdev.org/wiki/Palette_change_mid_frame)

