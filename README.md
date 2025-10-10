# ddd-nes

**NES game development learning project using Dialectic-Driven Development (DDD)**

Building an NES game from scratch in 6502 assembly to test DDD methodology in a greenfield, constraint-driven context while creating a comprehensive, agent-facing reference book.

---

## Project Vision

**Dual deliverable:**

1. **Agent-facing mdBook**: A clean, concise distillation of NESdev knowledge optimized for LLM agents (but human-friendly)
   - Compiled from blog posts, learning docs, and meta-docs (intermediate source material)
   - Condensed from NESdev wiki and practical experience
   - Focused on constraints, cycle budgets, and working patterns
   - Theory validated through practice (measured cycle counts, tested techniques)

2. **Toy library**: Working reference implementations demonstrating each technique
   - Test ROMs proving hardware behavior (PPU, APU, sprites, scrolling, etc.)
   - Build infrastructure examples (toolchain, asset pipelines, Makefiles)
   - Sample code referenced in the book (like a programming textbook)
   - Permanent artifacts showing "this pattern works on real hardware"

**Philosophy**: Document what we learn as we learn it. NES development has a steep learning curve—capture knowledge or lose it. When theory meets the cycle counter, update the theory.

---

## Methodology

This project follows **Dialectic-Driven Development (DDD)** in **Discovery Mode**:

- **Learning-first approach**: Questions → Experiments → Findings → Production
- **Toy models**: Minimal test ROMs isolating single subsystems (one axis of complexity)
- **Test-driven infrastructure**: Perl + Test::More for build validation
- **Manual hardware validation**: Mesen2 debugger for timing, cycle counting, behavior verification
- **Theory updates**: Measured reality replaces wiki speculation in learning docs

See `DDD.md` for core methodology, `TOY_DEV_NES.md` for NES-specific toy development workflow.

---

## Repository Structure

```
ddd-nes/
├── CODE_MAP.md                  # Project structure reference
├── AGENTS.md                    # Quick reference for AI assistants
├── CLAUDE.md                    # Full development guidelines
├── ORIENTATION.md               # Navigation guide
├── DDD.md                       # Methodology (project-agnostic)
├── TOY_DEV.md / TOY_DEV_NES.md  # Toy development workflows
├── TESTING.md                   # Testing strategy (Perl DSL)
│
├── learnings/                   # Technical learning docs
│   ├── wiki_architecture.md     # Core NES architecture
│   ├── sprite_techniques.md     # PPU sprite programming
│   ├── audio.md                 # APU, sound engines
│   └── .ddd/                  # Meta-learning docs
│       └── 5_open_questions.md  # Questions → toy roadmap
│
├── toys/                        # Test ROM library
│   ├── STATUS.md                # Test counts, completion status
│   ├── PLAN.md                  # Development roadmap
│   ├── run-all-tests.pl         # Regression test runner
│   └── toy*_*/                  # Individual toys (SPEC, PLAN, LEARNINGS)
│
├── lib/                         # Testing infrastructure (CODE_MAP.md)
│   ├── NES/Test.pm              # Perl DSL for play-specs
│   └── nes-test-harness.js      # jsnes headless wrapper
│
├── tools/                       # Utility scripts (CODE_MAP.md)
│   ├── new-toy.pl               # Scaffold toy directory
│   ├── new-rom.pl               # Scaffold ROM build
│   ├── inspect-rom.pl           # Decode ROM headers
│   └── setup-brew-deps.sh       # Install toolchain
│
├── docs/blog/                   # AI-written reflections
│   └── README.md                # Blog post index
│
└── .webcache/                   # Cached wiki pages (gitignored)
```

**See `CODE_MAP.md` and subdirectory CODE_MAP files** for detailed documentation of each area.

---

## Quick Start

### Prerequisites (macOS ARM64)
```bash
# Install toolchain dependencies
./tools/setup-brew-deps.sh  # Installs cc65, sdl2

# Download Mesen2 (ARM64 native)
# https://github.com/SourMesen/Mesen2/releases
# Extract to /Applications/Mesen.app
```

### Build First Toy
```bash
cd toys/toy0_toolchain
make              # Build hello.nes
make test         # Run Perl test suite
make run          # Open in Mesen2 emulator
```

### Create New Toy
```bash
./tools/new-toy.pl sprite_dma    # Creates toys/toy1_sprite_dma/
cd toys/toy1_sprite_dma
# Edit LEARNINGS.md (define learning goals first)
# Edit SPEC.md, PLAN.md
# Implement, test, commit
```

---

## Documentation Workflow

**Study → Document → Validate → Refine**

1. **Study phase** (complete): Cache wiki pages, extract to learning docs
   ```bash
   tools/fetch-wiki.sh PPU_sprites        # Cache to .webcache/
   # Extract key info to learnings/sprite_techniques.md
   tools/add-attribution.pl learnings/sprite_techniques.md
   ```

2. **Toy phase** (current): Build test ROMs, measure reality
   ```bash
   # Learning goals in toy LEARNINGS.md link to 5_open_questions.md
   # Implement ROM, measure cycles/behavior in Mesen2
   # Update theory docs with findings
   ```

3. **Book phase** (future): Compile learnings into mdbook
   - Source material: Blog posts + learning docs + meta-docs (already written!)
   - Clean up for clarity, organize by theme
   - Add toy code snippets as examples
   - Cross-reference toys as "see toy3_sprite_input for working implementation"
   - Publish as agent-facing NES development guide

---

## Key Design Decisions

**Toolchain** (macOS ARM64 native):
- **Assembler**: cc65 (ca65/ld65) via Homebrew - ARM64 bottles, mature toolchain
- **Emulator**: Mesen2 (native ARM64) - best debugger, cycle-accurate
- **Graphics**: NEXXT (when needed) - all-in-one tile editor
- **Audio**: FamiStudio (cross-platform) or FamiTracker (Windows/Wine)

**Mapper progression**: NROM (16KB) → UNROM (128KB+) → MMC1 (if needed)

**Testing approach**:
- Build infrastructure: Test-driven with Perl + Test::More
- Hardware behavior: Manual validation with Mesen2 debugger
- Theory updates: Replace wiki speculation with measured cycle counts

**Documentation as deliverable**: The mdbook is the primary artifact, the game is the validation tool.

---

## Meta

[![Built with DDD](https://img.shields.io/badge/built_with-DDD-blue)](https://github.com/dialecticianai/ddd-book)

**Platform**: macOS Apple Silicon (ARM64) - M1 MacBook Pro

**License**: TBD (project in progress)

**Contributing**: Solo learning project (for now). Collaboration with NESHacker planned for future phases.

---

## References

- **Methodology**: `DDD.md`, `TOY_DEV_NES.md`
- **Orientation**: `ORIENTATION.md`, `STUDY_PLAN.md`
- **Learning docs**: `learnings/` directory
- **Open questions**: `learnings/.ddd/5_open_questions.md`
- **NESdev wiki**: https://www.nesdev.org/wiki/ (primary reference)
- **DDD book**: https://dialecticianai.github.io/ddd-book/
