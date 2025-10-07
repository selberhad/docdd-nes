# ORIENTATION — docdd-nes

**Project**: NES game development using **Doc-Driven Development (DDD)** methodology. Greenfield learning project to test DDD in a constraint-driven context.

**Purpose**: Document what we learn as we learn it. NES development has a steep learning curve - capture knowledge or lose it.

---

## Project Structure

### Documentation (Start Here)

- **`ORIENTATION.md`** ← You are here (navigation guide)
- **`NEXT_SESSION.md`** - Current status, what to do next (ephemeral, session handoff)
- **`DDD.md`** - Doc-Driven Development methodology (project-agnostic)
- **`TOY_DEV.md`** - Toy development workflow (project-agnostic)
- **`TOY_DEV_NES.md`** - NES-specific toy development workflow
- **`TESTING.md`** - Testing strategy for LLM-driven development (Perl DSL design)
- **`CLAUDE.md`** - NES development guidelines and project conventions
- **`STUDY_PLAN.md`** - Wiki study roadmap

### Learning Artifacts

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
- Progress tracking after each study priority
- `5_open_questions.md` - Consolidated questions with cross-references

### Toy Artifacts

**Pattern**: Each `toys/toyN_name/` directory contains:
- `SPEC.md` - Behavioral contract
- `PLAN.md` - Implementation roadmap
- `LEARNINGS.md` - Findings and patterns for production
- `README.md` - What this toy validates
- Source files (`.s`, `.cfg`, `Makefile`)
- Tests (`t/*.t` - Perl test files using `NES::Test`)

**See `toys/STATUS.md`** for test counts and completion status.

**See `toys/PLAN.md`** for development roadmap (16 toys planned).

### Blog (AI-Written Reflections)

`docs/blog/` contains posts chronicling the development process:
- Study phase completion
- First ROM boots
- Testing infrastructure design
- Meta-learnings about LLM collaboration

See `docs/blog/README.md` for full index.

### Main Game (Future)

- `src/` - Main game assembly (created after toy prototyping validates patterns)
- `SPEC.md` - Game design (created when ready to build)
- `CODE_MAP.md` - Memory layout documentation

---

## Tools & Utilities

### Scaffolding

- **`tools/new-toy.pl <name>`** - Scaffold new toy directory (SPEC, PLAN, README, LEARNINGS)
- **`tools/new-rom.pl <name> [dir]`** - Scaffold ROM build (Makefile, nes.cfg, .s skeleton, play-spec.pl)

### Testing

- **`toys/run-all-tests.pl`** - Run all toy regression tests (uses `prove`)
- **`tools/inspect-rom.pl <rom.nes>`** - Decode iNES header and show reset vectors

### Documentation

- **`tools/fetch-wiki.sh <PageName>`** - Cache NESdev wiki pages to `.webcache/`
- **`tools/add-attribution.pl <file.md>`** - Add wiki attribution to learning docs
- `.webcache/` - Cached wiki pages (gitignored, created on demand)

### Setup

- **`tools/setup-brew-deps.sh`** - Install Homebrew toolchain dependencies (cc65, sdl2)

**See `tools/CODE_MAP.md`** for detailed documentation of each tool's implementation.

---

## Toolchain

**Development machine**: macOS Apple Silicon (ARM64) - prefer native tools or Homebrew packages.

**Core tools** (install via `tools/setup-brew-deps.sh`):
- **cc65** (ca65/ld65) - Assembler + linker
- **SDL2** - Mesen2 dependency

**Emulators**:
- **Mesen2** - Best debugger, cycle-accurate (manual download, native ARM64)
- **jsnes** - Headless testing (via `lib/nes-test-harness.js`, npm package)

**To be added when needed**:
- **NEXXT** - Graphics editor (when creating first tileset)
- **FamiStudio** - Music tracker (cross-platform alternative to FamiTracker)

---

## Testing Infrastructure

**Framework**: `NES::Test` Perl module - play-specs as executable contracts

**See `TESTING.md`** for full testing strategy, DSL design, and usage

---

## Workflow Patterns

### Discovery (Learning Phase)

1. Read `NEXT_SESSION.md` for current status and next steps
2. Check `learnings/.docdd/5_open_questions.md` for what needs validation
3. Use `tools/new-toy.pl <name>` to scaffold toy
4. Follow LEARNINGS → SPEC → PLAN → TDD cycle (see `TOY_DEV.md`)
5. Extract production patterns to LEARNINGS.md
6. Update `NEXT_SESSION.md` for next session

### Navigation Tips

- **Looking for architecture info?** → `learnings/*.md`
- **Looking for open questions?** → `learnings/.docdd/5_open_questions.md`
- **Looking for test examples?** → Any `toys/toyN_name/t/*.t`
- **Looking for current status?** → `NEXT_SESSION.md`, `toys/STATUS.md`
- **Looking for methodology?** → `DDD.md`, `TOY_DEV.md`, `TESTING.md`
- **Looking for project conventions?** → `CLAUDE.md`

---

## Common Commands

```bash
# Scaffold new toy
tools/new-toy.pl toy6_scrolling

# Scaffold ROM build in existing toy
cd toys/toy6_scrolling
../../tools/new-rom.pl scroll

# Build ROM
make

# Inspect ROM binary
../../tools/inspect-rom.pl scroll.nes

# Run all toy tests (from toys/ directory)
cd toys && ./run-all-tests.pl
```

---

**Philosophy**: Document everything. NES knowledge is hard-won - capture it or lose it. 📚
