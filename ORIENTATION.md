# ORIENTATION — docdd-nes

**Quick Start**: NES game development project using **Doc-Driven Development (DDD)** methodology. Greenfield learning project to test DDD in a constraint-driven context.

---

## Current State (October 2025)

**Phase**: 🎮 **Two Hardware Toys Complete → toy3 Next**

### Progress Summary
- ✅ **52 wiki pages studied** (all core priorities complete)
- ✅ **11 technical learning docs** created
- ✅ **5 meta-learning docs** tracking progress
- ✅ **toy0_toolchain complete** (build pipeline validated, 6x faster than estimated)
- ✅ **Debug infrastructure surveyed** (jsnes chosen for Phase 1 automation)
- ✅ **Testing strategy defined** (`TESTING.md` - LLM-driven play-spec workflow)
- ✅ **NES::Test Phase 1 implemented** (Perl DSL + persistent jsnes harness)
- ✅ **toy1_sprite_dma complete** (OAM DMA validated, 20/20 tests passing, 45 min actual vs 2-3hr estimated)
- ✅ **toy2_ppu_init complete** (2-vblank warmup validated, 5/5 tests passing, 30 min actual vs 1-2hr estimated)

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

## Next Step: Choose toy3

**toy2 findings** (see `toys/toy2_ppu_init/LEARNINGS.md`):
- ✅ PPU 2-vblank warmup works perfectly (jsnes accurate)
- ✅ Frame timing confirmed (frame 1→2→3 progression)
- ✅ **Critical lesson**: NES RAM not zero-initialized (must explicitly init variables!)
- ✅ Standard init pattern established for all future toys

**toy3 candidates:**
1. **toy3_controller** - Controller input (3-step read sequence, new subsystem)
2. **toy3_full_init** - Combine toy1 + toy2 (integration: full init + sprite DMA)
3. **toy4_nmi** - NMI handler (vblank interrupt, OAM DMA in NMI)

**Recommended:** Controller input (covers next critical subsystem) OR Full init (integrates learned patterns)

**Pattern validated (2x):** LEARNINGS → SPEC → PLAN → TDD → Document findings → Update ORIENTATION

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

**Scaffolding:**
- `tools/new-toy.pl <name>` - Scaffold new toy directory (SPEC, PLAN, README, LEARNINGS)
- `tools/new-rom.pl <name> [dir]` - Scaffold ROM build (Makefile, nes.cfg, .s skeleton, play-spec.pl)

**Testing:**
- `toys/run-all-tests.pl` - Run all toy regression tests (uses `prove`)

**Documentation:**
- `tools/fetch-wiki.sh` - Cache NESdev wiki pages to `.webcache/`
- `tools/add-attribution.pl` - Add wiki attribution to learning docs

**Setup:**
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
