# PHASE 2 — Learning Progress Assessment

**Date**: October 2025
**Phase**: Systematic wiki study complete through Priority 2
**Status**: Ready for practical application (test ROMs) or deeper optimization study

---

## Questions Answered (from INITIAL.md)

### ✅ 1. Memory Map & Organization (COMPLETE)
**Documented in**: `learnings/wiki_architecture.md`, `learnings/getting_started.md`

- [x] Complete NES memory map ($0000-$FFFF) → **Fully documented**
- [x] Zero page location ($0000-$00FF) and why it matters → **Fastest addressing mode**
- [x] Stack location ($0100-$01FF) and size → **256 bytes LIFO, need 96+ free**
- [x] PPU register addresses ($2000-$2007) → **All registers documented with side effects**
- [x] APU register addresses ($4000-$4017) → **All channels documented**
- [x] Controller I/O addresses ($4016-$4017, $4014) → **Strobe protocol documented**
- [x] PRG-ROM mapping → **$8000-$FFFF (or banked via mapper)**
- [x] CHR-ROM mapping → **PPU $0000-$1FFF (pattern tables)**

**Key insight**: PPU and CPU have separate memory buses. No shared RAM between them.

### ✅ 2. PPU (Picture Processing Unit) (COMPLETE)
**Documented in**: `learnings/wiki_architecture.md`, `learnings/sprite_techniques.md`, `learnings/graphics_techniques.md`

- [x] PPU register list → **$2000-$2007 fully documented**
- [x] How to write to VRAM safely → **Vblank window only, 2273 cycle budget**
- [x] Sprite DMA mechanics → **513-514 cycles, $4014 register, page-aligned buffer**
- [x] Pattern tables → **$0000-$0FFF (left), $1000-$1FFF (right), 16 bytes/tile**
- [x] Nametables → **4x 1KB tables at $2000-$2FFF (mirrored)**
- [x] Attribute tables → **64 bytes per nametable, 16x16 pixel zones**
- [x] Palette memory → **32 bytes at $3F00-$3F1F, 4 BG + 4 sprite palettes**
- [x] Scrolling implementation → **PPUSCROLL register, split-screen techniques**
- [x] Sprite 0 hit → **Opaque pixel overlap detection for status bar splits**
- [x] PPU timing quirks → **Power-up warmup, write toggle resets, palette mirroring**

**Key insight**: 8-sprite-per-scanline limit is HARD (hardware overflow, use flicker rotation).

### ✅ 3. Timing & Constraints (COMPLETE)
**Documented in**: `learnings/wiki_architecture.md`, `learnings/timing_and_interrupts.md`

- [x] Vblank window exact timing → **2273 cycles NTSC (20 scanlines), 2660 PAL**
- [x] What can/can't be done during vblank → **Only PPU writes, budget carefully**
- [x] Frame rate → **60.0988 FPS NTSC, 50.007 PAL**
- [x] CPU cycles per frame → **29780.5 NTSC, 33247.5 PAL**
- [x] Cycle counting basics → **Min 2 cycles/instruction, +1 per memory access, +1 page cross**
- [x] Missing vblank deadline → **Tearing, partial updates, frame skip**
- [x] How to measure vblank fit → **Count instruction cycles, clockslide technique for variable delays**

**Key insight**: Vblank priority order: OAM DMA → scroll updates → VRAM → music → game logic.

### ✅ 4. 6502 Assembly & Optimization (PARTIAL)
**Documented in**: `learnings/getting_started.md`

- [x] 6502 instruction set → **56 instructions, 3-letter mnemonics**
- [x] Common patterns → **Loops, comparisons, branching basics**
- [x] Zero page addressing → **3 cycles vs 4 for absolute, required for indirect**
- [x] Indirect addressing → **Zero page only, (addr),Y for tables**
- [x] Stack operations → **PHA/PLA (3 cycles), JSR/RTS (6 cycles)**
- [x] Best practices → **Comment heavily, label meaningfully, document cycle counts**
- [ ] **Optimization techniques → NOT YET COVERED (Priority 3)**
- [ ] **Cycle vs byte tradeoffs → NOT YET COVERED (Priority 3)**

