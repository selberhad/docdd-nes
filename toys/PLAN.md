# Toy Development Plan

**Created**: October 2025
**Purpose**: High-level roadmap mapping open questions to test ROM sequence
**Source**: Derived from `learnings/.docdd/5_open_questions.md`

---

## Overview

**Toy philosophy**: One focused subsystem per ROM. Measure reality, update theory docs.

**Status**:
- ✅ toy0_toolchain: Build pipeline validated (13 tests, Mesen2 boots ROM)
- 36 open questions remain across 7 categories
- No blockers - all questions answerable through practice

**Answered by toy0**:
- Q1.1: Build pipeline integration (Makefile, ca65/ld65 workflow)
- Q1.2: Debug symbol generation (hello.dbg created, nes.cfg configured)
- Q1.3: Mesen debugger basics (GUI-only, manual validation workflow)
- Q1.6: Build automation structure (Makefile with rom/clean/run targets)

---

## Toy Sequence

### Phase 1: Hardware Fundamentals ✅ (toy0 complete)

**toy0_toolchain** - Build pipeline validation
- **Status**: ✅ Complete
- **Questions answered**: Q1.1, Q1.2, Q1.3, Q1.6
- **Artifacts**: Working Makefile, custom nes.cfg, test.pl infrastructure
- **Learnings**: `toys/toy0_toolchain/LEARNINGS.md`

---

### Phase 2: PPU & Graphics Subsystem (toys 1-4)

**toy1_sprite_dma** - OAM DMA cycle measurement
- **Focus**: Sprite DMA timing validation
- **Questions**: Q1.4 (cycle counting), Q6.2 (Mesen profiler usage)
- **Goal**: Measure actual 513-cycle OAM DMA, validate sprite display
- **Update**: `learnings/sprite_techniques.md` with measured timings
- **Test approach**: Manual (Mesen2 cycle counter, visual validation)

**toy2_ppu_init** - PPU initialization sequence
- **Focus**: PPU warmup, vblank detection, rendering enable
- **Questions**: Q1.4 (vblank timing), Q2.2 (palette setup)
- **Goal**: Prove 2-frame warmup, measure vblank wait cycles
- **Update**: `learnings/wiki_architecture.md` PPU section with actual timings
- **Test approach**: Manual (visual validation, debugger observation)

**toy3_graphics_workflow** - Asset pipeline end-to-end
- **Focus**: PNG → CHR-ROM workflow, palette design
- **Questions**: Q1.7 (graphics tools), Q2.1 (pixel editor workflow), Q2.2 (palette design)
- **Goal**: Document NEXXT workflow (or alternative), create reusable tileset
- **Update**: `learnings/graphics_techniques.md` with asset pipeline
- **Test approach**: Manual (create 4 tiles, 4 palettes, display on screen)

**toy4_attributes** - Attribute table granularity
- **Focus**: 16×16 pixel attribute blocks, color bleeding
- **Questions**: Q2.4 (attribute alignment), Q2.3 (metatile preview)
- **Goal**: Test attribute boundaries, measure impact of granularity
- **Update**: `learnings/graphics_techniques.md` with attribute constraints
- **Test approach**: Manual (draw test patterns, observe color blocks)

---

### Phase 3: Input & Audio Subsystem (toys 5-6)

**toy5_controller** - Controller reading and edge cases
- **Focus**: 3-step controller read, DPCM conflict testing
- **Questions**: Q1.4 (cycle counting), Q6.2 (profiling)
- **Goal**: Validate controller read timing, test rapid button presses
- **Update**: `learnings/input_handling.md` with measured timings
- **Test approach**: Manual (button presses, debugger watches $4016/$4017)

**toy6_audio** - FamiTone2 integration and SFX
- **Focus**: Sound engine integration, cycle budget measurement
- **Questions**: Q3.2 (SFX priority), Q3.3 (cycle budget), Q3.5 (asset build), Q3.6 (phasing)
- **Goal**: Play music + SFX, measure FamiTone2 update cycles
- **Update**: `learnings/audio.md` with actual cycle costs
- **Test approach**: Manual (listen for audio, Mesen cycle profiling)

---

### Phase 4: Scrolling & Level Data (toys 7-8)

