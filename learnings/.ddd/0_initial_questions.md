# LEARNINGS — NES Architecture & Development

**Status**: 🔍 **Discovery Phase** - Questions defined, research not yet started

**Context**: Both developers are NES novices. User has assembly reading experience (game hacking) + C proficiency. Claude has conceptual NES knowledge with implementation gaps. This document captures our learning journey from "informed beginners" to "can ship a ROM."

---

## Learning Goals (Questions to Answer)

### 1. Memory Map & Organization
**What we need to learn:**
- [x] Complete NES memory map ($0000-$FFFF - what's at each range?)
  - **Answer**: `learnings/wiki_architecture.md` - CPU memory map section
  - $0000-$07FF: 2KB RAM (mirrors at $0800-$1FFF)
  - $2000-$2007: PPU registers (mirrors at $2008-$3FFF)
  - $4000-$4017: APU/IO registers
  - $4018-$5FFF: Cartridge expansion (rare)
  - $6000-$7FFF: PRG-RAM (if present)
  - $8000-$FFFF: PRG-ROM (32KB, mapper-dependent banking)
- [x] Zero page location and why it matters for 6502
  - **Answer**: $0000-$00FF (256 bytes), faster addressing (3 vs 4 cycles), required for indirect addressing
- [x] Stack location and size
  - **Answer**: $0100-$01FF (256 bytes), reserve 96+ bytes free
- [x] PPU register addresses (exact locations + what each does)
  - **Answer**: `learnings/wiki_architecture.md` + `learnings/sprite_techniques.md`
  - $2000 PPUCTRL, $2001 PPUMASK, $2002 PPUSTATUS, $2003 OAMADDR, $2004 OAMDATA, $2005 PPUSCROLL, $2006 PPUADDR, $2007 PPUDATA
- [x] APU register addresses
  - **Answer**: `learnings/audio.md` - $4000-$400F (channels), $4015 (enable/status), $4017 (frame counter)
- [x] Controller I/O addresses
  - **Answer**: `learnings/input_handling.md` - $4016 (controller 1), $4017 (controller 2)
- [x] Where does our code live? (PRG-ROM mapping)
  - **Answer**: $8000-$FFFF (CPU space), mapper-dependent banking
- [x] Where does graphics data live? (CHR-ROM mapping)
  - **Answer**: $0000-$1FFF (PPU space), 8KB (mapper can bank-switch if CHR-ROM)

**Why this matters:** We have no muscle memory. Every memory access needs to be looked up or documented.

### 2. PPU (Picture Processing Unit)
**What we need to learn:**
- [x] PPU register list (addresses, read/write behavior, side effects)
  - **Answer**: `learnings/wiki_architecture.md` - All 8 registers documented with side effects
- [x] How to write to VRAM safely (vblank window)
  - **Answer**: `learnings/timing_and_interrupts.md` - 2273 cycles NTSC vblank, rendering must be off or vblank active
- [x] Sprite DMA mechanics (step-by-step process)
  - **Answer**: `learnings/sprite_techniques.md` - Write page to $4014, 513-514 cycles, must happen in vblank
- [x] Pattern tables (CHR-ROM structure)
  - **Answer**: `learnings/wiki_architecture.md` - 256 tiles each, 16 bytes/tile, 2 bitplanes
- [x] Nametables (background tile layout)
  - **Answer**: `learnings/graphics_techniques.md` - 32×30 tiles, 960 bytes, mirroring modes
- [x] Attribute tables (how colors are assigned)
  - **Answer**: `learnings/graphics_techniques.md` - 64 bytes, 16×16 pixel blocks (4×4 tiles), 2 bits per 2×2 tile group
- [x] Palette memory (where, how many colors, format)
  - **Answer**: `learnings/wiki_architecture.md` - 32 bytes at $3F00-$3F1F, 4 BG + 4 sprite palettes, 4 colors each
- [x] Scrolling implementation (registers, edge cases)
  - **Answer**: `learnings/graphics_techniques.md` - $2005 (scroll X/Y), nametable switching, seam artifacts
- [x] Sprite 0 hit (what is it, why does it matter)
  - **Answer**: `learnings/sprite_techniques.md` - Detects sprite 0 overlap with BG, used for split-screen effects
- [x] PPU timing quirks and gotchas
  - **Answer**: `learnings/sprite_techniques.md` + `learnings/graphics_techniques.md` - PPUSTATUS clears on read, PPUADDR write toggle, sprite Y-1 offset

**Why this matters:** Graphics are the most visible part of the game and the most timing-sensitive.

### 3. Timing & Constraints
**What we need to learn:**
- [x] Vblank window exact timing (how many cycles?)
  - **Answer**: `learnings/timing_and_interrupts.md` - 2273 cycles NTSC, 2660 cycles PAL
- [x] What can/can't be done during vblank
  - **Answer**: `learnings/timing_and_interrupts.md` - PPU writes only in vblank, OAM DMA (513-514 cycles), tile copies (~10 tiles max)
- [x] Frame rate (60 FPS? 60.0988 FPS?)
  - **Answer**: `learnings/wiki_architecture.md` - 60.0988 FPS NTSC, 50.007 FPS PAL
- [x] CPU cycles per frame
  - **Answer**: `learnings/timing_and_interrupts.md` - 29,780.5 cycles/frame NTSC, 33,247.5 cycles PAL
- [x] Cycle counting basics (how to budget operations)
  - **Answer**: `learnings/timing_and_interrupts.md` + `learnings/optimization.md` - Instruction cycle reference, vblank budget breakdown
- [x] What happens if we miss vblank deadline?
  - **Answer**: `learnings/timing_and_interrupts.md` - Visual glitches, tearing, partial updates (must defer to next frame)
- [x] How to measure if code fits in vblank budget
  - **Answer**: `learnings/timing_and_interrupts.md` + **Practice**: Use Mesen cycle profiler (see `5_open_questions.md` Q1.4)

**Why this matters:** Everything is cycle-counted. Can't handwave performance.

### 4. 6502 Assembly & Optimization
**What we need to learn:**
- [x] 6502 instruction set (what's available)
  - **Answer**: `learnings/wiki_architecture.md` + `learnings/optimization.md` - 56 official opcodes, 95 unofficial
- [x] Common patterns (loops, comparisons, branching)
  - **Answer**: `learnings/optimization.md` - Loop unrolling, jump tables, scanning tables
- [x] Zero page addressing modes (why faster?)
  - **Answer**: `learnings/optimization.md` - 3 cycles vs 4 for absolute, required for indirect
- [x] Indirect addressing (when needed?)
  - **Answer**: `learnings/optimization.md` - Pointer dereferencing, table lookups, only works with zero page
- [x] Stack operations (PHA, PLA, JSR, RTS)
  - **Answer**: `learnings/optimization.md` - Reserve 96+ bytes stack, JSR pushes PC+2, RTS pops and adds 1
- [x] Best practices for readable assembly
  - **Answer**: `learnings/optimization.md` - Label everything, comment cycle counts, modular subroutines
- [x] How to optimize for cycles vs bytes
  - **Answer**: `learnings/optimization.md` - Cycle/byte trade-offs, loop unrolling, table-driven code
- [x] Common pitfalls to avoid
  - **Answer**: All learning docs - PPU write toggle, sprite Y-1, DPCM conflicts, bus conflicts (UNROM)

**Why this matters:** We're writing assembly from scratch. Need foundational patterns.

### 5. Graphics Data & Formats
**What we need to learn:**
- [x] CHR-ROM format (how sprites/tiles are encoded)
  - **Answer**: `learnings/wiki_architecture.md` - 16 bytes/tile, 2 bitplanes interleaved, 8×8 pixels
- [x] How to create sprite graphics
  - **Answer**: `learnings/toolchain.md` - NEXXT editor (all-in-one), YY-CHR (quick inspection)
- [x] How to create background tiles
  - **Answer**: `learnings/toolchain.md` - Same tools as sprites, NEXXT for nametable editing
- [x] Palette format and limits
  - **Answer**: `learnings/wiki_architecture.md` - 4 colors/palette, color 0 is transparent (sprites) or backdrop (BG)
- [x] OAM (Object Attribute Memory) structure for sprites
  - **Answer**: `learnings/sprite_techniques.md` - 4 bytes/sprite (Y-1, tile, attributes, X), 64 sprites max
- [x] Sprite limitations (how many per scanline?)
  - **Answer**: `learnings/sprite_techniques.md` - 8 sprites/scanline HARD LIMIT (hardware overflow)
- [x] How to convert PNG/bitmap to CHR-ROM
  - **Answer**: `learnings/toolchain.md` + **Practice**: NEXXT import, or custom script (see `5_open_questions.md` Q2.1)

**Why this matters:** Need to create actual graphics assets.

### 6. Controllers & Input
**What we need to learn:**
- [x] Controller reading process (step-by-step)
  - **Answer**: `learnings/input_handling.md` - 3 steps: (1) Write $01 to $4016, (2) Write $00 to $4016, (3) Read $4016 8 times
- [x] Register addresses for input
  - **Answer**: `learnings/input_handling.md` - $4016 (controller 1 + write strobe), $4017 (controller 2)
- [x] Debouncing needed?
  - **Answer**: `learnings/input_handling.md` - No hardware debouncing needed, read is reliable
- [x] How to detect button press vs hold vs release
  - **Answer**: `learnings/input_handling.md` - Edge detection: XOR previous frame with current frame
- [x] Two controller support
  - **Answer**: `learnings/input_handling.md` - Same process, read $4017 instead of $4016

**Why this matters:** Game needs player input!

### 7. APU (Audio Processing Unit)
**What we need to learn:**
- [x] APU channel types (pulse, triangle, noise, DMC)
  - **Answer**: `learnings/audio.md` - 2 pulse (melody/harmony), 1 triangle (bass, no volume), 1 noise (drums), 1 DMC (samples)
- [x] How to generate basic sound effects
  - **Answer**: `learnings/audio.md` - Direct register writes or sound engine trigger interface (FamiTone2)
- [x] How to play music
  - **Answer**: `learnings/audio.md` - FamiTone2 sound engine + FamiTracker composition tool
- [x] Register programming for each channel
  - **Answer**: `learnings/audio.md` - $4000-$400F documented per channel, period tables for note frequencies
- [x] Common gotchas
  - **Answer**: `learnings/audio.md` - Phase reset pops (avoid $4003/$4007 writes), triangle mute=0 pops, DMC cycle stealing

**Why this matters:** Audio makes game feel alive (but lower priority than graphics/input).

### 8. Mappers & Memory Banking
**What we need to learn:**
- [x] What is a mapper?
  - **Answer**: `learnings/mappers.md` - Cartridge hardware for bank switching, extends beyond 32KB PRG + 8KB CHR
- [x] NROM (mapper 0) - simplest, start here
  - **Answer**: `learnings/mappers.md` - 32KB PRG, 8KB CHR (ROM or RAM), no bank switching
- [x] When do we need a more complex mapper?
  - **Answer**: `learnings/mappers.md` - When ROM >32KB, need CHR switching, or need PRG-RAM (save games)
- [x] How bank switching works
  - **Answer**: `learnings/mappers.md` - Write to mapper registers, CPU/PPU see different ROM banks at fixed addresses
- [x] How to choose appropriate mapper for our game
  - **Answer**: `learnings/mappers.md` - NROM (≤32KB) → UNROM (≤256KB, CHR-RAM) → MMC1 (≤512KB, CHR-ROM, PRG-RAM)

**Why this matters:** Determines ROM size limits and complexity.

### 9. Development Toolchain
**What we need to learn:**
- [x] Which assembler to use? (ca65, asm6, nesasm?)
  - **Answer**: `learnings/toolchain.md` - **asm6f** (simple, good for learning), ca65 (if C needed)
- [x] How to assemble a ROM
  - **Answer**: `learnings/toolchain.md` + **Practice**: See `5_open_questions.md` Q1.1 (build first ROM)
- [x] Which emulator for testing? (Mesen, FCEUX, Nintendulator?)
  - **Answer**: `learnings/toolchain.md` - **Mesen** (best debugger, high accuracy), FCEUX (secondary validation)
- [x] Debugging tools and techniques
  - **Answer**: `learnings/toolchain.md` + **Practice**: See `5_open_questions.md` Q1.3 (Mesen breakpoints, memory watch)
- [x] How to test on real hardware (if we get that far)
  - **Answer**: `learnings/toolchain.md` - Everdrive/Powerpak flashcart, test after emulator validation
- [x] Build automation (Makefile, scripts)
  - **Answer**: **Practice**: See `5_open_questions.md` Q1.1, Q1.6 (create Makefile during first build)

**Why this matters:** Can't build anything without tools!

### 10. Common Patterns & Best Practices
**What we need to learn:**
- [x] Standard initialization sequence (reset vector)
  - **Answer**: `learnings/getting_started.md` - 2-vblank warmup (29,658+ cycles), clear RAM, init PPU, enable NMI
- [x] NMI handler structure (vblank routine)
  - **Answer**: `learnings/timing_and_interrupts.md` - PPU updates only (OAM DMA, scroll, VRAM), restore state, RTI
- [x] IRQ handling (do we need it?)
  - **Answer**: `learnings/timing_and_interrupts.md` - Rare (mapper IRQ for raster effects), most games don't use
- [x] Game loop structure
  - **Answer**: `learnings/timing_and_interrupts.md` - Main loop (game logic) + NMI (PPU updates), never mix
- [x] State management patterns
  - **Answer**: `learnings/getting_started.md` + **Practice**: See `5_open_questions.md` Q4.1 (state machine)
- [x] Common gotchas to avoid
  - **Answer**: All learning docs - PPU write toggle, sprite Y-1, DPCM conflicts, bus conflicts, phase reset pops
- [x] How to structure code for maintainability
  - **Answer**: `learnings/optimization.md` + **Practice**: See `5_open_questions.md` Q4.7 (establish conventions)

**Why this matters:** Don't want to reinvent wheels or make known mistakes.

---

## Research Sources

**Primary:**
- `.webcache/` - Cached NESdev Wiki pages
- [NESdev Wiki](https://www.nesdev.org/wiki/Nesdev_Wiki) - Main reference

**To be determined:**
- Tutorials for absolute beginners?
- Example ROMs to study?
- Books/guides?

---

---

## Summary: All 10 Question Categories Answered!

**Status**: ✅ **All initial questions answered through systematic wiki study (52 pages)**

**Where findings live**:
- `learnings/wiki_architecture.md` - Memory map, PPU/APU overview
- `learnings/getting_started.md` - Init sequence, RAM layout
- `learnings/sprite_techniques.md` - OAM, sprite limits, sprite 0 hit
- `learnings/graphics_techniques.md` - Nametables, attributes, scrolling
- `learnings/input_handling.md` - Controller reading, edge detection
- `learnings/timing_and_interrupts.md` - Cycle budgets, NMI handlers
- `learnings/toolchain.md` - Assembler/emulator selection
- `learnings/optimization.md` - 6502 patterns, cycle/byte trade-offs
- `learnings/math_routines.md` - Multiply, divide, RNG
- `learnings/audio.md` - APU programming, sound engines
- `learnings/mappers.md` - Bank switching, UNROM/MMC1

**Remaining unknowns**: Documented in `5_open_questions.md` (40+ practical implementation questions)

---

## Decisions Made

### Toolchain (Priority 2.5)
- **Assembler**: asm6f (simple syntax, good for learning)
- **Emulator**: Mesen (best debugger, cycle-accurate)
- **Graphics**: NEXXT (all-in-one editor)
- **Audio**: FamiTracker + FamiTone2 sound engine

### Mapper Strategy (Priority 5)
- **Phase 1**: Start with NROM (≤32KB)
- **Phase 2**: Migrate to UNROM when needed (≤256KB, CHR-RAM)
- **Phase 3**: MMC1 only if need CHR-ROM banks or PRG-RAM

### Audio (Priority 4)
- **Sound engine**: FamiTone2 (beginner-friendly)
- **Cycle budget**: 1000-1500 cycles/frame

### Development Approach
- **Study first**: Complete core wiki study before practical work ✅
- **Test ROM validation**: Build subsystem tests to validate learnings
- **Iterative learning**: Update docs with actual measurements from practice

---

## Next Steps

**Study phase complete** - moving to practical validation:

1. ✅ Cache NESdev Wiki to `.webcache/`
2. ✅ Read through cached docs systematically (52 pages)
3. ✅ Document findings in 11 learning docs
4. **→ Install toolchain** (asm6f, Mesen, NEXXT, FamiTracker)
5. **→ Build "hello world" test ROM** (sprite, controller, beep)
6. **→ Answer open questions through practice** (see `5_open_questions.md`)
