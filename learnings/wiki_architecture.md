# NES Architecture - Wiki Analysis

**Status**: Complete - Extracted from cached NESdev wiki pages
**Source**: .webcache/ HTML files (CPU_memory_map.html, PPU_memory_map.html, PPU.html, The_frame_and_NMIs.html, Controller_reading.html, APU.html, CPU.html, OAM.html)
**Purpose**: Answer core architecture questions from learnings/INITIAL.md

---

## 1. Memory Map & Organization

### CPU Memory Map ($0000-$FFFF)

| Address Range | Size | Device/Purpose |
|--------------|------|----------------|
| $0000-$00FF | $0100 | **Zero Page** - Fast access (fewer bytes/cycles) |
| $0100-$01FF | $0100 | **Stack** - Starts at $01FF, grows downward |
| $0200-$07FF | $0600 | General RAM (commonly $0200-$02FF used for OAM shadow) |
| $0800-$1FFF | $1800 | **Mirrors of $0000-$07FF** (repeats 3x) |
| $2000-$2007 | $0008 | **PPU Registers** |
| $2008-$3FFF | $1FF8 | Mirrors of $2000-$2007 (repeats every 8 bytes) |
| $4000-$4017 | $0018 | **APU and I/O Registers** (includes controller ports) |
| $4018-$401F | $0008 | APU/I/O test mode (normally disabled) |
| $6000-$7FFF | $2000 | Cartridge RAM (battery-backed save or work RAM) |
| $8000-$FFFF | $8000 | **Cartridge ROM** and mapper registers |

**Key Facts**:
- Total internal RAM: **2 KB** ($0000-$07FF)
- Zero page ($0000-$00FF): Faster access than other addresses
- Stack ($0100-$01FF): 256 bytes, grows downward from $01FF
- Common practice: $0200-$02FF reserved for sprite OAM buffer (shadow OAM)

**CPU Interrupt Vectors** (at end of ROM):
- $FFFA-$FFFB: **NMI vector** (points to NMI handler)
- $FFFC-$FFFD: **Reset vector** (points to initialization code)
- $FFFE-$FFFF: **IRQ/BRK vector** (points to IRQ handler)

### PPU Memory Map ($0000-$3FFF)

The PPU has its own **separate 14-bit address space**:

| Address Range | Size | Description | Mapped By |
|--------------|------|-------------|-----------|
| $0000-$0FFF | $1000 | **Pattern Table 0** (sprite/tile graphics) | Cartridge CHR-ROM/RAM |
| $1000-$1FFF | $1000 | **Pattern Table 1** | Cartridge CHR-ROM/RAM |
| $2000-$23BF | $03C0 | **Nametable 0** (background tile map) | Cartridge or internal VRAM |
| $23C0-$23FF | $0040 | **Attribute Table 0** (color assignment) | Cartridge or internal VRAM |
| $2400-$27FF | $0400 | Nametable 1 + Attribute Table 1 | Cartridge or internal VRAM |
| $2800-$2BFF | $0400 | Nametable 2 + Attribute Table 2 | Cartridge or internal VRAM |
| $2C00-$2FFF | $0400 | Nametable 3 + Attribute Table 3 | Cartridge or internal VRAM |
| $3000-$3EFF | $0F00 | Mirror of $2000-$2EFF (unused) | - |
| $3F00-$3F1F | $0020 | **Palette RAM** (color indexes) | Internal to PPU |
| $3F20-$3FFF | $00E0 | Mirrors of $3F00-$3F1F | Internal to PPU |

**Key Facts**:
- PPU has 2 KB internal VRAM (usually mapped to nametables)
- Pattern tables hold sprite/tile graphics (CHR-ROM)
- Nametables define background layout (32x30 tiles = 960 bytes)
- Attribute tables assign palettes to 2x2 tile groups (64 bytes each)
- Palette RAM: 32 bytes total (not configurable by cartridge)

### PPU Registers (CPU addresses)

