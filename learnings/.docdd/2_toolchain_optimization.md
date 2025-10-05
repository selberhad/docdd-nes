# PHASE 3 — Toolchain & Optimization Study Complete

**Date**: October 2025
**Phase**: Priority 2.5 (Toolchain) + Priority 3 (Programming Techniques) complete
**Status**: Ready for audio study (Priority 4), then mappers (Priority 5)

---

## What We Studied

### Priority 2.5: Development Toolchain (3 pages)
**Documented in**: `learnings/toolchain.md`

- Tools overview (assemblers, graphics, audio, debugging)
- Emulator comparison (accuracy, features, platform support)
- Test ROM validation suites

### Priority 3: Programming Techniques (19 pages)
**Documented in**: `learnings/optimization.md`, `learnings/math_routines.md`

#### 6502 Optimization (9 pages):
- Assembly optimization patterns
- RTS trick for function dispatch
- Jump tables and scanning tables
- Synthetic instructions
- Unofficial opcodes
- Pointer tables
- Multibyte constants

#### Math Routines (9 pages):
- Multiplication (constant, fast signed, 8-bit)
- Division (constant, general, divide by 3)
- BCD conversion (16-bit)
- Base 100 number representation
- Random number generation

#### Data Compression (2 pages):
- Compression overview
- Fixed bit length encoding

---

## Key Insights Gained

### Toolchain Decisions Made
1. **Assembler: asm6f** (recommended)
   - Simple syntax, good for learning
   - Symbol file generation for debugging
   - NES 2.0 header support
   - Alternative: CC65 if C development desired

2. **Emulator: Mesen** (primary)
   - Excellent debugger (breakpoints, memory viewer, trace logging)
   - High accuracy
   - Mac support via .NET
   - Secondary: FCEUX for cross-validation

3. **Graphics: NEXXT**
   - All-in-one CHR/nametable/sprite/palette editor
   - Alternative: YY-CHR for quick inspection

4. **Audio: FamiTracker**
   - Industry standard tracker
   - FamiTone2/5 for runtime playback

5. **Testing: blargg test ROM suite**
   - Run BEFORE integrating new subsystems
   - nestest for CPU validation

### Optimization Principles Learned
1. **Cycle/byte trade-offs are REAL**
   - Speed optimization often costs ROM space
   - Size optimization often costs cycles
   - Must choose based on bottleneck (vblank vs ROM size)

2. **Zero page is PRECIOUS**
   - Only 256 bytes total
   - 3 cycles vs 4 for absolute addressing
   - Required for indirect addressing
   - Reserve for hot variables and pointers

3. **Unrolling trade-offs**
   - Loop unrolling: +speed, -size
   - Worth it for tight vblank operations
   - Not worth it for non-critical code

4. **Table-driven code is FAST**
   - Jump tables: 13-17 cycles vs cascading compares
   - Lookup tables: eliminate runtime computation
   - Trade ROM space for speed

5. **Unofficial opcodes are RISKY**
   - Useful for optimization (LAX, SAX, etc.)
   - Not all stable across chip revisions
   - Test on real hardware if using

### Math Implementation Realities
1. **No multiply/divide hardware**
   - Must implement via shift-add/subtract
   - Constant multiplication: optimize via shifts
   - General multiply: ~200-300 cycles
   - Division even slower

2. **BCD useful for scores**
   - Base 100 more efficient than BCD for 6502
   - Eliminates decimal mode (not available on NES 2A03)
   - Direct decimal display without conversion

3. **RNG needs care**
   - LFSR standard (Galois configuration)
   - 16-bit for better period
   - Seed from user input/frame count

### Compression Insights
1. **Fixed-bit encoding basics**
   - Pack multiple small values per byte
   - 2-bit (0-3) → 4 per byte
   - 3-bit (0-7) → 2 per byte + 2 bits wasted
   - 4-bit (0-15) → 2 per byte (nibbles)

2. **Domain-specific compression**
   - Tile compression (RLE, LZ variants)
   - Metatiles (covered in graphics_techniques.md)
   - Text compression (dictionary, Huffman)
   - Level data (run-length, pattern-based)

---

## Questions Raised

### Tool Integration
1. **Build pipeline**: How to integrate asm6f + NEXXT + FamiTracker?
   - Makefile? Shell script?
   - Auto-convert graphics assets?
   - Assemble + link CHR data?

2. **Debugging workflow**: How to use Mesen debugger effectively?
   - Symbol file integration?
   - Breakpoint strategies?
   - Memory watch patterns?

3. **Testing strategy**: When to run test ROMs?
   - Before first build?
   - After each subsystem?
   - Continuous validation?

### Optimization Strategy
4. **When to optimize**: Premature vs necessary?
   - Optimize vblank code always?
   - Profile first for non-critical code?
   - How to measure cycle usage?

5. **Zero page allocation**: How to manage 256 bytes?
   - Reserve ranges for different subsystems?
   - Document in CODE_MAP.md?
   - Naming conventions?

6. **Unofficial opcode policy**: Use or avoid?
   - Acceptable for speed-critical paths?
   - Test coverage required?
   - Fallback for incompatible hardware?

### Math & Data
7. **When to use math routines**: Cost/benefit?
   - Avoid division in gameplay loop?
   - Pre-compute tables where possible?
   - Fixed-point vs integer math?

8. **Compression trade-offs**: Decompression cost?
   - RLE fast enough for vblank?
   - LZ too slow for real-time?
   - Pre-decompress to RAM vs stream?

