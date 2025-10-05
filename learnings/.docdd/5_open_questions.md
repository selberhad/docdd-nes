# Open Questions — Consolidated from All Study Phases

**Created**: October 2025
**Purpose**: Central tracking of all open questions raised during systematic wiki study (Phases 0-4)
**Status**: Ready for practical work to answer these through test ROMs and implementation

---

## Quick Summary

**Study complete**: 52/100+ wiki pages (all core priorities)
**Open questions**: 36 practical implementation questions
**Answered/decided**: 7 questions (sound engine, mapper strategy, optimization policy)
**Primary blockers**: None - all questions answerable through practice

**Categories**:
1. Toolchain & Development Workflow (8 open)
2. Graphics Asset Pipeline (5 open)
3. Audio Implementation (3 open, **3 answered**)
4. Game Architecture & Patterns (7 open)
5. Mapper Selection & Implementation (3 open, **3 answered**)
6. Optimization & Performance (6 open, **1 answered**)
7. Testing & Validation (4 open)

**Total**: 36 open questions, **7 answered/decided** (43 total)

---

## 1. Toolchain & Development Workflow

### Build Pipeline Integration
**Q1.1**: How to integrate asm6f + NEXXT + FamiTracker into single build workflow?
- Makefile? Shell script? Both?
- Auto-convert graphics assets on change?
- How to assemble + link CHR data?
- **Answer via**: Build first test ROM, document actual workflow

**Q1.2**: How to generate symbol files for debugging?
- asm6f flag for symbol output?
- Integration with Mesen debugger?
- **Answer via**: Check asm6f docs, test with Mesen

### Debugging Workflow
**Q1.3**: How to use Mesen debugger effectively?
- Breakpoint strategies (entry points, vblank, specific cycles)?
- Memory watch patterns (what to track)?
- Trace logging for cycle counting?
- **Answer via**: Debug first test ROM in Mesen

**Q1.4**: How to measure actual cycle usage?
- Mesen's cycle counter?
- Manual counting vs profiler?
- Validate vblank budget adherence?
- **Answer via**: Profile test ROM routines (OAM DMA, tile copy, etc.)

### Testing Strategy
**Q1.5**: When to run blargg test ROMs?
- Before first build? After each subsystem? Continuous?
- Which tests are critical (nestest, ppu_vbl_nmi, sprite_hit)?
- **Answer via**: Run full suite before first custom ROM

**Q1.6**: Build automation structure?
- Separate Makefile targets (rom, chr, clean, run)?
- Dependency tracking (rebuild on asset change)?
- **Answer via**: Create Makefile during first build

### Asset Conversion
**Q1.7**: Graphics tools workflow?
- NEXXT for all tile editing?
- YY-CHR for quick inspection?
- Custom scripts for PNG → CHR?
- **Answer via**: Create first tileset, document steps

**Q1.8**: Music data build integration?
- FamiTracker → text2data → .asm workflow?
- Auto-convert on .ftm file change?
- Include in main Makefile?
- **Answer via**: Create first music track, document build steps

---

## 2. Graphics Asset Pipeline

### Tile Design
**Q2.1**: What pixel editor workflow for 4-color constraint?
- Draw in NEXXT directly?
- External tool (Aseprite, GraphicsGale) then import?
- Palette assignment workflow?
- **Answer via**: Create placeholder graphics, document process

**Q2.2**: Palette design tools/techniques?
- Pick colors from NES palette chart?
- Visual palette editor?
- Common palette choices for placeholder art?
- **Answer via**: Design 4 palettes for test ROM

### Metatile Systems
**Q2.3**: How to efficiently compress level data with metatiles?
- 2×2 metatiles standard?
- How to encode (attribute bits + tile indices)?
- Runtime decompression cost?
- **Answer via**: Implement metatile system in test ROM

**Q2.4**: How to handle attribute table granularity (16×16 pixels)?
- Design metatiles to align with attribute blocks?
- Accept color bleeding?
- Mid-frame palette changes workaround?
- **Answer via**: Test attribute limits in graphics test ROM

