# Getting Started with NES Development

**Source**: Priority 1 NESdev Wiki pages (Before_the_basics, Programming_Basics, Init_code, Registers, PPU_power_up_state, Sample_RAM_map, Limitations)

This document consolidates foundational knowledge for NES development, extracted from cached wiki documentation.

---

## 1. Hardware Overview

### NES Components
- **2A03 CPU** (Ricoh): 6502-based 8-bit microprocessor running at ~1.79 MHz
  - Serial input for game controllers
  - Audio output (4 tone generators + delta modulation playback)
- **2KB CPU RAM** ($0000-$07FF)
- **2C02 PPU** (Picture Processing Unit)
  - Tile-based background rendering
  - 64 sprites (individually moving objects)
  - 25 colors from palette of 53
  - 256x240 pixel progressive output
- **2KB PPU RAM** (internal VRAM)

### Cartridge Components
- **PRG ROM**: 16KB+ program code for CPU (at $8000+)
- **CHR ROM/RAM**: 8KB+ graphics data for PPU
- **Optional mapper**: Bank switching hardware
- **Optional PRG RAM**: 8KB battery-backed save RAM (at $6000-$7FFF)

### Critical Architecture Constraints
- **PPU and CPU do not share memory** - separate buses entirely
- **PPU spends exactly 1 clock cycle per pixel** rendered
- **No pre-initialized global variables** - all data lives in ROM, must manually initialize RAM
- **Memory-mapped I/O** - registers accessed through CPU address space
- **1.79 MHz CPU** - expect cycle-counting requirements for timing-critical code

---

## 2. 6502 CPU Fundamentals

### Registers (6 total, mostly 8-bit)
1. **Accumulator (A)**: Main arithmetic/logic register
2. **X Index (X)**: Loop counter, memory addressing, temporary storage
3. **Y Index (Y)**: Similar to X, but not fully interchangeable
4. **Flags (P)**: 7 status flags packed into 8-bit register
5. **Stack Pointer (SP)**: Points to current stack location ($0100-$01FF)
6. **Program Counter (PC)**: 16-bit! Shows position in program sequence

### Stack Behavior
- **Location**: Fixed at $0100-$01FF (256 bytes, "stack page")
- **LIFO**: Last-in-first-out data structure
- **Fast access**: Faster than heap-based memory
- **Instructions**: PHA, PLA, PHP, PLP, JSR, RTS, BRK, RTI

### Instruction Set
- **56 instructions total** (not all 256 opcodes used originally)
- **3-letter mnemonics** (LDA, STA, ADC, etc.)
- **Register-specific instructions** include register in mnemonic (LDA = Load Accumulator)
- **No multiplication/division** - must implement manually
- **No decimal mode** (2A03 lacks it, though 6502 spec includes it)

### Math Operations
- **Addition**: `ADC` (add with carry)
- **Subtraction**: `SBC` (subtract with carry)
- **Multiplication**: Implement using shift-and-add algorithm
  - Example provided: 16-bit unsigned multiply → 32-bit result
  - Uses zero page addresses for operands/results
- **Division**: Must implement manually (not provided in examples)

---

## 3. Memory Organization

### CPU Memory Map ($0000-$FFFF)
- **$0000-$00FF**: Zero page (fastest access, required for indirect addressing)
- **$0100-$01FF**: Stack page (CPU stack operations)
- **$0200-$07FF**: General RAM (6 pages)
- **$6000-$7FFF**: Optional PRG RAM (battery-backed save data)
- **$8000-$FFFF**: PRG ROM (program code and data)

### Sample RAM Layout (from Sample_RAM_map.html)

| Address Range | Size | Recommended Use |
|--------------|------|-----------------|
| $0000-$000F | 16 bytes | Local variables and function arguments |
| $0010-$00FF | 240 bytes | Global variables (frequent access), pointer tables |
| $0100-$019F | 160 bytes | Nametable update buffer (for vblank) |
| $01A0-$01FF | 96 bytes | Stack (leave room!) |
| $0200-$02FF | 256 bytes | OAM sprite buffer (for DMA copy) |
| $0300-$03FF | 256 bytes | Sound engine variables, misc globals |
| $0400-$07FF | 1024 bytes | Arrays, less-frequent globals |

**Key Principles**:
- **Zero page ($0000-$00FF)**: Faster access, required for indirect addressing
- **Stack needs space**: Don't allocate $0100-$01FF entirely - leave 96+ bytes
- **OAM at $0200**: Convention for sprite DMA (easily divisible address)
- **Plan carefully**: Only 2KB total RAM!

---

## 4. Power-Up and Reset Sequence

### PPU Power-Up State (Critical Timing!)

**Initial Register Values**:

