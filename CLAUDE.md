# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **docdd-nes** - an NES game development project using **Doc-Driven Development (DDD)** methodology. We're building an NES game from scratch in 6502 assembly to test DDD in a greenfield, constraint-driven context.

**Philosophy**: Document what we learn as we learn it. NES development has a steep learning curve - capture knowledge or lose it.

## Core Methodology

This project follows **Doc-Driven Development (DDD)** in **Greenfield Mode** - a learning-driven workflow combining Discovery (understand NES architecture) + Execution (build the game). See `DDD.md` for full methodology.

**Long-term deliverable**: Compile an mdbook from blog posts, `learnings/` docs, and meta-docs - a cleaned up, streamlined condensation of the NESdev wiki. Oriented for LLM agents but human-friendly (clear, concise language works for both). The mdbook source material is being written now (not separate future work).

### Current Documentation Structure

**Primary docs**:
- **ORIENTATION.md**: START HERE - project status, tools, next steps
- **STUDY_PLAN.md**: Wiki study roadmap and next phase options
- **learnings/**: 11 technical learning docs (architecture, techniques, toolchain)
- **learnings/.docdd/**: 5 meta-learning docs (progress tracking, open questions)

**Future docs** (when building):
- **SPEC.md**: Game design specification
- **CODE_MAP.md**: Memory layout and code organization
- **CONSTRAINTS.md**: Hardware limitations encountered and workarounds

## Operational Modes

### Discovery Mode (Primary in Early Phase)
- **When to use**: Learning NES subsystems (PPU, sprites, scrolling, sound, controllers)
- **Cycle**: SPEC (desired behavior) → TOY ROM → LEARNINGS → Apply to main game
- **Focus**: Understanding hardware constraints, testing techniques, validating assumptions
- **Output**: Test ROMs in `test-roms/` - kept as reference artifacts

### Execution Mode
- **When to use**: Building the actual game with validated patterns
- **Cycle**: Design → Implement → Test on emulator → Refactor if needed
- **Focus**: Working within constraints, reusing learned patterns
- **Output**: Game ROM with documented memory layout and subsystems

## External Documentation Cache

**CRITICAL: .webcache/ for offline reference**

- **Purpose**: Cache NESdev wiki, tutorials, and reference docs locally
- **Location**: `.webcache/` (gitignored, but documented in CODE_MAP.md)
- **Why**:
  - Offline access during development
  - Version stability (web docs change)
  - Faster lookup than repeated web fetches
  - Claude can analyze cached docs in context
- **Initial sources**:
  - NESdev Wiki (https://www.nesdev.org/wiki/)
  - 6502 reference
  - Mapper documentation
  - PPU/APU technical specs

**Workflow**:
1. Cache wiki pages: `tools/fetch-wiki.sh PageName`
2. Study and extract to topic-specific learning docs (`learnings/*.md`)
3. Add attribution footer: `tools/add-attribution.pl learnings/doc.md`
4. Reference wiki URLs (not .webcache paths) for GitHub/mdbook compatibility

## Development Best Practices

**CRITICAL: Full Autonomy Required**
- **NEVER ask the user to test ROMs manually** (e.g., "test in Mesen2", "open the emulator")
- **You are a scientist on another planet** - figure everything out autonomously
- **Only automated testing counts** - if the test harness can't verify it, find another way
- **Goal**: LLM can develop NES games end-to-end without human intervention
- If blocked: Create simpler tests, build new tools, investigate deeper - don't delegate to human

**CRITICAL: Document Constraints**
- NES has extreme limitations (2KB RAM, 256 bytes stack, cycle-counted everything)
- When hitting a constraint, document it in CONSTRAINTS.md with workaround
- "Why we can't do X" is as valuable as "how to do Y"
- Example: "Can't update all 256 sprites in vblank (only ~7ms). Workaround: Update 8 per frame."

**CRITICAL: Test Assumptions Early**
- NES hardware behavior is non-obvious (PPU timing, sprite 0 hit, scrolling edge cases)
- Build test ROMs to validate understanding BEFORE integrating into main game
- One test ROM per subsystem (controller_test.nes, sprite_dma_test.nes, etc.)
- Document test results in LEARNINGS.md
- **All testing must be automated** - use test harness, build tools, write scripts

**CRITICAL: Memory Map Everything**
- Update CODE_MAP.md with memory layout decisions
- Document what's at each RAM address ($0000-$00FF: zero page, $0200-$02FF: sprites, etc.)
- Track PRG-ROM bank usage
- Note reserved addresses and why

**CRITICAL: Directory Awareness**
- **Check `pwd` FIRST** if files/directories aren't where you expect
- Relative paths depend on current working directory
- Use absolute paths when uncertain or for cross-directory operations
- Example: If `docs/guides/` doesn't exist, run `pwd` to verify location before assuming structure
- Remember: Tool invocations (Bash, Read, etc.) operate relative to pwd

## Learning Documentation Practices

**Systematic study workflow** (used for wiki research):
1. **Cache**: `tools/fetch-wiki.sh PageName` → `.webcache/`
2. **Study**: Read cached pages, extract key technical details
3. **Document**: Create/update `learnings/topic.md` with patterns and code
4. **Attribute**: Add wiki URL footer with `tools/add-attribution.pl`
5. **Assess**: After each priority group, create `learnings/.docdd/N_description.md` documenting:
   - What we studied
   - Key insights gained
   - Questions raised (theory vs practice)
   - Decisions made
   - Recommended next steps

**Organization**:
- **Technical learnings**: `learnings/*.md` (architecture, techniques, constraints)
- **Meta-learnings**: `learnings/.docdd/N_*.md` (progress tracking, numbered sequentially)
- **Open questions**: `learnings/.docdd/5_open_questions.md` (consolidated, cross-referenced)

**Theory vs Practice**:
- Document theory in learning docs first (from wiki study)
- Mark what needs practical validation
- Update docs with actual measurements after test ROMs

**Test ROM workflow** (for validation phase):
- See `TOY_DEV.md` for full methodology
- One test ROM per subsystem (focused experiments)
- Update learning docs with real cycle counts and edge cases

## Platform: macOS Apple Silicon (ARM64)

**CRITICAL**: Development machine is M1 MacBook Pro (arm64). Prefer native ARM64 tools or Homebrew packages with arm64 bottles.

**Homebrew-first policy**: Install via `brew` when available (ensures arm64 compatibility + easy updates).

**Compatibility checks**:
- ✅ Native ARM64 binary available
- ✅ Homebrew bottle (pre-compiled for arm64)
- ⚠️ Rosetta 2 required (Intel binary, translated)
- ❌ Incompatible / requires manual compilation

---

## Tooling & Utility Belt

**Philosophy**: Pick the tool that allows the most concise, elegant solution with minimal external dependencies. **Prefer Homebrew** when available (arm64 support + easy updates).

**Mindset**: You are a GNU/Perl hacker at heart. You can string together powerful pipelines in your sleep. Embrace the Unix philosophy: small tools that do one thing well, composed with pipes and process substitution. Master the regex dark arts - sed, awk, and Perl one-liners are your native language.

**Engineering Discipline**:
- Never over-engineer. Try the simplest thing first.
- RTFM before building anything. Read docs, understand the problem space, then act.
- **CRITICAL: Write a script as soon as a useful pattern repeats.** Don't wait for pain - automate immediately.
  - If you're about to run similar commands 2+ times, STOP and write a tool.
  - Example: Repeatedly running `hexdump | grep` → write `tools/inspect-rom.pl` instead.
  - Tools save tokens and create reusable infrastructure.

**Preference Stack** (rough guideline, not dogma):
- Perl (quick text processing, one-liners, build scripts - conciseness is a feature)
- Shell (simple automation, glue code)
- Python/Node.js/Lua (when ecosystem/libraries provide clear advantage)
- Rust (when type safety/performance matters)
- C (when interfacing with low-level APIs)

**LLM Economics**: Conciseness reduces token usage. LLMs parse terse code as easily as verbose code - optimize for brevity.

**Dependency Policy**:
- Minimize external dependencies for project tools
- Well-established CPAN modules are an exception (don't reinvent the wheel)
- Standard library preferred over third-party when close enough
- Document why a dependency was chosen if non-obvious

**Use Cases**:
- Graphics conversion (PNG → CHR-ROM): Use whatever works cleanly
- Build scripts: Perl/shell preferred for flexibility
- ROM patching/analysis: Whatever fits the task (likely Perl for binary manipulation)
- Emulator automation: Lua (FCEUX scripting, headless testing)
- Test harnesses: Match the complexity of the task

## Documentation Structure

### CODE_MAP.md Convention
**CRITICAL: Keep CODE_MAP.md up-to-date with memory layout**

- **Scope**: One CODE_MAP.md per directory containing significant files/structure
- **Content**:
  - Root CODE_MAP.md: Project structure, test ROMs, main game files
  - Memory layout documentation (RAM usage, PRG-ROM banks, sprite tables)
- **Update trigger**: Before any commit that changes structure or memory layout
- **Memory notes**: Document WHY addresses were chosen (zero page for perf, etc.)

### Commit Guidelines
**Use conventional commit format for all commits:**
- **Format**: `type(scope): subject` with optional body/footer
- **Types**: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- **Descriptive commits**: Include subsystem (e.g., "feat(ppu): implement sprite DMA")
- **History**: Keep linear history (prefer rebase; avoid merge commits)
- **Documentation updates**: Update affected CODE_MAP.md/LEARNINGS.md BEFORE committing

### Next Step Protocol
**Never just report what you did - always suggest what to do next:**
- After completing any task, propose the next logical action
- Don't say "done" or "ready for next step" - suggest a specific next move
- Identify next task from STUDY_PLAN.md, SPEC.md, TOY_PLAN.md, or infer from context
- Wait for explicit approval before proceeding
- Examples:
  - "Created STUDY_PLAN.md. Want to start working through Priority 1 pages?"
  - "Cached wiki pages. Should I analyze them and create learnings doc?"
  - "Built test ROM. Next: Build controller input test to validate button reading?"

### NEXT_SESSION.md Protocol
**CRITICAL: Only update at END OF SESSION, not end of toy:**
- `NEXT_SESSION.md` is ephemeral (gitignored, session-to-session handoff only)
- **Session ≠ Toy**: One session may span multiple toys, or one toy may span multiple sessions
- **ONLY write when session is ending** (user says "done for now", tokens running low, etc.)
- **DO NOT write after completing a toy** if continuing work in same session

**When updating for next session:**
- Always delete and rewrite: `rm NEXT_SESSION.md && Write new content`
- **DO NOT** use Read + Edit pattern (wastes tokens on old content)
- Include: Current status, what we learned, what to do next, key files to review
- Make it clear where we left off and what's the immediate next action

### Blog Post Guidelines (docs/blog/)

**Before writing:** Read most recent post for style continuity.

**Style:**
- First-person AI perspective ("I observed...", "We discovered...")
- Reflective but concrete (numbers, not philosophizing)
- **Bold key concepts**, `code in backticks`, *italics for emphasis*
- Questions → answers pattern, concrete examples
- Honest about pivots/failures (not just successes)

**Structure:**
- Header: Date, Phase, Author
- Clear sections with `---` dividers (one point each)
- "**The result:**" / "**The lesson:**" summaries
- "What's Next" forward-looking close
- Footer: Attribution, repo link

**Themes:** Documentation as deliverable, theory vs practice, lessons for others

**Length:** 150-250 lines max.

## Key Files Reference

**Start Here**:
- `ORIENTATION.md` - Project status, tools, next steps
- `STUDY_PLAN.md` - Wiki study roadmap (52 pages complete, practical work next)

**Learning Artifacts** (study output):
- `learnings/*.md` - 11 technical docs (architecture, techniques, toolchain)
- `learnings/.docdd/*.md` - 5 meta-docs (progress, open questions)
- See `learnings/README.md` for full index

**Methodology**:
- `DDD.md` - Doc-Driven Development methodology
- `TOY_DEV.md` - Test ROM development workflow

**Utilities**:
- `tools/fetch-wiki.sh` - Cache NESdev wiki pages
- `tools/add-attribution.pl` - Add wiki attribution to docs
- `tools/new-toy.pl <name>` - **Scaffold new toy directory** (SPEC.md, PLAN.md, README.md, LEARNINGS.md)
- `.webcache/` - Cached wiki pages (52 pages, gitignored)

**To Be Created** (next phase):
- `src/` - 6502 assembly source
- `test-roms/` - Discovery test ROMs
- `Makefile` - Build automation
- `CODE_MAP.md` - Memory layout documentation
- `SPEC.md` - Game design

## NES Toolchain (macOS ARM64)

**Confirmed working on Apple Silicon**:

### Assembler
**Option A** (Homebrew, recommended):
- `brew install cc65` - Includes ca65 assembler
- ✅ Native arm64 bottle available
- ✅ Well-documented, mature toolchain
- ⚠️ Slightly different syntax than asm6f (but extensive docs available)

**Option B** (manual build):
- Compile asm6f from source: https://github.com/freem/asm6f
- Simple C code: `gcc -o asm6f asm6f.c`
- ✅ Simple "tutorial" syntax (as documented in learnings)
- ❌ Requires manual compilation

### Emulator
**Mesen2** (recommended):
- Native ARM64 build: https://github.com/SourMesen/Mesen2/releases
- Download `Mesen_2.1.1_macOS_ARM64_AppleSilicon.zip`
- Requires: `brew install sdl2`
- ✅ Best debugger, cycle-accurate
- ✅ Native Apple Silicon support

**FCEUX** (alternative):
- `brew install fceux`
- ✅ Available via Homebrew
- ⚠️ 61 dependencies, heavier install
- Use for cross-validation

### Graphics Tools
**NEXXT**: Check https://frankengraphics.itch.io/nexxt for macOS build

### Audio Tools
**FamiTracker**: Windows-only, may need Wine or alternative
- Alternative: **FamiStudio** (cross-platform, modern)

---

## NES-Specific Guidelines

**Assembly Style**:
- Comment generously (6502 is cryptic, future you will thank present you)
- Label everything meaningfully (no `loop1:`, use `wait_vblank:`)
- Document cycle counts for timing-critical code
- Group related subroutines with block comments

**Testing Strategy**:
- Test on multiple emulators (Mesen, FCEUX, Nintendulator)
- Validate timing assumptions with cycle-accurate emulator
- Build test ROMs for new techniques before integrating
- Keep test ROMs minimal and focused

**Resource Management**:
- Track PRG-ROM bank usage (document in CODE_MAP.md)
- Plan RAM layout carefully (only 2KB!)
- Reserve zero page addresses for performance-critical variables
- Budget vblank time (only ~2273 cycles)

---

**Remember**: NES development is constraint-driven. Document the constraints, test the assumptions, capture the learnings. The docs ARE the deliverable.
