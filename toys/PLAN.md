# Toy Development Plan (V2)

**Created**: October 2025
**Purpose**: Progressive NES development with LLM-driven automated testing
**Strategy**: See `TESTING.md` for complete testing vision

---

## Overview

**Toy philosophy**: One focused subsystem per ROM. Validate with automated play-specs where possible.

**Testing approach** (see `TESTING.md`):
- **Phase 1**: jsnes subset (state assertions: CPU, PPU, OAM, memory)
- **Phase 2**: Extended DSL (cycle counting, frame buffer, pixel assertions)
- **Phase 3**: Human/Mesen2 (complex visual, edge cases, real hardware)

**Status**:
- ✅ toy0_toolchain: Build pipeline validated (Perl tests, Mesen2 boots)
- ✅ toys/debug/0-2: Emulator survey complete (jsnes chosen for Phase 1)
- 📋 TESTING.md: Complete testing strategy defined (14 questions answered)
- ⏭️ Next: Implement `NES::Test` Phase 1, build toy1 with automated validation

---

## Toy Sequence

### Phase 0: Infrastructure ✅

**toy0_toolchain** - Build pipeline
- **Status**: ✅ Complete
- **Validation**: Perl tests (build artifacts)
- **Artifacts**: Makefile, custom nes.cfg, test.pl template
- **Learnings**: `toys/toy0_toolchain/LEARNINGS.md`

**toys/debug/0_survey** - Emulator research
- **Status**: ✅ Complete
- **Result**: jsnes chosen (headless, direct API)
- **Learnings**: `toys/debug/0_survey/LEARNINGS.md`

**toys/debug/1_jsnes_wrapper** - Headless testing prototype
- **Status**: ✅ Complete
- **Result**: 16 tests passing, JSON output
- **Learnings**: `toys/debug/1_jsnes_wrapper/LEARNINGS.md`

**toys/debug/2_tetanes** - Alternative investigation
- **Status**: ✅ Complete (rejected - API too limited)
- **Learnings**: `toys/debug/2_tetanes/LEARNINGS.md`

---

### Phase 1: Core Subsystems (jsnes validation)

**toy1_sprite_dma** - OAM DMA and sprite display
- **Focus**: Sprite DMA timing, OAM update, sprite rendering
- **Play-spec** (Phase 1):
  ```perl
  at_frame 0 => sub {
      assert_ram 0x0200 => 0;  # OAM empty
  };
  # ... DMA execution
  at_frame 1 => sub {
      assert_ram 0x0200 => { $_ != 0 };  # OAM populated
      assert_sprite 0, y => 100;  # sprite visible
  };
  ```
- **Phase 2 upgrade**: Add `assert_routine_cycles 'oam_dma' => 513`
- **Phase 3 validation**: Visual sprite display in Mesen2
- **Questions answered**: Q1.4 (basic), Q6.2 (partial)
- **Updates**: `learnings/sprite_techniques.md`

**toy2_ppu_init** - PPU initialization and vblank
- **Focus**: PPU warmup, vblank detection, rendering enable
- **Play-spec** (Phase 1):
  ```perl
  at_frame 0 => sub {
      assert_ppu_status 0x00;  # pre-init
  };
  at_frame 2 => sub {
      assert_ppu_status 0x80;  # vblank flag set
  };
  ```
- **Phase 2 upgrade**: Measure vblank wait cycles
- **Phase 3 validation**: Rendering stability in Mesen2
- **Questions answered**: Q1.4 (partial), Q2.2 (partial)
- **Updates**: `learnings/wiki_architecture.md` PPU section

**toy3_controller** - Controller input reading
- **Focus**: 3-step controller read, button state validation
- **Play-spec** (Phase 1):
  ```perl
  press_button 'A';
  at_frame 1 => sub {
      assert_ram 0x10 => 0x01;  # A button flag
  };
  press_button 'A+B';
  at_frame 2 => sub {
      assert_ram 0x10 => 0x03;  # A+B flags
  };
  ```
- **Phase 2 upgrade**: Measure controller read cycles, DPCM conflict test
- **Questions answered**: Q1.4 (partial)
- **Updates**: `learnings/input_handling.md`

---

### Phase 2: Graphics Pipeline (mixed validation)