**toy7_scrolling** - Nametable streaming during scroll
- **Focus**: Horizontal/vertical scrolling, column/row updates
- **Questions**: Q4.5 (level streaming), Q4.6 (nametable streaming), Q6.1 (vblank budget)
- **Goal**: Stream tiles during scroll, measure vblank overhead
- **Update**: `learnings/graphics_techniques.md` scrolling section
- **Test approach**: Manual (visual validation, cycle profiling)

**toy8_metatiles** - Metatile compression and decompression
- **Focus**: 2×2 metatile system, encoding, runtime cost
- **Questions**: Q2.3 (metatile system), Q6.7 (compression cost)
- **Goal**: Implement metatile decompression, measure cycle cost
- **Update**: `learnings/graphics_techniques.md` metatile patterns
- **Test approach**: Manual (visual validation) + cycle profiling

---

### Phase 5: Mapper Expansion (toys 9-11)

**toy9_unrom** - UNROM bank switching
- **Focus**: Bus conflict handling, fixed bank organization
- **Questions**: Q5.4 (bus conflicts), Q5.5 (fixed bank layout), Q7.1 (bank test)
- **Goal**: Validate banktable pattern, measure fixed bank usage
- **Update**: `learnings/mappers.md` UNROM section with actual code size
- **Test approach**: Automated (test.pl verifies all banks accessible) + manual

**toy10_mmc1** - MMC1 interrupt safety
- **Focus**: Reset+save pattern, NMI during bankswitch
- **Questions**: Q7.1 (interrupt test during bankswitch)
- **Goal**: Validate MMC1 bankswitch survives NMI interrupts
- **Update**: `learnings/mappers.md` MMC1 section with validation
- **Test approach**: Automated (test.pl triggers NMI during switch) + manual

**toy11_chr_ram** - CHR-RAM performance
- **Focus**: CHR-RAM copy during vblank, double-buffering
- **Questions**: Q2.5 (CHR-RAM vs CHR-ROM), Q7.2 (CHR copy performance)
- **Goal**: Measure actual 10 tiles/frame limit, test buffering strategies
- **Update**: `learnings/graphics_techniques.md` CHR-RAM section
- **Test approach**: Manual (visual validation) + cycle profiling

---

### Phase 6: Game Architecture Patterns (toys 12-14)

**toy12_state_machine** - Game state transitions
- **Focus**: Menu → gameplay → pause flow
- **Questions**: Q4.1 (state machine patterns), Q6.3 (zero page allocation)
- **Goal**: Implement state system, document memory layout
- **Update**: `learnings/architecture_patterns.md` (new doc)
- **Test approach**: Manual (state transitions via controller)

**toy13_entities** - Entity/sprite management
- **Focus**: Array of structs, pool allocation
- **Questions**: Q4.2 (entity system), Q6.4 (zero page usage)
- **Goal**: Manage 16 entities, update sprites each frame
- **Update**: `learnings/architecture_patterns.md` entity section
- **Test approach**: Manual (visual validation) + cycle profiling

**toy14_collision** - AABB collision detection
- **Focus**: Bounding box vs pixel-perfect cost comparison
- **Questions**: Q4.3 (collision patterns), Q4.4 (pixel-perfect cost), Q6.6 (math cost)
- **Goal**: Implement AABB + pixel-perfect, measure cycle difference
- **Update**: `learnings/math_routines.md` collision section
- **Test approach**: Manual (collision visualization) + cycle profiling

---

### Phase 7: Optimization & Polish (toys 15-16)

**toy15_compression** - RLE/LZ decompression benchmarks
- **Focus**: Decompression cycle costs, vblank budget impact
- **Questions**: Q6.7 (compression cost), Q6.1 (optimization timing)
- **Goal**: Benchmark RLE vs LZ, measure vblank overhead
- **Update**: `learnings/optimization.md` compression section
- **Test approach**: Cycle profiling (decompress test data)

**toy16_math** - Math routine performance
- **Focus**: Multiply/divide cycle costs, lookup tables
- **Questions**: Q6.6 (math cost/benefit)
- **Goal**: Measure multiply/divide vs table lookups
- **Update**: `learnings/math_routines.md` with actual measurements
- **Test approach**: Cycle profiling (run routines 100x)

---

## Progression Strategy