| Register | At Power-On | After Reset |
|----------|-------------|-------------|
| PPUCTRL ($2000) | $00 | $00 |
| PPUMASK ($2001) | $00 | $00 |
| PPUSTATUS ($2002) | +0+x xxxx | U??x xxxx |
| OAMADDR ($2003) | $00 | unchanged |
| $2005/$2006 latch | cleared | cleared |
| PPUSCROLL ($2005) | $0000 | $0000 |
| PPUADDR ($2006) | $0000 | unchanged |
| PPUDATA ($2007) buffer | $00 | $00 |

**Critical Timing Constraints**:
- **~29,658 CPU cycles** must pass before writing PPUCTRL/PPUMASK/PPUSCROLL/PPUADDR
- **Internal reset signal** clears these registers during first vblank
- **Writes ignored** until end of first vblank (~27,384 cycles from power-on)
- **Other registers work immediately**: PPUSTATUS, OAMADDR, OAMDATA, PPUDATA, OAMDMA

### Standard Init Code Pattern

```assembly
reset:
    sei              ; ignore IRQs
    cld              ; disable decimal mode (compatibility)
    ldx #$40
    stx $4017        ; disable APU frame IRQ
    ldx #$ff
    txs              ; set up stack pointer
    inx              ; now X = 0
    stx $2000        ; disable NMI
    stx $2001        ; disable rendering
    stx $4010        ; disable DMC IRQs

    ; Clear vblank flag (unknown state at power-on)
    bit $2002

    ; First vblank wait (~27,384 cycles)
@vblankwait1:
    bit $2002
    bpl @vblankwait1

    ; Clear RAM during warmup period (~30,000 cycles available)
    txa              ; A = 0
@clrmem:
    sta $00,x        ; Clear page 0
    sta $100,x       ; Clear page 1
    sta $200,x       ; Clear page 2
    sta $300,x       ; Clear page 3
    sta $400,x       ; Clear page 4
    sta $500,x       ; Clear page 5
    sta $600,x       ; Clear page 6
    sta $700,x       ; Clear page 7
    inx
    bne @clrmem

    ; Second vblank wait (ensures PPU fully stabilized)
@vblankwait2:
    bit $2002
    bpl @vblankwait2

    ; Now safe to configure PPU and start rendering
```

**Key Init Requirements**:
1. **Disable interrupts** (IRQ ignore bit, NMI, APU IRQs)
2. **Disable decimal mode** (not strictly needed, but aids debugging)
3. **Initialize stack pointer** ($FF → $01FF)
4. **Disable PPU rendering** (PPUCTRL/PPUMASK = 0)
5. **Wait 2 vblanks** (30,000+ cycles for PPU warmup)
6. **Clear RAM** (between vblank waits, initialize to known state)
7. **Initialize mapper** (if banking required)

### Hardware Differences
- **Front-loading NES**: Reset button resets both CPU and PPU
- **Top-loading NES/Famicom**: Reset button only resets CPU
- **Famicom**: PPU starts ~1 frame before CPU (capacitor-based reset)
- **Some mappers**: No fixed bank (AxROM, BxROM, GxROM, MMC1 configs)
  - Must duplicate vectors and init code in each bank

---

## 5. Register Access Patterns

### CPU Internal Registers
- **Fast storage** inside CPU chip
- **Not memory-mapped** (accessed via specific instructions)
- See section 2 for list (A, X, Y, P, SP, PC)

### Memory-Mapped Registers
- **PPU registers**: $2000-$2007 (mirrored every 8 bytes)
- **APU registers**: $4000-$4017
- **Controller input**: $4016-$4017
- **Mapper registers**: Vary by mapper (e.g., $8000-$FFFF for bank switching)

**Access via CPU address space**:
- Load: `LDA $2002` (read PPUSTATUS)
- Store: `STA $2000` (write PPUCTRL)

### Common Register Roles
- **State storage**: Numbers (accumulator), flags (P register)
- **Behavior control**: PPU rendering mode, APU audio channels
- **Banking**: Mapper registers switch ROM/RAM banks
- **I/O**: Controller reads, PPU data writes

---

## 6. Hardware Limitations (Design Implications)

### Fundamental Constraints
1. **2KB RAM total** ($0000-$07FF only)
   - Must carefully plan memory layout
   - No room for large world maps without PRG RAM
   - Static allocation preferred over dynamic

2. **64 sprites maximum** (8 per scanline)
   - More than 8 on a line = flicker/dropout
   - Sprite DMA takes 513 cycles (limits vblank time)
   - OAM decay on power-on (unspecified state)

3. **16x16 pixel attribute zones** (background color)
   - Only 4 palettes for background
   - Limits color variety in tiles
   - Workarounds: Dithering, MMC5 ExGrafix, Rainbow mapper

4. **Vblank window ~2273 cycles**
   - Limited time to update VRAM
   - Can transfer ~160 bytes to nametable
   - Or update entire OAM sprite table (256 bytes via DMA)

5. **No multiplication/division** in CPU
   - Must implement in software (slow)
   - Critical for physics, 3D math, scaling

