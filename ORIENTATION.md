# ORIENTATION — docdd-nes

**Quick Start**: NES game development project using **Doc-Driven Development (DDD)** methodology. Greenfield learning project to test DDD in a constraint-driven context.

---

## Current State (October 2025)

**Phase**: 🚀 **NES::Test Phase 1 Complete → Ready to Build toy1**

### Progress Summary
- ✅ **52 wiki pages studied** (all core priorities complete)
- ✅ **11 technical learning docs** created
- ✅ **5 meta-learning docs** tracking progress
- ✅ **toy0_toolchain complete** (build pipeline validated, 6x faster than estimated)
- ✅ **Debug infrastructure surveyed** (jsnes chosen for Phase 1 automation)
- ✅ **Testing strategy defined** (`TESTING.md` - LLM-driven play-spec workflow)
- ✅ **NES::Test Phase 1 implemented** (Perl DSL + persistent jsnes harness)
- ✅ **toy1_sprite_dma planned** (SPEC, PLAN, LEARNINGS ready)

### What We Know
**Complete NES architecture understanding documented in `learnings/`**:
- Memory maps (CPU/PPU), timing (vblank budgets, cycle counting)
- PPU (registers, sprites, scrolling, palettes, nametables)
- APU (5 channels, FamiTone2 sound engine, music workflow)
- Controllers (3-step read, edge detection, DPCM conflicts)
- 6502 optimization (cycle/byte trade-offs, zero page, jump tables)
- Mappers (NROM → UNROM → MMC1 progression, CHR-ROM vs CHR-RAM)
- Math routines, compression, toolchain selection (asm6f, Mesen, NEXXT, FamiTracker)

### Decisions Made
- **Assembler**: cc65 (ca65/ld65) - Homebrew, native ARM64, custom nes.cfg
- **Emulator (dev)**: Mesen2 - Best debugger, cycle-accurate, native ARM64
- **Emulator (test)**: jsnes - Headless automation, direct API (Phase 1 testing)
- **Testing**: Perl DSL (`NES::Test`) - Play-specs as executable contracts (see `TESTING.md`)
- **Graphics**: NEXXT (when needed)
- **Audio**: FamiStudio + FamiTone2 engine (cross-platform)
- **Mapper strategy**: Start NROM, migrate to UNROM when >32KB
- **Optimization policy**: Avoid unofficial opcodes unless proven bottleneck

---

## Next Step: Build toy1_sprite_dma

**→ See `toys/toy1_sprite_dma/PLAN.md` for detailed TDD steps**

**All infrastructure ready!** ✅ NES::Test Phase 1, build pipeline, testing strategy

Next session tasks (from toy1 PLAN.md):
1. **Copy build infrastructure** from toy0 (Makefile, nes.cfg)
2. **Write failing play-spec.pl** (Red - OAM DMA assertions)
3. **Implement assembly incrementally** (Green - shadow OAM → DMA trigger)
4. **Document findings** in LEARNINGS.md
5. **Extract patterns** for future toys

**Estimated time**: 2-3 hours (first hardware validation toy, TDD workflow)

**What toy1 validates** (see `toys/toy1_sprite_dma/SPEC.md`):
- OAM DMA mechanism ($4014 trigger)
- Shadow OAM ($0200) → PPU OAM transfer
- NES::Test Phase 1 for hardware validation
- 4 test sprites with known positions/attributes

---

## Tools & Environment

**Toolchain** (✅ installed, macOS ARM64 native):
- **cc65** (ca65/ld65) - Assembler + linker (via Homebrew)
- **Mesen2** - Emulator/debugger (native ARM64, cycle-accurate)
- **SDL2** - Mesen2 dependency (via Homebrew)

**To be added when needed**:
- **NEXXT** - Graphics editor (when creating first tileset)
- **FamiStudio** - Music tracker (when creating first music, cross-platform alternative to Windows-only FamiTracker)
- **blargg test ROMs** - Validation suite (download when validating emulator)

**Build workflow** (to be implemented):
- Makefile for assembly + asset integration
- Symbol file generation for debugging
- Auto-convert graphics/music on change

---

## Key Files

### Documentation (Start Here)
- **`ORIENTATION.md`** ← You are here
- **`TESTING.md`** - **Testing strategy for LLM-driven development** (14 questions answered, Perl DSL design)
- **`toys/PLAN.md`** - **16-toy development plan** (progressive automation, Phase 1→2→3)
- **`STUDY_PLAN.md`** - Wiki study roadmap (52 pages complete)
- **`CLAUDE.md`** - NES development guidelines for Claude
- **`DDD.md`** - Doc-Driven Development methodology
- **`TOY_DEV.md`** - Test ROM development workflow

### Learning Artifacts (Study Output)
**Technical learnings** (`learnings/`):
- `wiki_architecture.md` - Core NES architecture
- `getting_started.md` - Initialization, registers, limitations
- `sprite_techniques.md`, `graphics_techniques.md` - PPU programming
- `input_handling.md`, `timing_and_interrupts.md` - I/O and cycle budgets
- `toolchain.md` - Tool selection and setup
- `optimization.md`, `math_routines.md` - 6502 programming
- `audio.md` - APU and sound engines
- `mappers.md` - Bank switching and memory expansion

**Meta-learnings** (`learnings/.docdd/`):
- `0_initial_questions.md` - Original 10 question categories (all answered)
- `1_essential_techniques.md` - Priority 1-2 progress
- `2_toolchain_optimization.md` - Priority 2.5-3 progress
- `3_audio_complete.md` - Priority 4 progress
- `4_mappers_complete.md` - Priority 5 progress
- `5_open_questions.md` - **36 open questions + 7 answered** (roadmap for practical work)

### Utilities
- `tools/fetch-wiki.sh` - Cache NESdev wiki pages to `.webcache/`
- `tools/add-attribution.pl` - Add wiki attribution to learning docs
- `tools/setup-brew-deps.sh` - Install Homebrew toolchain dependencies (cc65, sdl2)
- `.webcache/` - Cached wiki pages (52 pages, gitignored)

### Blog (AI-Written Reflections)
- `docs/blog/1_study-phase-complete.md` - Study phase complete (52 pages → 16 docs)
- `docs/blog/2_first-rom-boots.md` - toy0 complete (6x faster than estimated, TDD infrastructure)
- `docs/blog/3_headless-testing-search.md` - Emulator survey (jsnes chosen over TetaNES/FCEUX)
- `docs/blog/4_testing-vision.md` - **Testing strategy designed** (Perl DSL, LLM workflow, 3-phase automation)

### Toy Artifacts (Built)
- `toys/toy0_toolchain/` - ✅ Build pipeline (Makefile, nes.cfg, test.pl, 13 tests passing)
- `toys/debug/0_survey/` - ✅ Emulator research (LEARNINGS.md)
- `toys/debug/1_jsnes_wrapper/` - ✅ jsnes headless wrapper (16 tests passing, JSON output)
- `toys/debug/2_tetanes/` - ✅ TetaNES investigation (rejected - API limitations)

### To Be Created (Next Session)
- `lib/NES/Test.pm` - **Phase 1 Perl DSL module** (jsnes backend)
- `toys/toy1_sprite_dma/` - First hardware validation toy
- `src/` - Main game assembly (after toy prototyping)
- `SPEC.md` - Game design (after toy validation)

---

**Philosophy**: Document everything. NES knowledge is hard-won - capture it or lose it. 📚