**toy4_graphics_workflow** - Asset pipeline end-to-end
- **Focus**: PNG → CHR-ROM, palette design, nametable setup
- **Play-spec** (Phase 1):
  ```perl
  at_frame 1 => sub {
      assert_tile 5, 3 => 0x42;  # tile in nametable
      assert_palette 0, 3 => 0x30;  # palette entry
  };
  ```
- **Phase 3 validation**: Visual appearance (colors, patterns)
- **Questions answered**: Q1.7, Q2.1, Q2.2
- **Updates**: `learnings/graphics_techniques.md` asset pipeline

**toy5_attributes** - Attribute table and color granularity
- **Focus**: 16×16 pixel attribute blocks, color bleeding
- **Play-spec** (Phase 1):
  ```perl
  at_frame 1 => sub {
      assert_attribute 1, 1 => 0x01;  # 16x16 block palette
  };
  ```
- **Phase 2 upgrade**: Frame buffer assertions for color boundaries
- **Phase 3 validation**: Visual attribute alignment
- **Questions answered**: Q2.4, Q2.3 (partial)
- **Updates**: `learnings/graphics_techniques.md` attributes

---

### Phase 3: Advanced Graphics (Phase 2 DSL required)

**toy6_scrolling** - Nametable streaming
- **Focus**: Horizontal/vertical scroll, column/row updates
- **Play-spec** (Phase 2 - requires cycle counting):
  ```perl
  at_frame 1 => sub {
      assert_scroll_x 128;
      assert_vblank_cycles_lt 2273;  # streaming budget
  };
  ```
- **Phase 3 validation**: Smooth scrolling visually
- **Questions answered**: Q4.5, Q4.6, Q6.1
- **Updates**: `learnings/graphics_techniques.md` scrolling

**toy7_chr_ram** - CHR-RAM performance
- **Focus**: CHR-RAM copy during vblank, tile updates
- **Play-spec** (Phase 2 - requires cycle counting):
  ```perl
  at_frame 1 => sub {
      assert_chr_tile 0 => 0x00;  # before update
      assert_vblank_cycles_used { $_ < 1000 };  # 10 tiles budget
  };
  at_frame 2 => sub {
      assert_chr_tile 0 => 0x42;  # after update
  };
  ```
- **Questions answered**: Q2.5, Q7.2
- **Updates**: `learnings/graphics_techniques.md` CHR-RAM

---

### Phase 4: Audio & Advanced Input (deferred validation)

**toy8_audio** - FamiTone2 integration
- **Focus**: Sound engine integration, music + SFX
- **Play-spec** (Phase 1 - limited):
  ```perl
  at_frame 1 => sub {
      assert_apu_pulse1_enabled 1;  # channel on
  };
  ```
- **Phase 2 upgrade**: Cycle budget measurement
- **Phase 3 validation**: Audio output (human listening)
- **Audio assertions**: Deferred (see TESTING.md Q5)
- **Questions answered**: Q3.2 (partial), Q3.3, Q3.5, Q3.6
- **Updates**: `learnings/audio.md`

**toy9_metatiles** - Metatile compression
- **Focus**: 2×2 metatile system, runtime decompression
- **Play-spec** (Phase 1):
  ```perl
  # Decompress metatile, verify nametable output
  at_frame 1 => sub {
      assert_tile 0, 0 => 0x10;  # top-left
      assert_tile 1, 0 => 0x11;  # top-right
      assert_tile 0, 1 => 0x20;  # bottom-left
      assert_tile 1, 1 => 0x21;  # bottom-right
  };
  ```
- **Phase 2 upgrade**: Measure decompression cycles
- **Questions answered**: Q2.3, Q6.7 (partial)
- **Updates**: `learnings/graphics_techniques.md` metatiles

---

### Phase 5: Mapper Expansion (automated focus)

**toy10_unrom** - UNROM bank switching
- **Focus**: Bus conflict handling, fixed bank organization
- **Play-spec** (Phase 1):
  ```perl
  at_frame 0 => sub {
      assert_current_bank 0;
  };
  # Switch to bank 1
  at_frame 1 => sub {
      assert_current_bank 1;
      assert_ram 0x50 => 0x42;  # data from bank 1
  };
  ```
- **Phase 3 validation**: All banks accessible
- **Questions answered**: Q5.4, Q5.5, Q7.1
- **Updates**: `learnings/mappers.md` UNROM

**toy11_mmc1** - MMC1 interrupt safety
- **Focus**: Reset+save pattern, NMI during bankswitch
- **Play-spec** (Phase 1):
  ```perl
  # Trigger NMI during bankswitch, verify state
  at_frame 1 => sub {
      assert_current_bank 1;  # switch succeeded despite NMI
  };
  ```
