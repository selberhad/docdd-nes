#!/bin/bash
# Bootstrap git repository with clean commit history
# Stages: docs → learnings → tools → toy0

set -e  # Exit on error

# Check if already initialized
if [ -d .git ]; then
    echo "⚠️  Repository already initialized. Skipping git-bootstrap."
    echo "To re-bootstrap, delete .git/ first (WARNING: loses all git history)"
    exit 1
fi

echo "🚀 Bootstrapping ddd-nes git repository..."

# Initialize repo
git init
echo "✓ Initialized git repository"

# Stage 1: Core methodology and project docs
git add README.md DDD.md TOY_DEV_NES.md TOY_DEV.md CLAUDE.md ORIENTATION.md STUDY_PLAN.md
git add .gitignore 2>/dev/null || true  # Add if exists
git commit -m "docs: add core methodology and project documentation

- README.md: Project vision (dual deliverable: mdbook + toy library)
- DDD.md: Dialectic-Driven Development methodology
- TOY_DEV_NES.md: NES-specific toy development workflow
- TOY_DEV.md: Porting-context toy methodology (reference)
- CLAUDE.md: Agent instructions and project conventions
- ORIENTATION.md: Current status and navigation
- STUDY_PLAN.md: Wiki study roadmap (52 pages complete)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✓ Committed core documentation"

# Stage 2: Learning artifacts from wiki study
git add learnings/
git commit -m "docs(learnings): add wiki study artifacts (52 pages → 16 docs)

Technical learning docs (11):
- wiki_architecture.md: Core NES architecture
- getting_started.md: Init, registers, limitations
- sprite_techniques.md, graphics_techniques.md: PPU programming
- input_handling.md, timing_and_interrupts.md: I/O and cycle budgets
- optimization.md, math_routines.md: 6502 programming
- audio.md: APU and sound engines
- mappers.md: Bank switching
- toolchain.md: Tool selection

Meta-learning docs (5):
- 0_initial_questions.md: Original 10 question categories
- 1_essential_techniques.md through 4_mappers_complete.md: Progress tracking
- 5_open_questions.md: 43 questions (36 open, 7 answered) - toy roadmap

Study phase: Complete (Sep-Oct 2025)
Next phase: Practical validation through test ROMs

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✓ Committed learning artifacts"

# Stage 3: Development tools
git add tools/
git commit -m "chore(tools): add development utilities

- new-toy.pl: Auto-numbered toy scaffolding (SPEC/PLAN/LEARNINGS/README)
- fetch-wiki.sh: Cache NESdev wiki pages to .webcache/nesdevwiki/
- add-attribution.pl: Add wiki attribution footer to learning docs
- setup-brew-deps.sh: Install Homebrew toolchain (cc65, sdl2)
- git-bootstrap.sh: Initialize repo with staged commit history

Toolchain installed: cc65 2.19, Mesen2 (ARM64), SDL2
Platform: macOS Apple Silicon (ARM64)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✓ Committed development tools"

# Stage 4: Blog/docs (if exists)
if [ -d docs ]; then
    git add docs/
    git commit -m "docs(blog): add study phase reflections

- docs/blog/1_study-phase-complete.md: Lessons from systematic wiki study

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    echo "✓ Committed blog/docs"
fi

# Stage 5: toy0_toolchain (first working code!)
git add toys/toy0_toolchain/
git commit -m "feat(toy0): complete toolchain validation - first working ROM!

Test-driven build validation:
- 13 passing Perl tests (Test::More)
- Build pipeline: ca65 → ld65 → 24592-byte ROM
- Mesen2 validation: Loads successfully (green screen, NTSC)
- Makefile automation: all, clean, run, test targets
- Error handling: ca65/ld65 fail gracefully on invalid input

Files:
- hello.s: Minimal 6502 assembly (reset vector + infinite loop)
- nes.cfg: Custom NROM linker config (HEADER/CODE/VECTORS/CHARS)
- test.pl: 13 tests (build, file sizes, binary headers, Makefile, errors)
- Makefile: Automated build/test/run workflow
- SPEC.md, PLAN.md, LEARNINGS.md, README.md: Full DDD harness

Answered questions:
- Q1.1: Build workflow (ca65 -g → ld65 -C nes.cfg --dbgfile)
- Q1.2: Debug symbols (ca65 -g + ld65 --dbgfile generates .dbg)
- Q1.3: Mesen2 loads ROM successfully
- Q1.6: Makefile structure (targets working, dependencies tracked)

Key findings:
- Stock cc65 nes.cfg not minimal (required custom config)
- iNES header needs explicit .segment \"HEADER\" (not auto-generated)
- Test-driven approach 6x faster than estimated (no debug cycles)
- Custom nes.cfg + Makefile + test.pl reusable for future toys

Duration: 2 hours | Estimate: 1 day | Status: Complete ✅

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✓ Committed toy0_toolchain (FIRST WORKING ROM!)"

# Summary
echo ""
echo "✨ Git repository bootstrapped successfully!"
echo ""
echo "Commit history:"
git log --oneline --decorate
echo ""
echo "Current status:"
git status
echo ""
echo "🎮 First NES ROM complete! Ready for toy1."