6. **CHR-ROM banking limitations**
   - 8KB CHR banks (or 4KB with advanced mappers)
   - Morphmation tricks for pseudo-3D (Rad Racer, F-1 Race)
   - CHR-RAM allows runtime graphics but requires vblank updates

### Genre-Specific Challenges

**Fighting games**:
- Sprite overdraw (8-sprite limit per scanline)
- Solution: Draw one fighter as BG tiles, other as sprites
- Limits: No jumping over opponent easily

**Puzzle games**:
- 16x16 attribute tiles limit color variety
- Solution: Dithering, single playfield, or MMC5/Rainbow mapper

**Simulation/RPG**:
- 8KB PRG RAM ceiling (rare exceptions)
- Large world maps require compression or streaming

**Driving/3D**:
- No 3D hardware
- Morphmation limits track variety
- Software rendering too slow for real-time

**Music/Rhythm**:
- 4-channel APU (limited instrumentation)
- DPCM samples cause controller read glitches
- ROM size constraints (no CD-quality audio)

---

## 7. Best Practices for Beginners

### Before You Start
1. **Learn 6502 assembly** - Fundamental requirement
2. **Understand memory-mapped I/O** - Different from modern systems
3. **Study timing and cycles** - PPU/CPU coordination is critical
4. **Accept hardware limits** - Design within constraints, don't fight them
5. **Know the tools** - Assembler (ca65, asm6), emulator (Mesen, FCEUX), debugger

### Development Workflow
1. **Test assumptions early** - Build test ROMs for subsystems
2. **Wait for PPU warmup** - Always use 2-vblank init pattern
3. **Document memory layout** - Update CODE_MAP.md before committing
4. **Plan RAM usage** - Sketch memory map before coding
5. **Budget vblank time** - Profile critical sections (~2273 cycles max)

### Common Pitfalls
- **No pre-initialized globals** - ROM only, must manually init RAM
- **Race conditions** - Can't write VRAM during rendering (wait for vblank)
- **PPU warmup violations** - Writing $2000-$2007 too early (< 29,658 cycles)
- **Stack overflow** - Need 96+ bytes stack space ($01A0-$01FF)
- **OAM sprite $00 values** - Places sprites at top-left; init with $FF to hide offscreen
- **Controller glitches** - DPCM sample playback skips bits; use Four Score signature detection

### Testing Strategy
- **Multiple emulators** - Test on Mesen, FCEUX, Nintendulator
- **Cycle-accurate debugging** - Validate timing assumptions
- **Build test ROMs** - One subsystem per test (controller, sprites, scrolling)
- **Keep test ROMs** - Reference artifacts for future work

---

## 8. Quick Reference

### Critical Memory Addresses
- `$0000-$00FF`: Zero page (fast access)
- `$0100-$01FF`: Stack
- `$0200-$02FF`: OAM buffer (sprite data)
- `$2000-$2007`: PPU registers
- `$4000-$4017`: APU/IO registers
- `$FFFA-$FFFB`: NMI vector
- `$FFFC-$FFFD`: Reset vector
- `$FFFE-$FFFF`: IRQ vector

### Essential Init Sequence
1. SEI, CLD (disable interrupts/decimal)
2. Initialize stack ($FF → SP)
3. Disable NMI, rendering, APU IRQs
4. Clear vblank flag (bit $2002)
5. Wait vblank #1
6. Clear RAM (2KB)
7. Wait vblank #2
8. Now safe to configure PPU/APU

### Timing Constraints
- **PPU warmup**: 29,658 cycles minimum
- **Vblank duration**: ~2273 cycles
- **OAM DMA**: 513 cycles
- **Sprite evaluation**: Max 8 per scanline
- **Frame rate**: 60 Hz NTSC, 50 Hz PAL

### Register Quick Reference
- **$2000 PPUCTRL**: PPU control (NMI enable, sprite size, BG pattern table)
- **$2001 PPUMASK**: Rendering enable (sprites, BG, color emphasis)
- **$2002 PPUSTATUS**: Vblank flag, sprite 0 hit (read-only)
- **$2003 OAMADDR**: OAM write address
- **$2004 OAMDATA**: OAM data port
- **$2005 PPUSCROLL**: Scroll position (write 2x: X, then Y)
- **$2006 PPUADDR**: VRAM address (write 2x: high, then low)
- **$2007 PPUDATA**: VRAM data port

---

## Sources

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Before_the_basics](https://www.nesdev.org/wiki/Before_the_basics)
- [Programming_Basics](https://www.nesdev.org/wiki/Programming_Basics)
- [Init_code](https://www.nesdev.org/wiki/Init_code)
- [Registers](https://www.nesdev.org/wiki/Registers)
- [PPU_power_up_state](https://www.nesdev.org/wiki/PPU_power_up_state)
- [Sample_RAM_map](https://www.nesdev.org/wiki/Sample_RAM_map)
- [Limitations](https://www.nesdev.org/wiki/Limitations)