---

## Decisions Pending

### Toolchain Setup (PRACTICAL WORK REQUIRED)
- [ ] Install asm6f on development machine → **See `5_open_questions.md` Q1.1**
- [ ] Install Mesen emulator (Mac .NET version) → **See `5_open_questions.md` Q1.1**
- [ ] Download blargg test ROM suite → **See `5_open_questions.md` Q1.5**
- [ ] Install NEXXT graphics editor → **See `5_open_questions.md` Q1.7**
- [ ] Install FamiTracker (or alternative) → **See `5_open_questions.md` Q3.4**

### Coding Conventions (THEORY DOCUMENTED, PRACTICE NEEDED)
- [ ] Zero page allocation map (document in CODE_MAP.md)
  - **Theory**: `learnings/optimization.md` - Reserve for hot variables, pointers
  - **Practice**: Create allocation map → **See `5_open_questions.md` Q6.3**
- [ ] Optimization policy (when to use advanced techniques)
  - **Theory**: `learnings/optimization.md` - Cycle/byte trade-offs documented
  - **Practice**: Establish policy → **See `5_open_questions.md` Q6.1**
- [ ] Unofficial opcode policy (allowed or forbidden)
  - **Theory**: `learnings/optimization.md` - Risky, chip revision differences
  - **Decision**: Avoid unless bottleneck proven → **See `5_open_questions.md` Q6.5**
- [ ] Comment style for cycle-critical code
  - **Theory**: `learnings/optimization.md` - Document cycle counts
  - **Practice**: Establish conventions → **See `5_open_questions.md` Q4.7**
- [ ] Math routine library organization
  - **Theory**: `learnings/math_routines.md` - All routines documented
  - **Practice**: Organize into .asm library

### Build System (PRACTICAL WORK REQUIRED)
- [ ] Create Makefile or build script → **See `5_open_questions.md` Q1.1, Q1.6**
- [ ] CHR asset build integration → **See `5_open_questions.md` Q1.7**
- [ ] Music data build integration → **See `5_open_questions.md` Q3.5**
- [ ] Symbol file generation for debugging → **See `5_open_questions.md` Q1.2**
- [ ] Test ROM validation step → **See `5_open_questions.md` Q1.5**

---

## Study Progress Summary

**Wiki Pages Studied**: 43/100+ (43%)
- Priority 1: Getting Started (7 pages) ✅
- Priority 2: Essential Techniques (14 pages) ✅
- Priority 2.5: Toolchain (3 pages) ✅
- Priority 3: Programming Techniques (19 pages) ✅
- **Total: 43 pages**

**Learnings Documents Created**: 10
1. `wiki_architecture.md` - Core NES architecture
2. `getting_started.md` - Initialization, registers, limitations
3. `sprite_techniques.md` - Sprite management patterns
4. `graphics_techniques.md` - Video, terrain, palettes
5. `input_handling.md` - Controller reading, accessories
6. `timing_and_interrupts.md` - Cycle budgeting, NMI handlers
7. `toolchain.md` - Tool selection and setup
8. `optimization.md` - 6502 optimization techniques
9. `math_routines.md` - Math implementations
10. `README.md` - Navigation and index

**Remaining Priorities**:
- Priority 4: Audio (5 pages) - APU basics, sound engines, music
- Priority 5: Mappers (4 pages) - UNROM, MMC1, CHR-RAM
- Reference: ~40+ pages (file formats, emulation, platform variants)

---

## What We Can Build Now

With current knowledge, we can create:

### Test ROMs (Discovery Mode)
1. **Hello World**: Display sprite, read controller input
2. **Timing Test**: Validate vblank budget, cycle counting
3. **Graphics Test**: Sprite management, scrolling, palette changes
4. **Math Test**: Multiply/divide routines, RNG validation

### Simple Game Prototypes
1. **Single-screen puzzle game**
   - No scrolling
   - Controller input
   - Sprite movement
   - Simple collision

2. **Vertical/horizontal shooter**
   - Scrolling (one axis)
   - Sprite management (enemies, bullets)
   - Simple AI patterns

3. **Platformer prototype**
   - Scrolling
   - Physics (gravity, jumping)
   - Collision detection
   - Tile-based levels

**Limitation**: No audio yet (Priority 4 pending)

---

## Next Steps

### Option A: Complete Audio Study (Priority 4) - RECOMMENDED
**Why**: Round out core knowledge before practical work
1. Study 5 audio pages (APU basics, sound engines, music)
2. Create `learnings/audio.md`
3. Then proceed to mappers (Priority 4) or start practical work

### Option B: Start Toolchain Setup
**Why**: Validate tool choices with "hello world" ROM
1. Install asm6f, Mesen, NEXXT
2. Build minimal test ROM
3. Document setup in `learnings/toolchain_setup.md`
4. Return to study or continue practical work

### Option C: Study Mappers (Priority 5)
**Why**: Understand ROM size constraints before building
1. Study 4 mapper pages (UNROM, MMC1, CHR-RAM)
2. Create `learnings/mappers.md`
3. Decide on mapper for game project

---

## Recommendation

**Complete Priority 4 (Audio)** next. We're close to finishing systematic study (5 more pages). Better to have complete reference material before switching to practical work. Audio knowledge will inform game design decisions.

After Priority 4:
- Quick mapper study (Priority 5) or defer to "as-needed"
- Toolchain setup
- First test ROM

The goal: **Solid reference material before NESHacker collaboration**.