### CHR Data Management
**Q2.5**: When to use CHR-ROM vs CHR-RAM?
- Depends on game genre (decided after SPEC.md)
- Action/platformer → CHR-ROM (speed)
- RPG/puzzle → CHR-RAM (flexibility)
- **Answer via**: Prototype with both in test ROMs

---

## 3. Audio Implementation

### ✅ Sound Engine Integration (ANSWERED)
**Q3.1**: Which sound engine to use?
- ✅ **ANSWERED**: FamiTone2 (beginner-friendly)
  - Source: `learnings/audio.md` - Comparison of 8 engines analyzed
  - Alternative: FamiStudio if rich features needed later
- **Next step**: Integrate FamiTone2 in audio test ROM

**Q3.2**: How to structure SFX vs music priority?
- Priority by channel (SFX on pulse 2, music on pulse 1/triangle)?
- Priority by type (important SFX interrupt music)?
- Ducking (reduce music volume during SFX)?
- **Answer via**: Implement SFX system, test mixing strategies

**Q3.3**: Cycle budget allocation for audio?
- **Target**: 1000-1500 cycles/frame (FamiTone2)
- How much actual headroom after OAM DMA + VRAM updates?
- Penguin engine (790 cycles) if budget tight?
- **Answer via**: Profile FamiTone2 update in test ROM

### ✅ Music Workflow (ANSWERED)
**Q3.4**: Composition tool - FamiTracker vs FamiStudio?
- ✅ **ANSWERED**: FamiTracker (industry standard)
  - Source: `learnings/audio.md` - Well-documented, widely used
  - Alternative: FamiStudio (modern, better UI) if limitations hit
- **Next step**: Install and create test track

**Q3.5**: Asset build integration for music?
- FamiTracker .ftm → text2data → .asm include?
- Auto-rebuild on .ftm change?
- Include music data in which PRG bank?
- **Answer via**: Set up music build pipeline

**Q3.6**: When to implement audio in development?
- Simple beep/bloop in early test ROM?
- Full music integration before game?
- SFX first or music first?
- **Answer via**: Add audio incrementally (beep → SFX → music)

---

## 4. Game Architecture & Patterns

### State Management
**Q4.1**: State machine patterns for game flow?
- Menu → gameplay → pause → game over transitions?
- How to structure state handlers?
- Where to store current state (zero page byte)?
- **Answer via**: Implement state machine in simple game prototype

**Q4.2**: Entity system for multiple sprites?
- Array of structs (x, y, velocity, type, state)?
- How many entities to support (16? 32? 64?)?
- Pool allocation or fixed slots?
- **Answer via**: Implement enemy manager in game prototype

### Collision Detection
**Q4.3**: Bounding box collision patterns for 6502?
- AABB (Axis-Aligned Bounding Box) standard?
- Tile-based collision (background)?
- Sprite-sprite collision (enemies, bullets)?
- **Answer via**: Implement collision in platformer test ROM

**Q4.4**: Pixel-perfect collision worth the cycles?
- AABB sufficient for most games?
- Pixel-perfect for specific cases (puzzle games)?
- **Answer via**: Measure cycle cost of both approaches

### Level Streaming
**Q4.5**: How to load/unload level data dynamically?
- Stream from ROM during scrolling?
- Pre-decompress full level to RAM?
- Trade-off: ROM space vs RAM space?
- **Answer via**: Implement scrolling level in test ROM

**Q4.6**: Nametable streaming during scrolling?
- Column-at-a-time (vertical scrolling)?
- Row-at-a-time (horizontal scrolling)?
- Cycle budget for streaming?
- **Answer via**: Implement scrolling with nametable updates

### Code Organization
**Q4.7**: How to structure code for maintainability?
- One file or modular includes?
- Naming conventions (snake_case, PascalCase)?
- Comment density (every line, per-block, minimal)?
- **Answer via**: Establish conventions in first test ROM

---

## 5. Mapper Selection & Implementation

