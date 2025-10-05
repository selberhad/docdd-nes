# Sprite Techniques

**Source**: Priority 2 NESdev Wiki pages (PPU sprite evaluation, sprite size, placeholder graphics, sprite cel streaming, OAM addresses)

Practical patterns for sprite management, evaluation limits, and streaming techniques.

---

## Sprite Evaluation Process

### Hardware Limitations

**64 sprites total, 8 sprites per scanline maximum**

The PPU evaluates sprites during rendering (dots 65-256 of each scanline):
1. **Primary OAM scan** (dots 65-256): Check all 64 sprites for Y-range overlap
2. **Secondary OAM fill**: Copy up to 8 in-range sprites to secondary OAM (32 bytes)
3. **Sprite fetch** (dots 257-320): Fetch pattern data for secondary OAM sprites

**CRITICAL**: If more than 8 sprites overlap a scanline, sprites 9+ are dropped (sprite overflow).

### Sprite Overflow Flag

- Bit 5 of $2002 (PPUSTATUS) is set when more than 8 sprites occupy a scanline
- **Hardware bug**: Flag is unreliable due to evaluation glitches (can set incorrectly or miss actual overflows)
- **Workaround**: Don't rely on overflow flag for game logic; design around 8-sprite limit instead

### Sprite Priority Behavior

- **Lower OAM index = higher priority** for sprite-0-hit and pixel rendering
- Sprites earlier in OAM (sprite 0, 1, 2...) appear in front of later sprites
- **Use case**: Place important sprites (player character) at low OAM indices

---

## Sprite Size Modes

### 8x8 Sprites (PPUCTRL bit 5 = 0)

```
Pattern selection: Sprite attribute byte directly specifies tile number
CHR address: $0000 or $1000 bank (PPUCTRL bit 3) + tile number * 16
```

**Use case**: Most games; flexible tile selection, easier to manage

### 8x16 Sprites (PPUCTRL bit 5 = 1)

```
Pattern selection: Attribute byte specifies PAIR of tiles (top + bottom)
  - Bit 0 of tile number selects CHR bank ($0000 or $1000)
  - Bits 1-7 select tile pair (top tile = tile & $FE, bottom = tile | $01)
```

**Gotcha**: Tiles must be arranged in even/odd pairs in CHR-ROM
**Benefit**: Larger sprites without using 2 OAM entries; saves sprite slots

### Mode Switching Strategy

**Can change sprite size mid-frame** (via PPUCTRL in NMI or during vblank):
- Top status bar: 8x8 sprites for text/icons
- Main playfield: 8x16 sprites for characters

**CRITICAL**: Mode applies to ALL sprites; can't mix 8x8 and 8x16 simultaneously

---

## Sprite 0 Hit Detection

**Purpose**: Detect when sprite 0's opaque pixel overlaps background opaque pixel (for raster effects)

### How It Works

1. Place sprite 0 at strategic scanline (e.g., bottom of status bar)
2. Ensure both sprite 0 pixel AND background pixel are opaque (non-transparent)
3. Poll $2002 bit 6 until set (sprite 0 hit occurred)
4. Change scroll/PPUCTRL for split-screen effect

### Practical Pattern (from Controller_reading_code.html)

```asm
wait_sprite0_hit:
  bit $2002           ; Check sprite 0 hit flag
  bvs wait_sprite0_hit ; Loop until bit 6 set
  ; Now at scanline where sprite 0 overlapped background
  ; Safe to change scroll registers
```

**Timing**: Sprite 0 hit flag is set during rendering, cleared on $2002 read or vblank start

### Sprite 0 Gotchas

- **Must occur during rendering** (sprites/background enabled)
- **X=255 edge case**: Sprite 0 hit doesn't occur if sprite is at X=255
- **Left clip area**: If PPUMASK bits 1/2 hide leftmost 8 pixels, sprite 0 must be placed accordingly
- **Timing sensitivity**: Hit occurs mid-scanline; may need cycle-counted delays after detection

---

## OAM Management Best Practices

### Don't Hardcode OAM Addresses

**Problem**: Hardcoding sprite positions like `$0200, $0204, $0208` makes sprite management inflexible

**Solution**: Use indirection and loop-based updates

```asm
; Bad: Hardcoded addresses
lda #$50
sta $0200  ; Y pos of sprite 0
sta $0204  ; Y pos of sprite 1
sta $0208  ; Y pos of sprite 2

; Good: Index-based updates
ldx #0
lda #$50
sprite_loop:
  sta $0200,x  ; Y position
  inx
  inx
  inx
  inx          ; Advance by 4 bytes per sprite
  cpx #12      ; Update 3 sprites
  bne sprite_loop
```

### OAM Buffer Strategy

**Pattern**: Use shadow OAM in main RAM, then DMA to OAM during vblank

```asm
.segment "BSS"
oam_buffer: .res 256  ; $0200-$02FF reserved for OAM shadow

.segment "CODE"
; Update sprites in main RAM during gameplay
update_player_sprite:
  lda player_y
  sta oam_buffer+0     ; Y position
  lda player_tile
  sta oam_buffer+1     ; Tile number
  lda player_attr
  sta oam_buffer+2     ; Attributes
  lda player_x
  sta oam_buffer+3     ; X position

; During NMI: DMA entire buffer to OAM
nmi_handler:
  lda #$02
  sta $4014            ; Start OAM DMA from $0200
```

**Benefit**: Atomically update all sprites; no partial updates during rendering

---

## Placeholder Graphics

### Development Workflow

**Use simple patterns during prototyping** before final art is ready:

1. **Solid color tiles**: Single-color sprites/backgrounds (easy to identify objects)
2. **Checkboard patterns**: Distinguish different sprite types
3. **Number tiles**: Display sprite indices for debugging
4. **Color-coded placeholders**: Consistent palette = consistent object type

### Palette Strategy for Placeholders

```
Palette 0: Player (blue)
Palette 1: Enemies (red)
Palette 2: Items (yellow)
Palette 3: UI elements (white/gray)
```

**Benefit**: Swap palettes later without changing tile references; art replacement is palette + CHR swap

---

## Sprite Cel Streaming

**Problem**: Limited CHR-ROM space (8KB banks); can't fit all animation frames simultaneously

**Solution**: Stream sprite patterns to CHR-RAM during vblank

### Technique 1: Double Buffering (MMC3 or CHR-RAM)

```
Bank 0: Active sprites (currently displayed)
Bank 1: Next frame's sprites (loaded during vblank)

Frame N: Display bank 0, load bank 1
Frame N+1: Display bank 1, load bank 0
```

**Pattern**:
1. Game logic determines next animation frame
2. During vblank, DMA new tiles to inactive CHR bank
3. Swap active bank (PPUCTRL or mapper register)

### Technique 2: Streaming to CHR-RAM

**Use case**: Games with CHR-RAM (e.g., mapper 1, 2, 4 with CHR-RAM)

```asm
; Stream 16 bytes (1 tile) to CHR-RAM during vblank
stream_tile:
  lda $2002           ; Reset address latch
  lda #$00
  sta $2006           ; High byte of CHR address
  lda #$40
  sta $2006           ; Low byte ($0040 = tile 4)

  ldx #0
stream_loop:
  lda tile_buffer,x   ; Load from RAM buffer
  sta $2007           ; Write to CHR-RAM
  inx
  cpx #16             ; 16 bytes per tile
  bne stream_loop
```

**Budget**: ~2273 cycles during NTSC vblank; can stream ~20 tiles per frame if optimized

### Technique 3: Metasprite Recycling

**Concept**: Reuse same CHR tiles, change OAM positions/attributes

Example: Walking animation
- Frame 1: Tile $00 at (X, Y)
- Frame 2: Tile $00 at (X+2, Y), flip horizontal attribute
- Frame 3: Tile $01 at (X, Y)

**Benefit**: 2-3 tiles cover 6-8 animation frames via position/flip tricks

---

## Sprite Evaluation Timing

### When Sprites Are Visible

- **Rendering enabled** (PPUMASK bits 3 or 4 set): Sprites evaluate and render
- **Rendering disabled**: Sprites don't appear; OAM can be written anytime

### OAM Write Windows

**NTSC (2C02)**:
- **Safe write time**: Vblank (scanlines 241-260) = ~2273 CPU cycles
- **Unsafe**: During rendering (scanlines 0-239); writes may corrupt OAM

**PAL (2C07)**:
- **Safe write time**: Only first 24 scanlines after NMI (~2557 CPU cycles)
- **Unsafe**: Scanlines 24-239; OAM writes blocked by PPU

**Workaround**: Always use OAM DMA ($4014) during vblank; avoid direct OAM writes

---

## Advanced Sprite Tricks

### Hiding Sprites

**Method 1**: Set Y position to $FF (off-screen)
```asm
lda #$FF
sta oam_buffer,x  ; Sprite moves below visible scanlines
```

**Method 2**: Set tile number to $FF (if $FF is transparent tile)

**Method 3**: Use attribute to select all-transparent palette

### Sprite Flickering (8-sprite limit mitigation)

**Problem**: More than 8 sprites on same scanline causes dropout

**Solution**: Rotate sprite priority each frame
```asm
; Frame N: Start OAM scan at sprite 0
; Frame N+1: Start OAM scan at sprite 8 (rotate priority)
; Frame N+2: Start OAM scan at sprite 16
```

**Pattern**:
```asm
; Rotate OAM buffer by 4 bytes each frame
rotate_oam:
  lda oam_buffer+0
  pha
  lda oam_buffer+1
  pha
  lda oam_buffer+2
  pha
  lda oam_buffer+3
  pha

  ; Shift all sprites down by 4 bytes
  ldx #0
shift_loop:
  lda oam_buffer+4,x
  sta oam_buffer+0,x
  inx
  cpx #252
  bne shift_loop

  ; Restore first sprite at end
  pla
  sta oam_buffer+255
  pla
  sta oam_buffer+254
  pla
  sta oam_buffer+253
  pla
  sta oam_buffer+252
```

**Result**: Dropped sprites alternate each frame (flicker instead of disappear)

---

## Key Takeaways

1. **8 sprites per scanline is HARD LIMIT** - design around it (sprite flicker, smaller sprites, y-position spreading)
2. **Sprite 0 hit is TIMING-CRITICAL** - requires opaque overlap, careful placement, cycle-accurate polling
3. **OAM DMA is MANDATORY** - never write OAM directly during rendering; always use $4014 in vblank
4. **8x16 mode saves sprite slots** - use for large characters; remember tiles must be paired
5. **CHR streaming enables large sprite sets** - budget ~20 tiles/frame on NTSC; use double-buffering

## Reference Files

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [PPU_sprite_evaluation](https://www.nesdev.org/wiki/PPU_sprite_evaluation)
- [Sprite_size](https://www.nesdev.org/wiki/Sprite_size)
- [Placeholder_graphics](https://www.nesdev.org/wiki/Placeholder_graphics)
- [Sprite_cel_streaming](https://www.nesdev.org/wiki/Sprite_cel_streaming)
- [Don't_hardcode_OAM_addresses](https://www.nesdev.org/wiki/Don't_hardcode_OAM_addresses)