**Fundamental → Advanced**:
1. Hardware basics (PPU, sprites, input, audio)
2. Level data (scrolling, metatiles)
3. Mapper expansion (UNROM, MMC1)
4. Game patterns (state, entities, collision)
5. Optimization (compression, math)

**Systematic measurement**:
- Every toy measures cycle costs (Q1.4, Q6.2)
- Update theory docs with actual numbers
- Build reusable code patterns in `toys/lib/` (future)

**Incremental validation**:
- Start with NROM (simpler)
- Migrate to UNROM when >32KB (toy9)
- Test MMC1 features separately (toy10)
- Choose CHR-ROM vs CHR-RAM after toy11 measurements

---

## Question Coverage Map

**Toolchain (8 questions)**:
- ✅ Q1.1, Q1.2, Q1.3, Q1.6: toy0_toolchain
- Q1.4, Q6.2: toy1 (cycle counting workflow established)
- Q1.5: Defer (blargg tests - run when needed)
- Q1.7: toy3 (graphics workflow)
- Q1.8: toy6 (audio asset build)

**Graphics (5 questions)**:
- Q2.1, Q2.2: toy3 (asset workflow)
- Q2.3: toy8 (metatiles)
- Q2.4: toy4 (attributes)
- Q2.5: toy11 (CHR-RAM vs CHR-ROM)

**Audio (6 questions)**:
- ✅ Q3.1, Q3.4: Answered in `learnings/audio.md` (FamiTone2, FamiTracker)
- Q3.2, Q3.3, Q3.5, Q3.6: toy6

**Game Architecture (7 questions)**:
- Q4.1: toy12 (state machine)
- Q4.2: toy13 (entities)
- Q4.3, Q4.4: toy14 (collision)
- Q4.5, Q4.6: toy7 (scrolling)
- Q4.7: Establish in toy1 (code organization conventions)

**Mappers (6 questions)**:
- ✅ Q5.1, Q5.3: Answered in `learnings/mappers.md` (NROM → UNROM → MMC1)
- Q5.2: Defer until SPEC.md (game genre decision)
- Q5.4, Q5.5: toy9 (UNROM)
- Q5.6: toy10 (MMC1)

**Optimization (6 questions)**:
- ✅ Q6.5: Answered in `learnings/optimization.md` (avoid unofficial opcodes)
- Q6.1, Q6.2: Established in toy1 (profiling workflow)
- Q6.3, Q6.4: toy12 (zero page allocation map)
- Q6.6: toy16 (math benchmarks)
- Q6.7: toy15 (compression benchmarks)

**Testing (4 questions)**:
- Q7.1: toy9, toy10 (bank switch testing)
- Q7.2: toy11 (CHR-RAM performance)
- Q7.3, Q7.4: Defer until game near completion (real hardware)

**Total**: 43 questions (7 answered, 36 open → mapped to 16 toys)

---

## Deferred Questions

**Not blocking development**:
- Q1.5: blargg test ROMs (run when debugging edge cases)
- Q5.2: CHR-ROM vs CHR-RAM (needs SPEC.md game genre)
- Q7.3, Q7.4: Real hardware testing (defer until late development)

**Established conventions** (answer implicitly):
- Q4.7: Code organization (establish in toy1, document in CODE_MAP.md)

---

## Next Actions

**Immediate**: Start toy1_sprite_dma
- Run `./tools/new-toy.pl sprite_dma`
- Create `toys/toy1_sprite_dma/SPEC.md` and `PLAN.md`
- Measure OAM DMA with Mesen2 cycle counter
- Update `learnings/sprite_techniques.md` with findings

**After toy1**: Decide between toy2 (PPU init) or toy3 (graphics workflow)
- toy2 continues PPU subsystem (logical progression)
- toy3 unlocks asset pipeline (enables richer test ROMs)

**Long-term**: After toy16, assess
- Which questions need game prototype to answer (Phase 5 from open questions doc)
- When to write SPEC.md (game design)
- When to transition from toys → main game development

---

## Status: Ready to Start toy1

**No blockers**. toy0 validated toolchain. 36 questions mapped to 16 toys. Systematic progression defined.

**Recommendation**: Start toy1_sprite_dma (PPU fundamentals, establishes cycle counting workflow for all future toys).