### ✅ Mapper Choice (ANSWERED)
**Q5.1**: Which mapper for docdd-nes?
- ✅ **ANSWERED**: Start NROM, migrate to UNROM when >32KB
  - Source: `learnings/mappers.md` - Mapper progression strategy
  - Move to MMC1 only if need CHR-ROM switching or PRG-RAM
- **Next step**: Prototype in NROM, measure ROM usage to know when to migrate

**Q5.2**: CHR-ROM or CHR-RAM for docdd-nes?
- **Pending**: Wait for SPEC.md (game genre decision)
- Action/platformer → CHR-ROM
- RPG/puzzle → CHR-RAM
- **Answer via**: Define game genre, choose CHR strategy

**Q5.3**: ✅ **ANSWERED**: When to switch mappers?
- ✅ NROM → UNROM: When ROM >32KB or need CHR switching
- ✅ UNROM → MMC1: When need CHR-ROM banks or PRG-RAM
- Source: `learnings/mappers.md` - Mapper decision matrix
- **Next step**: Track ROM growth during development, migrate when thresholds hit

### UNROM Implementation
**Q5.4**: ✅ **PARTIALLY ANSWERED**: Bus conflict handling in practice?
- ✅ **Theory**: Always use lookup table pattern (standard)
  - Source: `learnings/mappers.md` - banktable code example provided
  - Place in fixed bank ($C000-$FFFF)
- **Practice needed**: How much space does banktable consume? Organization strategy?
- **Answer via**: Implement UNROM bankswitch in test ROM

**Q5.5**: Fixed bank organization?
- Vectors, NMI, IRQ, bankswitch routine (required)
- Common utils (controller read, OAM DMA, etc.)?
- How much space for fixed bank code?
- **Answer via**: Implement UNROM test ROM, measure fixed bank usage

### ✅ MMC1 Implementation (ANSWERED)
**Q5.6**: MMC1 interrupt safety - which solution?
- ✅ **ANSWERED**: Reset + save/restore (simpler)
  - Source: `learnings/mappers.md` - Both strategies documented
  - Forces fixed-$C000 mode (acceptable constraint)
  - Upgrade to retry flag only if needed
- **Next step**: Implement reset+save in MMC1 test ROM, validate with NMI interrupts

---

## 6. Optimization & Performance

### When to Optimize
**Q6.1**: Premature vs necessary optimization?
- Optimize vblank code always (strict budget)?
- Profile first for non-critical code?
- **Answer via**: Profile test ROM, identify bottlenecks

**Q6.2**: How to measure actual cycle usage?
- Mesen debugger cycle counter?
- Manual counting from instruction reference?
- **Theory**: `learnings/timing_and_interrupts.md` - Instruction cycle reference provided
- **Answer via**: Use Mesen profiler on test ROM routines (same as Q1.4)

### Zero Page Allocation
**Q6.3**: How to manage 256 bytes of zero page?
- Reserve ranges per subsystem (e.g., $00-$1F: temp, $20-$3F: game state)?
- Document allocation in CODE_MAP.md?
- Naming conventions (zp_temp, zp_player_x)?
- **Answer via**: Create zero page allocation map in first ROM

**Q6.4**: Which variables deserve zero page?
- Hot variables (read/written every frame)?
- Pointer indirection (required for indirect addressing)?
- **Answer via**: Profile variable access patterns, move hot vars to ZP

### Math Routines
**Q6.6**: When to use math routines - cost/benefit?
- Avoid division in gameplay loop?
- Pre-compute tables where possible?
- Fixed-point vs integer math?
- **Theory**: `learnings/math_routines.md` - All routines documented with cycle costs
  - Multiply: ~200-300 cycles (general), faster for constants via shifts
  - Divide: Even slower than multiply
  - BCD/Base 100: For score display
- **Answer via**: Profile math usage in game, pre-compute tables where feasible

