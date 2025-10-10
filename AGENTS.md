# AGENTS.md - Quick Reference for AI Assistants

**Project**: NES game development using Dialectic-Driven Development (DDD) methodology

## Key Documents (Read These)
- **ORIENTATION.md** - Project structure, tools, navigation
- **NEXT_SESSION.md** - Current status, next steps (ephemeral)
- **CLAUDE.md** - Full development guidelines (this is condensed version)
- **DDD.md** - Methodology (project-agnostic)
- **TOY_DEV.md** / **TOY_DEV_NES.md** - Toy development workflow
- **TESTING.md** - Testing strategy (Perl DSL, play-specs)

## Critical Rules
- **Full autonomy required** - Never ask user to test ROMs manually or open emulators
- **Document constraints** - NES limitations are the point, capture them
- **Test assumptions early** - Build toy ROMs to validate before integrating
- **Automate immediately** - Write tool after 2nd repetition, not 10th
- **Memory map everything** - Update CODE_MAP.md with layout decisions
- **Check `pwd` first** - Relative paths depend on working directory

## Philosophy
- Document what we learn as we learn it (knowledge is hard-won, capture or lose it)
- Long-term deliverable: mdBook from blog posts + learnings (LLM-oriented, human-friendly)
- Modes: Discovery (toys, learning) → Execution (main game)

## Platform
- macOS Apple Silicon (ARM64) - prefer native tools, Homebrew packages
- See ORIENTATION.md for toolchain details

## Tooling Mindset
- Conciseness reduces tokens (LLMs parse terse code easily)
- Perl/shell preferred (Unix philosophy, pipelines, regex)
- RTFM before building, simplest thing first
- Write scripts immediately when patterns repeat (2nd time = automate)

## Documentation Practices
- **Systematic study**: Cache wiki → Study → Document → Attribute
- **Theory vs Practice**: Mark what needs validation, update with measurements
- **Meta-learnings**: Track progress in `learnings/.ddd/N_*.md`
- **CODE_MAP.md**: Update before structural commits
- **NEXT_SESSION.md**: Only at end of session (ephemeral handoff)

## Workflow
1. Read NEXT_SESSION.md for status
2. Check `learnings/.ddd/5_open_questions.md` for what needs validation
3. Use `tools/new-toy.pl` to scaffold
4. Follow LEARNINGS → SPEC → PLAN → TDD cycle
5. Extract patterns to LEARNINGS.md
6. Update NEXT_SESSION.md at session end

## Key Tools
- `tools/new-toy.pl <name>` - Scaffold toy directory
- `tools/new-rom.pl <name>` - Scaffold ROM build
- `toys/run-all-tests.pl` - Run all regression tests
- `tools/inspect-rom.pl` - Decode ROM headers
- `tools/fetch-wiki.sh` - Cache wiki pages
- `tools/add-attribution.pl` - Add wiki attribution

## Commits
- Conventional format: `type(scope): subject`
- Update docs before committing
- Linear history (prefer rebase)

## Next Step Protocol
- Always propose next action after completing task
- Don't say "done" - suggest specific next move
- Wait for approval before proceeding

## NES-Specific
- Comment generously (6502 is cryptic)
- Meaningful labels (`wait_vblank:` not `loop1:`)
- Document cycle counts for timing-critical code
- Test on multiple emulators (automated only)
- Track PRG-ROM banks, plan RAM layout (only 2KB!)
- Budget vblank time (~2273 cycles)

---

**Remember**: The docs ARE the deliverable. Capture constraints, test assumptions, document everything.