**Gap**: Advanced optimization patterns (RTS trick, jump tables, synthetic instructions) in Priority 3.

### ✅ 5. Graphics Data & Formats (COMPLETE)
**Documented in**: `learnings/wiki_architecture.md`, `learnings/sprite_techniques.md`, `learnings/graphics_techniques.md`

- [x] CHR-ROM format → **16 bytes per 8x8 tile (2 bitplanes)**
- [x] How to create sprites → **8x8 or 8x16 modes, pattern table indexing**
- [x] How to create backgrounds → **Nametable + attribute table + pattern table**
- [x] Palette format → **6-bit color indices, 4 colors per palette**
- [x] OAM structure → **4 bytes per sprite (Y, tile, attr, X)**
- [x] Sprite limitations → **64 total, 8 per scanline (hardware limit)**
- [ ] **PNG to CHR-ROM conversion → Tools not yet chosen**

**Gap**: Practical tools for graphics conversion (Priority: toolchain).

### ✅ 6. Controllers & Input (COMPLETE)
**Documented in**: `learnings/wiki_architecture.md`, `learnings/input_handling.md`

- [x] Controller reading process → **Strobe $4016 bit 0, read 8 times (A,B,Select,Start,U,D,L,R)**
- [x] Register addresses → **$4016 (controller 1), $4017 (controller 2)**
- [x] Debouncing → **Not needed in hardware, but edge detection for "newly pressed"**
- [x] Press vs hold vs release → **Compare current frame vs previous frame**
- [x] Two controller support → **Both read from same strobe, separate data lines**

**Key insight**: DPCM playback can glitch controller reads (use $4017 disable or read multiple times).

### ⚠️ 7. APU (Audio Processing Unit) (OVERVIEW ONLY)
**Documented in**: `learnings/wiki_architecture.md`

- [x] APU channel types → **2 pulse, 1 triangle, 1 noise, 1 DMC**
- [x] Register programming → **$4000-$4017 documented with basic usage**
- [ ] **How to generate sound effects → NOT YET COVERED (Priority 4)**
- [ ] **How to play music → NOT YET COVERED (Priority 4)**
- [ ] **Common gotchas → Partially covered (DMC IRQ conflicts)**

**Gap**: Practical audio implementation (sound engines, music drivers) in Priority 4.

### ⚠️ 8. Mappers & Memory Banking (OVERVIEW ONLY)
**Documented in**: `learnings/wiki_architecture.md`

- [x] What is a mapper → **Cartridge hardware extending ROM/RAM**
- [x] NROM (mapper 0) → **32KB PRG + 8KB CHR, no banking**
- [ ] **When to use complex mappers → General guidance only**
- [ ] **How bank switching works → Overview only, not implementation details**
- [ ] **Choosing mapper → NOT YET COVERED (Priority 5)**

**Gap**: Specific mapper implementation (UNROM, MMC1) in Priority 5.

### ❌ 9. Development Toolchain (NOT COVERED)
**Status**: No documents yet

- [ ] **Assembler choice → NOT DECIDED**
- [ ] **How to assemble ROM → NOT COVERED**
- [ ] **Emulator for testing → NOT DECIDED**
- [ ] **Debugging tools → NOT COVERED**
- [ ] **Real hardware testing → NOT COVERED**
- [ ] **Build automation → NOT COVERED**

**Gap**: Critical for moving from theory to practice. Need assembler + emulator to build test ROMs.

### ✅ 10. Common Patterns & Best Practices (COMPLETE)
**Documented in**: `learnings/getting_started.md`, `learnings/timing_and_interrupts.md`