| Address | Name | Access | Purpose |
|---------|------|--------|---------|
| $2000 | PPUCTRL | Write | PPU control flags |
| $2001 | PPUMASK | Write | Rendering enable/disable, color effects |
| $2002 | PPUSTATUS | Read | PPU status (VBlank, sprite 0 hit, etc.) |
| $2003 | OAMADDR | Write | OAM address pointer |
| $2004 | OAMDATA | R/W | OAM data access |
| $2005 | PPUSCROLL | Write x2 | Scroll position (X then Y) |
| $2006 | PPUADDR | Write x2 | VRAM address (high byte, then low) |
| $2007 | PPUDATA | R/W | VRAM data access |

### APU Registers (CPU addresses)

| Address Range | Purpose |
|--------------|---------|
| $4000-$4003 | Pulse channel 1 |
| $4004-$4007 | Pulse channel 2 |
| $4008-$400B | Triangle channel |
| $400C-$400F | Noise channel |
| $4010-$4013 | DMC (Delta Modulation Channel) |
| $4015 | APU status (enable/disable channels) |
| $4017 | Frame counter |

### Controller I/O Registers

| Address | Purpose |
|---------|---------|
| $4016 | Controller 1 data + strobe (write 1 then 0 to poll) |
| $4017 | Controller 2 data |
| $4014 | **OAMDMA** - Sprite DMA (write page# to copy 256 bytes to OAM) |

---

## 2. PPU (Picture Processing Unit)

### Core Capabilities
- Generates **240 scanlines** of video output
- Renders backgrounds (tiles) and sprites (movable objects)
- Supports **scrolling** via PPUSCROLL register
- Has **separate memory space** from CPU (accessed via $2006/$2007)

### OAM (Object Attribute Memory)
- Internal PPU memory: **256 bytes** (64 sprites x 4 bytes each)
- Each sprite entry:
  - Byte 0: **Y position** (top of sprite, subtract 1 before writing)
  - Byte 1: **Tile index** (which pattern to use)
  - Byte 2: **Attributes** (palette, priority, flip H/V)
  - Byte 3: **X position** (left side of sprite)

**Sprite DMA ($4014)**:
- Write page number (e.g., $02) to copy 256 bytes from $0200-$02FF to OAM
- Takes **513 CPU cycles** (+1 on odd cycles)
- Much faster than manual LDA/STA loop
- Suspend CPU during transfer

**Sprite Limitations**:
- Max **64 sprites** total
- Max **8 sprites per scanline** (hardware enforced)
- Sprites use **dynamic RAM** - decays if rendering disabled

### Palette System
- **32 bytes** of palette RAM at $3F00-$3F1F
- Background palettes: $3F00-$3F0F (4 palettes x 4 colors)
- Sprite palettes: $3F10-$3F1F (4 palettes x 4 colors)
- Color index $00 is transparent
- Universal background color at $3F00

### Pattern Tables (CHR-ROM)
- Two pattern tables: $0000-$0FFF and $1000-$1FFF
- Each holds 256 tiles (8x8 pixels)
- 2 bits per pixel (4 colors per tile)
- 16 bytes per tile (8 bytes for low bit plane, 8 for high bit plane)

### Nametables (Background Layout)
- Each nametable: **960 bytes** (32 columns x 30 rows)
- Each byte is a tile index into pattern table
- Attribute table: **64 bytes** per nametable
  - Assigns palettes to 2x2 tile groups (16x16 pixel areas)
  - 2 bits per tile = 4 palette choices

### PPU Timing Constraints
- VRAM can **only be safely accessed during VBlank**
- Accessing VRAM during rendering causes glitches
- Must set PPUADDR twice (high byte, then low byte)
- Must read $2002 to reset write toggle before setting scroll/address
- Palette updates should be in VBlank even if PPU is off (rainbow stripe quirk)

### Sprite 0 Hit
- Detects when opaque pixel of sprite 0 overlaps opaque background pixel
- Sets bit 6 of PPUSTATUS ($2002)
- Used for timing effects (e.g., split-screen scrolling)
- Does NOT happen at x=0 to x=7 if clipping enabled
- Does NOT happen at x=255 (pipeline quirk)
- Only first hit per frame is detected

---

## 3. Timing & VBlank

### Frame Structure (NTSC)
- **262 scanlines total** per frame
- **240 visible scanlines** (rendering)
- **20 scanlines for VBlank** (lines 241-260)
- Pre-render scanline (line 261) prepares for next frame

### VBlank Window
- Duration: **20 scanlines** = **2273 CPU cycles**
- Actual usable time: ~**2250 cycles** (accounting for NMI overhead)
- This is when you can safely update PPU memory

### Frame Rate
- NTSC: **~60.0988 FPS** (not exactly 60)
- PAL: **~50.0070 FPS**

### CPU Clock Speed
- NTSC: **~1.79 MHz** (1,789,773 Hz exactly: 21.477272 MHz ÷ 12)
- PAL: **~1.66 MHz** (1,662,607 Hz)
- Master clock divided by 12 (NTSC) or 16 (PAL)

### PPU-CPU Clock Ratio
- NTSC: **3 PPU cycles per 1 CPU cycle** (exactly, no drift)
- PAL: **3.2 PPU cycles per 1 CPU cycle** (exactly)
- Both fed from same master clock

### NMI (Non-Maskable Interrupt)
- Triggered at **start of VBlank** (scanline 241)
- Controlled by bit 7 of PPUCTRL ($2000)
- Guaranteed to run every frame (if enabled)
- **The only reliable way to catch VBlank**

### Cycle Budget Guidelines
From The_frame_and_NMIs.html:
- **160 bytes** to nametables/palette via moderately unrolled loop
- **256 bytes** to OAM via sprite DMA ($4014)
- Everything beyond this requires careful optimization

### What You CAN Do During VBlank
- Update OAM (sprite data) via $4014 DMA
- Update nametables (background tiles)
- Update palettes
- Update scroll position
- Change PPU control flags

### What You CANNOT Do During Rendering
- Access VRAM ($2006/$2007) - causes glitches
- Update nametables/palettes
- Change scroll (except for raster effects)

### Buffering Strategy (from wiki)
**Critical**: Separate logic code from drawing code
1. During game logic (any time): Prepare data in RAM buffers
2. During VBlank: Copy buffers to PPU

**Shadow OAM Example**:
- Reserve $0200-$02FF in RAM
- Update sprites by writing to shadow OAM
- In VBlank: Write $02 to $4014 to DMA copy to real OAM

**Nametable Buffer Format** (suggested pattern):
```
Byte 0: Length of data (0 = end of buffer)
Byte 1: PPU address high byte
Byte 2: PPU address low byte
Byte 3: Flags (inc-by-1 vs inc-by-32, RLE, etc.)
Bytes 4+: Data to copy
```

**Why Buffer?**
- Sacrifice rendering time (plentiful) to save VBlank time (scarce)
- Keeps drawing code simple and fast
- Prevents spilling out of VBlank window

### NMI Best Practices (from wiki)
- **Leave NMIs enabled** all the time (after startup)
- Structure NMI handler to:
  1. Do timing-critical stuff first (PPU updates)
  2. Then set scroll/control registers
  3. Then non-timing-critical stuff (music, etc.)
- Make operations conditional via flags (needdma, needdraw, etc.)
- Backup A/X/Y registers at start (PHA, TXA, PHA, TYA, PHA)
- Restore at end (PLA, TAY, PLA, TAX, PLA)

### Interrupt-Aware Programming
**Conflicts to avoid**:
1. **CPU register conflicts**: NMI can change A/X/Y mid-operation
   - Solution: Backup/restore regs in NMI handler
2. **Variable conflicts**: NMI and main code share variables
   - Solution: Don't share temp variables between NMI and main
3. **System state conflicts**: NMI can reset PPU toggle ($2002)
   - Solution: Make state changes in NMI conditional

**Multi-instruction operations are vulnerable**:
```assembly
; VULNERABLE - NMI can occur between LDA and STA
lda playermaxhp
sta playerhp

; SAFER - single instruction
sta needdma
```

---

## 4. Controllers & Input

### Controller Reading Process
**Standard 3-step process**:
1. Write **1** to $4016 (signal controller to poll buttons)
2. Write **0** to $4016 (finish poll, enter serial mode)
3. Read $4016 or $4017 **8 times** (one bit per button)

### Button Order (Standard Controller)
Each read from $4016/$4017 returns one button (D0 = inverted button state):
1. A
2. B
3. Select
4. Start
5. Up
6. Down
7. Left
8. Right

**Note**: Read value is **inverted** (pressed = 0, released = 1)

### Register Details

**$4016 Write** (Controller Strobe):
```
xxxx xEES
      |||
      ||+- Controller port latch bit (1=poll, 0=serial)
      ++-- Expansion port latch bits
```

**$4016/$4017 Read**:
```
xxxD DDDD
|||+-++++- Input data lines D4-D0
+++------- Open bus
```

**Data Lines**:
- D0: NES controller / Famicom controller 1
- D1: Famicom expansion port controller
- D2: Famicom microphone (controller 2 only)
- D3: Zapper light sense
- D4: Zapper trigger

### DPCM Conflict (NTSC Only)
**Problem**: DMC audio sample playback can cause spurious controller reads
- DMC DMA can "double-clock" shift register during $4016/$4017 read
- Results in bit deletion (often appears as spurious "right" press)
- **Fixed in PAL NES** (2A07 CPU)

**Solutions**:
1. **Multiple Read Method**: Read controller 2-3 times, compare results
2. **OAM DMA Sync**: Trigger OAM DMA before reading (aligns APU "get" cycles)
   - All $401x reads must be even number of cycles apart
   - More complex but supports devices like SNES Mouse

### Input Timing
- Controller reading should be **once per frame** (in NMI or after)
- Can read any time, but VBlank is conventional
- No debouncing needed (hardware is digital)

### Detecting Press vs Hold vs Release
```assembly
; Store previous frame's buttons
lda buttons
sta buttons_prev

; Read current frame
jsr read_controller
sta buttons

; Detect new presses (not held last frame)
lda buttons_prev
eor #$FF          ; Invert prev
and buttons       ; AND with current
sta buttons_new   ; = buttons pressed THIS frame

; Detect releases
lda buttons
eor #$FF
and buttons_prev
sta buttons_released
```

### Two Controller Support
- $4016: Controller 1
- $4017: Controller 2
- Same read process for both
- Can read simultaneously or sequentially

---

## 5. APU (Audio Processing Unit)

### Overview
- APU registers: **$4000-$4017**
- Built into RP2A03 (NTSC) / RP2A07 (PAL) CPU chip
- 5 audio channels total

### Channels
1. **Pulse 1** ($4000-$4003): Square wave, sweep, envelope
2. **Pulse 2** ($4004-$4007): Square wave, sweep, envelope
3. **Triangle** ($4008-$400B): Triangle wave (bass/melody)
4. **Noise** ($400C-$400F): Pseudo-random noise (percussion/effects)
5. **DMC** ($4010-$4013): Delta Modulation Channel (samples)

### Channel Control
- **$4015**: Enable/disable channels, read length counter status
- **$4017**: Frame counter mode (4-step or 5-step sequencer)

### DMC Sample Playback
- Reads samples from CPU memory ($C000-$FFFF practical range)
- Can cause controller read glitches (see Controllers section)
- Useful for drum samples, voice clips

### Key Characteristics
- Each channel has variable-rate timer
- Envelope generators for volume control
- Length counters control note duration
- Sweep units for pitch bends (pulse channels)
- Non-linear mixing of all channels

### Music Engine Considerations
- Update APU registers in NMI (every frame)
- Music engine should run even during game logic
- Lower priority than graphics (can skip frames if needed)

---

## 6. Key Constraints to Remember

### Memory Constraints
- **2 KB internal RAM** total
  - $0000-$00FF: Zero page (fast access)
  - $0100-$01FF: Stack (256 bytes)
  - $0200-$07FF: General purpose (~1.5 KB after OAM buffer)
- PPU: 2 KB internal VRAM (for nametables)

### Timing Constraints
- **2250 cycles** usable VBlank time
- Can update ~160 bytes to nametables OR ~256 bytes via DMA
- Everything is cycle-counted - no handwaving performance

### PPU Constraints
- VRAM access **only during VBlank** (or when rendering disabled)
- Max **8 sprites per scanline** (hardware limit)
- Max **64 sprites total**
- Sprite 0 hit detection (for timing effects)
- OAM is **dynamic RAM** - decays without rendering

### Rendering Constraints
- Cannot update nametables during rendering (causes glitches)
- Palette updates should be in VBlank even when PPU off
- Must set PPUADDR twice (high byte, low byte)
- Must read PPUSTATUS ($2002) to reset toggle

### Graphics Constraints
- 2 bits per pixel = **4 colors per tile/sprite**
- Palette: 32 bytes total (4 bg + 4 sprite palettes x 4 colors)
- Pattern tables: 256 tiles per table (8x8 pixels each)
- Nametable: 32x30 tiles = 960 bytes

### Controller Constraints
- Read once per frame (after VBlank)
- DPCM audio can cause read glitches (NTSC only)
- Must strobe before reading (write 1, then 0 to $4016)

### Audio Constraints
- 5 channels total (2 pulse, 1 triangle, 1 noise, 1 DMC)
- DMC reads from CPU memory (competes with code execution)
- APU registers at $4000-$4017

---

## 7. Critical Gotchas

### PPU Gotchas
1. **Toggle Reset**: Reading $2002 resets PPUADDR/PPUSCROLL write toggle
2. **Sprite Y-1**: Must subtract 1 from Y coordinate before writing to OAM
3. **Sprite 0 Limits**: No hit at x=0-7 (if clipping on), x=255, or if transparent
4. **Palette $3F00**: Universal background color (all palettes use it)
5. **OAM Decay**: Dynamic RAM decays without rendering (~1.3ms)

### Timing Gotchas
1. **NMI vs VBlank**: NMI is a notification, VBlank is a time period
2. **VBlank != RTI**: VBlank can end before your NMI handler finishes
3. **Odd Cycle DMA**: OAM DMA takes 513 cycles +1 if started on odd cycle
4. **3:1 PPU Ratio**: 3 PPU cycles per 1 CPU cycle (NTSC) - no drift

### Controller Gotchas
1. **Inverted Reads**: 0 = pressed, 1 = not pressed
2. **DPCM Glitch**: Sample playback causes spurious button reads (NTSC)
3. **Must Strobe**: Write 1 then 0 to $4016 before each read sequence

### Memory Gotchas
1. **Mirroring**: $0800-$1FFF mirrors $0000-$07FF (don't waste comparisons)
2. **PPU Mirrors**: $2008-$3FFF mirrors $2000-$2007 every 8 bytes
3. **Stack Direction**: Grows **downward** from $01FF
4. **Zero Page Speed**: Faster access, use for hot variables

---

## Next Steps for Implementation

Based on this analysis, we can now:

1. **Define memory layout** (CODE_MAP.md):
   - Zero page allocation ($00-$FF)
   - Stack usage ($0100-$01FF)
   - OAM buffer ($0200-$02FF)
   - General RAM ($0300-$07FF)

2. **Create initialization sequence**:
   - Wait for PPU warmup
   - Clear RAM
   - Initialize PPU registers
   - Load palette
   - Enable NMI

3. **Implement VBlank handler**:
   - Sprite DMA ($4014)
   - Nametable updates (buffered)
   - Scroll updates
   - Control register updates

4. **Build controller reading routine**:
   - Strobe + 8 reads
   - Handle DPCM conflict
   - Track press/hold/release

5. **Set up game loop structure**:
   - WaitFrame routine
   - Game logic (during rendering)
   - Drawing code (VBlank only)

---

## References

All information extracted from:

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [CPU_memory_map](https://www.nesdev.org/wiki/CPU_memory_map)
- [PPU_memory_map](https://www.nesdev.org/wiki/PPU_memory_map)
- [PPU](https://www.nesdev.org/wiki/PPU)
- [The_frame_and_NMIs](https://www.nesdev.org/wiki/The_frame_and_NMIs)
- [Controller_reading](https://www.nesdev.org/wiki/Controller_reading)
- [APU](https://www.nesdev.org/wiki/APU)
- [CPU](https://www.nesdev.org/wiki/CPU)
- [OAM](https://www.nesdev.org/wiki/OAM)