- **Questions answered**: Q7.1
- **Updates**: `learnings/mappers.md` MMC1

---

### Phase 6: Game Architecture (mostly Phase 1)

**toy12_state_machine** - Game state transitions
- **Focus**: Menu → gameplay → pause flow
- **Play-spec** (Phase 1):
  ```perl
  at_frame 0 => sub {
      assert_game_state 'menu';  # custom helper
  };
  press_button 'Start';
  at_frame 1 => sub {
      assert_game_state 'gameplay';
  };
  ```
- **Questions answered**: Q4.1, Q6.3
- **Updates**: `learnings/architecture_patterns.md` (new doc)

**toy13_entities** - Entity/sprite management
- **Focus**: Array of structs, pool allocation, sprite updates
- **Play-spec** (Phase 1):
  ```perl
  at_frame 1 => sub {
      assert_entity_count 16;
      assert_entity 0, x => 100, y => 50;
      assert_sprite 0, x => 100, y => 50;  # entity→sprite sync
  };
  ```
- **Phase 2 upgrade**: Measure entity update cycles
- **Questions answered**: Q4.2, Q6.4
- **Updates**: `learnings/architecture_patterns.md` entities

**toy14_collision** - AABB collision detection
- **Focus**: Bounding box collision, cycle cost measurement
- **Play-spec** (Phase 1):
  ```perl
  # Position entities to collide
  at_frame 1 => sub {
      assert_collision_flag 1;  # collision detected
  };
  ```
- **Phase 2 upgrade**: Compare AABB vs pixel-perfect cycles
- **Questions answered**: Q4.3, Q4.4 (partial), Q6.6 (partial)
- **Updates**: `learnings/math_routines.md` collision

---

### Phase 7: Optimization (Phase 2 heavy)

**toy15_compression** - RLE/LZ decompression
- **Focus**: Decompression cycle costs, vblank budget
- **Play-spec** (Phase 2 - requires cycle counting):
  ```perl
  at_frame 1 => sub {
      assert_decompress_cycles { $_ < 2000 };  # vblank budget
      assert_ram 0x0300 => 0x42;  # decompressed data
  };
  ```
- **Questions answered**: Q6.7, Q6.1
- **Updates**: `learnings/optimization.md` compression

**toy16_math** - Math routine performance
- **Focus**: Multiply/divide vs lookup tables
- **Play-spec** (Phase 2 - requires cycle counting):
  ```perl
  at_frame 1 => sub {
      assert_routine_cycles 'multiply_8x8' => { $_ < 100 };
      assert_ram 0x20 => 42;  # result
  };
  ```
- **Questions answered**: Q6.6
- **Updates**: `learnings/math_routines.md`

---

## Validation Phase Summary

### Phase 1: jsnes (immediate - 10 toys)
- toy1 (sprite DMA), toy2 (PPU init), toy3 (controller)
- toy4 (graphics), toy5 (attributes), toy9 (metatiles)
- toy10 (UNROM), toy11 (MMC1), toy12 (state), toy13 (entities), toy14 (collision)

### Phase 2: Extended DSL (6 toys require cycle counting/frame buffer)
- toy6 (scrolling), toy7 (CHR-RAM), toy8 (audio - partial)
- toy13 (entities - upgrade), toy14 (collision - upgrade)
- toy15 (compression), toy16 (math)

### Phase 3: Human/Mesen2 (all toys - visual/edge cases)
- Visual appearance validation
- Edge case debugging
- Real hardware testing (deferred until late)

---

## Implementation Plan

### Immediate (Next Session)

**Step 1: Implement `NES::Test` Phase 1**
- Location: `lib/NES/Test.pm` (new)
- Backend: jsnes wrapper (reuse toys/debug/1_jsnes_wrapper)
- DSL primitives:
  - `load_rom`, `at_frame`, `press_button`, `run_frames`
  - `assert_ram`, `assert_cpu_pc`, `assert_sprite`, `assert_ppu`
  - `assert_tile`, `assert_palette` (if jsnes supports)
- Test infrastructure: Perl module + Test::More integration

**Step 2: Retrofit toy0 with play-spec**
- Create `toys/toy0_toolchain/play-spec.pl`
- Validate basic DSL workflow
- Document pattern in TOY_DEV.md