- [x] Standard init sequence → **2-vblank warmup pattern (29,658+ cycles before PPU writes)**
- [x] NMI handler structure → **Main-only, NMI-only, NMI+main hybrid patterns**
- [x] IRQ handling → **Not commonly used (mappers provide IRQ for raster effects)**
- [x] Game loop structure → **Main loop + NMI interrupt, vblank budget management**
- [x] State management → **RAM layout conventions ($0200-$02FF OAM, etc.)**
- [x] Common gotchas → **PPU write toggle, sprite Y-1 offset, DPCM conflicts**
- [x] Code structure → **Modular subroutines, interrupt forwarding for rapid dev**

**Key insight**: NMI handler = PPU-only updates. Main loop = game logic. Never mix.

---

## Questions Raised (New Unknowns)

### ✅ 🔧 Toolchain Decisions (ANSWERED IN PRIORITY 2.5)
1. **Which assembler?** ✅ **ANSWERED**
   - **Decision**: `learnings/toolchain.md` - **asm6f** (simple syntax, good for learning)
   - Alternative: ca65 if C integration needed
2. **Which emulator?** ✅ **ANSWERED**
   - **Decision**: `learnings/toolchain.md` - **Mesen** (best debugger, cycle-accurate, Mac support)
   - Secondary: FCEUX for cross-validation
3. **Graphics tools?** ✅ **ANSWERED**
   - **Decision**: `learnings/toolchain.md` - **NEXXT** (all-in-one editor), YY-CHR (quick inspection)
   - **Practice needed**: PNG → CHR workflow (see `5_open_questions.md` Q2.1)
4. **Build automation?** ⏳ **NEEDS PRACTICE**
   - **Theory**: Makefile for multi-step builds
   - **Practice**: Create during first ROM build (see `5_open_questions.md` Q1.1, Q1.6)

### 🎨 Graphics Asset Pipeline
5. **How to design tiles?** ⏳ **NEEDS PRACTICE**
   - **Theory**: `learnings/toolchain.md` - NEXXT for direct editing, 4-color constraint per palette
   - **Practice**: Create placeholder graphics (see `5_open_questions.md` Q2.1-Q2.2)
6. **Metatile systems?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/graphics_techniques.md` - 2×2 or 4×4 tile groups, compressed level data
   - **Practice**: Implement metatile system (see `5_open_questions.md` Q2.3)
7. **Palette design?** ⏳ **NEEDS PRACTICE**
   - **Theory**: `learnings/wiki_architecture.md` - 4 colors/palette, NES palette chart
   - **Practice**: Pick palettes for test ROM (see `5_open_questions.md` Q2.2)

### ✅ 🎵 Audio Implementation (ANSWERED IN PRIORITY 4)
8. **Sound engine architecture?** ✅ **ANSWERED**
   - **Decision**: `learnings/audio.md` - **FamiTone2** (beginner-friendly, well-documented)
   - Alternative: FamiStudio engine if richer features needed
9. **Music format?** ✅ **ANSWERED**
   - **Theory**: `learnings/audio.md` - FamiTracker .ftm → text2data → .asm include
   - **Practice**: Set up build pipeline (see `5_open_questions.md` Q3.5)
10. **SFX priority?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/audio.md` - Priority by channel, priority by type, ducking strategies
   - **Practice**: Implement SFX system (see `5_open_questions.md` Q3.2)

### 🎮 Game Architecture (NEEDS PRACTICE)
11. **State machine patterns?** ⏳ **NEEDS PRACTICE**
   - **Theory**: State byte in zero page, jump table for handlers
   - **Practice**: Implement in game prototype (see `5_open_questions.md` Q4.1)
12. **Entity systems?** ⏳ **NEEDS PRACTICE**
   - **Theory**: Array of structs (x, y, velocity, type, state), pool allocation
   - **Practice**: Implement enemy manager (see `5_open_questions.md` Q4.2)