### Compression
**Q6.7**: Compression decompression cost?
- RLE fast enough for vblank?
- LZ too slow for real-time?
- Pre-decompress to RAM vs stream?
- **Theory**: `learnings/optimization.md` - RLE, LZ, fixed-bit encoding documented
- **Theory**: `learnings/mappers.md` - Konami/Codemasters RLE examples
- **Answer via**: Benchmark decompression routines, measure vblank budget impact

### ✅ Unofficial Opcodes (ANSWERED)
**Q6.5**: Policy on unofficial opcodes?
- ✅ **ANSWERED**: Avoid unless bottleneck proven, document if used
  - Source: `learnings/optimization.md` - Stability issues documented (chip revision differences)
  - Not all stable across NES hardware variants (Dendy, PAL clones)
  - Test coverage required if used
- **Next step**: Benchmark official vs unofficial in test ROM if bottleneck discovered

---

## 7. Testing & Validation

### Bank Switching Tests
**Q7.1**: How to test bank switching?
- Build ROM with code in each bank printing bank number?
- Test all banks accessible?
- Test NMI/IRQ during bankswitch (MMC1)?
- **Answer via**: Create bank switch test ROM

### CHR-RAM Performance
**Q7.2**: What's the actual CHR-RAM copy performance?
- **Theory**: 10 tiles/frame (160 bytes)
- Measure actual cycle cost in vblank
- Need double-buffering for large updates?
- **Answer via**: Profile CHR copy routine in test ROM

### Real Hardware Testing
**Q7.3**: When to test on real hardware?
- After emulator validation?
- Before final release?
- Which flashcart (Everdrive, Powerpak)?
- **Answer via**: Defer until game nearing completion

### Donor Cart Compatibility
**Q7.4**: Which donor carts available for reproduction?
- **UNROM**: Common (Mega Man, Castlevania, Metal Gear)
- **MMC1**: Very common (Metroid, Zelda, Kid Icarus)
- CHR-RAM boards less common?
- **Answer via**: Research donor cart availability when ready for hardware

---

## Next Steps to Answer These Questions

### Phase 1: Toolchain Setup (Answers Q1.1-Q1.8, Q3.4)
1. Install asm6f, Mesen, NEXXT, FamiTracker
2. Run blargg test ROM suite
3. Create build script (Makefile)
4. Document toolchain setup process

### Phase 2: First Test ROM (Answers Q1.3-Q1.6, Q2.1-Q2.2, Q6.3)
1. Build "hello world" NROM ROM
2. Display sprite (test graphics workflow)
3. Read controller (test input)
4. Play beep (test basic audio)
5. Profile cycle usage (measure actual costs)
6. Document findings in learning docs

### Phase 3: Subsystem Test ROMs (Answers Q2.3-Q2.5, Q3.2-Q3.3, Q4.3-Q4.6, Q6.6-Q6.7)
1. Graphics test: Metatiles, attributes, scrolling
2. Audio test: FamiTone2 integration, SFX mixing
3. Collision test: AABB, tile-based, sprite-sprite
4. Scrolling test: Nametable streaming, level data
5. Compression test: RLE/LZ decompression benchmarks
6. Update learning docs with actual measurements

### Phase 4: Mapper Test ROMs (Answers Q5.4-Q5.5, Q7.1-Q7.2)
1. UNROM bank switch test (bus conflict table, fixed bank layout)
2. MMC1 interrupt safety test (reset+save validation)
3. CHR-RAM performance test
4. Compare mappers, document actual ROM usage patterns

### Phase 5: Game Prototype (Answers Q4.1-Q4.7, Q6.1-Q6.4)
1. Define game in SPEC.md (determines Q5.2 CHR choice)
2. Implement core gameplay (state machine, entity system)
3. Measure performance bottlenecks (cycle profiling)
4. Optimize critical paths (zero page allocation, math routines)
5. Document architecture patterns established

---

## Status: Ready for Practical Work

**No blockers**: All questions answerable through test ROM development and iteration.

**Recommended path**: Start with toolchain setup and "hello world" test ROM. Answer questions incrementally as they become relevant.

**Documentation strategy**: Update learning docs with actual measurements and edge cases discovered during implementation.