**Step 3: Build toy1_sprite_dma**
- First toy with automated hardware validation
- Play-spec validates OAM DMA, sprite rendering
- Update `learnings/sprite_techniques.md` with findings

### Medium-Term (After toy1-5 complete)

**Evaluate Phase 1 limits:**
- Which toys blocked without cycle counting?
- Which toys blocked without frame buffer?
- Prioritize Phase 2 features based on actual need

**Implement Phase 2 DSL:**
- Choose emulator backend (FCEUX Lua? TetaNES fork? Other?)
- Add cycle counting: `assert_vblank_cycles_lt`, `assert_routine_cycles`
- Add frame buffer: `assert_pixel`, `assert_framebuffer_matches`
- Upgrade toys 6-8, 13-16 with Phase 2 assertions

### Long-Term (After toy16)

**Revisit deferred questions:**
- Audio assertions (Q5 from TESTING.md)
- TAS format import/export (Q9 from TESTING.md)
- Real hardware testing (Q7.3, Q7.4 from old plan)

**Game prototype:**
- Apply validated patterns to main game
- Write SPEC.md (game design)
- LLM generates play-specs from SPEC.md
- Iterate: play-spec → assembly → validation

---

## Question Coverage Map

**From `learnings/.docdd/5_open_questions.md`** (43 questions total):

**Toolchain (8 questions)**:
- ✅ Q1.1, Q1.2, Q1.3, Q1.6: toy0_toolchain
- toy1, toy3: Q1.4 (cycle counting - Phase 2)
- Deferred: Q1.5 (blargg tests), Q1.7 (graphics tools - toy4), Q1.8 (audio - toy8)

**Graphics (5 questions)**:
- toy4: Q2.1, Q2.2 (asset workflow, palettes)
- toy9: Q2.3 (metatiles)
- toy5: Q2.4 (attributes)
- toy7: Q2.5 (CHR-RAM vs CHR-ROM)

**Audio (6 questions)**:
- ✅ Q3.1, Q3.4: Answered in `learnings/audio.md`
- toy8: Q3.2, Q3.3, Q3.5, Q3.6

**Game Architecture (7 questions)**:
- toy12: Q4.1 (state machine)
- toy13: Q4.2 (entities)
- toy14: Q4.3, Q4.4 (collision)
- toy6: Q4.5, Q4.6 (scrolling)
- Implicit: Q4.7 (code organization)

**Mappers (6 questions)**:
- ✅ Q5.1, Q5.3: Answered in `learnings/mappers.md`
- Deferred: Q5.2 (needs SPEC.md game genre)
- toy10: Q5.4, Q5.5 (UNROM)
- toy11: Q5.6 (MMC1)

**Optimization (6 questions)**:
- ✅ Q6.5: Answered in `learnings/optimization.md`
- toy1+: Q6.1, Q6.2 (profiling workflow - Phase 2)
- toy12: Q6.3, Q6.4 (zero page allocation)
- toy16: Q6.6 (math benchmarks)
- toy15: Q6.7 (compression)

**Testing (4 questions)**:
- toy10, toy11: Q7.1 (bank switch testing)
- toy7: Q7.2 (CHR-RAM performance)
- Deferred: Q7.3, Q7.4 (real hardware)

---

## Key Differences from V1

**Old plan (PLAN.md + PLAN_DEBUG.md):**
- All toys: Manual Mesen2 validation
- Separate debug infrastructure plan
- "Find headless emulator" goal

**New plan (PLAN_V2):**
- **Progressive automation**: Phase 1 (jsnes) → Phase 2 (extended) → Phase 3 (human)
- **Integrated testing**: Testing strategy in TESTING.md, referenced per toy
- **LLM-first workflow**: Play-specs as executable contracts, not just tests
- **Pragmatic phasing**: Build value with Phase 1, upgrade when limits hit

**Philosophy shift:**
- V1: "Automate validation where possible"
- V2: **"Design testing for LLM development, implement progressively"**

---

## Next Steps

**Immediate (this session):**
1. Delete old PLAN.md and PLAN_DEBUG.md
2. Rename PLAN_V2.md → PLAN.md
3. Update ORIENTATION.md to reference new plan

**Next session:**
1. Implement `NES::Test` Phase 1 module
2. Create toy0 play-spec (validate DSL)
3. Build toy1_sprite_dma with automated validation

---

**Status: Ready to implement.** Testing strategy complete, toy sequence updated, progressive automation defined.