13. **Collision detection?** ⏳ **NEEDS PRACTICE**
   - **Theory**: AABB (Axis-Aligned Bounding Box) standard approach
   - **Practice**: Implement in platformer test (see `5_open_questions.md` Q4.3-Q4.4)
14. **Level streaming?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/graphics_techniques.md` - Stream nametable columns/rows during scroll
   - **Practice**: Implement scrolling level (see `5_open_questions.md` Q4.5-Q4.6)

### 🔬 Advanced Techniques (PARTIALLY ANSWERED)
15. **CHR-RAM streaming?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/mappers.md` - ~10 tiles/frame (160 bytes) in vblank
   - **Practice**: Measure actual performance (see `5_open_questions.md` Q7.2)
16. **Raster effects?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/graphics_techniques.md` - Sprite 0 hit, MMC3 IRQ for mid-frame changes
   - **Practice**: Implement split-screen effect in test ROM
17. **Compression?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/optimization.md` - RLE, LZ, fixed-bit encoding
   - **Theory**: `learnings/mappers.md` - CHR-RAM enables compression (Konami/Codemasters)
   - **Practice**: Measure decompression cost (see `5_open_questions.md` Q6.2)
18. **Mapper-specific features?** ✅ **PARTIALLY ANSWERED**
   - **Theory**: `learnings/mappers.md` - MMC1 serial protocol, UNROM bus conflicts
   - **Practice**: Implement mapper tests (see `5_open_questions.md` Q5.1-Q5.6, Q7.1)

---

## Decisions Made

### ✅ Documentation Strategy
- **mdbook target**: Learnings will be compiled into agent-friendly NES reference
- **Clear, concise language**: Works for both LLMs and humans
- **Practical focus**: Code patterns, cycle budgets, gotchas over history

### ✅ Study Approach
- **Systematic wiki caching**: tools/fetch-wiki.sh for offline reference
- **Priority-driven**: Core concepts → techniques → optimization → audio → mappers
- **Topic-specific docs**: Separate learnings for sprites, graphics, input, timing

### ✅ Development Philosophy
- **Test ROMs first**: Validate understanding before main game
- **Discovery mode**: LEARNINGS.md (goals) → build → LEARNINGS.md (findings)
- **Constraint-aware**: Design within hardware limits from day 1

### ⏳ Pending Decisions
- **Assembler choice**: Need to evaluate options (ca65 vs asm6 vs nesasm3)
- **Emulator choice**: Need Mac-compatible, debugger-friendly option
- **Game concept**: What are we building? (deferred until tools ready)

---

## Next Steps

### Option A: Complete Toolchain Setup (RECOMMENDED)
**Why**: Can't validate learnings without building test ROMs
1. Research assemblers (ca65, asm6, nesasm3) → choose one
2. Research emulators (Mesen, FCEUX, Nintendulator) → choose one (Mac-compatible)
3. Write "hello world" ROM (display sprite)
4. Document toolchain setup in `learnings/toolchain.md`
5. Create build scripts (tools/build.sh or Makefile)

### Option B: Continue Systematic Study (Priority 3)
**Why**: Deeper 6502 knowledge before practical work
1. Study 19 Priority 3 pages (optimization, math, compression)
2. Create `learnings/optimization.md` and `learnings/math_routines.md`
3. Then proceed to toolchain setup

### Option C: Define Game Concept (PREMATURE)
**Why**: Should validate basic techniques first
1. ❌ Skip for now - need test ROM experience first

---

## Summary

**Study Progress**: 21/100+ wiki pages (21%)
**Core Knowledge**: ✅ Complete (memory, PPU, timing, input, init patterns)
**Gaps**: Toolchain, audio implementation, mapper details, optimization
**Blocker**: No assembler/emulator chosen yet

**Recommendation**: Focus on toolchain setup (Option A). We have enough theory to start practical experiments. Test ROMs will reveal knowledge gaps better than more reading.
