# ORIENTATION — docdd-nes

**Quick Start**: NES game development project using **Doc-Driven Development (DDD)** methodology. Greenfield learning project to test DDD in a constraint-driven context.

---

## Current State (October 2025)

**Phase**: 🎓 **Systematic Study Complete → Ready for Practical Work**

### Study Progress
- ✅ **52 wiki pages studied** (all core priorities complete)
- ✅ **11 technical learning docs** created
- ✅ **5 meta-learning docs** tracking progress
- ✅ **43 questions catalogued** (36 open, 7 answered)

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
- **Assembler**: asm6f (simple, beginner-friendly)
- **Emulator**: Mesen (best debugger, cycle-accurate)
- **Graphics**: NEXXT (all-in-one editor)
- **Audio**: FamiTracker + FamiTone2 engine
- **Mapper strategy**: Start NROM, migrate to UNROM when >32KB
- **Optimization policy**: Avoid unofficial opcodes unless proven bottleneck

---

## Next Step: Toolchain Setup & First ROM

**→ See `STUDY_PLAN.md` Option A (Recommended Next Phase)**

**Toolchain ready!** ✅ All dependencies installed (cc65, SDL2, Mesen2)

Next actions:
1. **Build minimal test ROM**: Validate build workflow with ca65/ld65
2. **Run on Mesen2**: Confirm emulator works with our ROMs
3. **Incrementally add subsystems**: Sprite → controller → audio
4. **Measure & update**: Real cycle costs vs theory in learning docs

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
- **`STUDY_PLAN.md`** - Wiki study roadmap (52 pages complete, next phase outlined)
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
- `docs/blog/1_study-phase-complete.md` - Reflections on systematic study phase

### To Be Created (Next Phase)
- `src/` - 6502 assembly source code
- `test-roms/` - Discovery test ROMs
- `graphics/` - CHR-ROM data, palettes
- `music/` - FamiTracker files
- `Makefile` - Build automation
- `CODE_MAP.md` - Memory layout documentation
- `SPEC.md` - Game design (after prototyping)

---

**Philosophy**: Document everything. NES knowledge is hard-won - capture it or lose it. 📚
