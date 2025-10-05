# Debug Automation Toy Plan

**Created**: October 2025
**Purpose**: Build headless NES testing infrastructure before hardware validation toys
**Goal**: Enable automated hardware behavior validation (Perl tests for PPU state, cycle counts, memory)

---

## Problem Statement

**Current state**: Manual validation only (Mesen2 GUI, human observation)
- Cycle counting: manual debugger interaction
- Memory inspection: manual watches
- Regression testing: impossible (no automation)

**Desired state**: Automated hardware tests
- `perl test.pl` validates PPU registers, cycle counts, memory state
- Regression suite for all toys (detect behavior changes)
- Fast iteration (no manual GUI clicking)

**Challenge**: No known headless NES emulator with test-friendly output on macOS ARM64

---

## Strategic Approach

**RTFM first**: Survey existing solutions before building
**Prototype cheaply**: Validate feasibility before committing
**One axis per toy**: Test one automation capability at a time
**Decide last**: Research → prototype → choose path (script vs fork)

**Outcome**: Either working FCEUX Lua solution OR plan to fork cycle-accurate emulator

---

## Toy Sequence

**Directory**: All debug toys live in `toys/debug/` to avoid numbering conflicts with main toys.

### Phase 1: Research (toys/debug/0-2)

**toys/debug/0_survey** - Catalog existing automation capabilities
- **Focus**: FCEUX, Mesen, Nestopia, ANESE capabilities research
- **Questions**:
  - Does FCEUX Lua work on macOS ARM64?
  - What can FCEUX Lua access? (memory, registers, cycle counter, breakpoints)
  - Does Mesen (C++) have CLI/scripting? (Mesen2 is GUI-only)
  - Nestopia/ANESE automation hooks?
- **Deliverable**: `toys/debug/0_survey/LEARNINGS.md` with capability matrix
- **Test approach**: Read docs, test each emulator with toy0 ROM
- **Success**: Know which emulator(s) are viable for automation

**toys/debug/1_fceux_lua** - Prototype FCEUX Lua scripting
- **Focus**: Can Lua read memory and output JSON?
- **Questions**:
  - Load ROM, advance frames programmatically?
  - Read arbitrary memory addresses?
  - Access CPU/PPU registers?
  - Breakpoint support?
  - Output to stdout (for Perl consumption)?
- **Deliverable**: Working Lua script that dumps memory/registers as JSON
- **Test approach**: Write hello_test.lua, run with FCEUX, parse output in Perl
- **Success**: `perl test.pl` validates toy0 ROM state via FCEUX Lua

**toys/debug/2_cycle_counting** - Can we measure cycles automatically?
- **Focus**: Cycle counter access via scripting
- **Questions**:
  - Does FCEUX Lua expose cycle counter?
  - Can we set breakpoints and measure elapsed cycles?
  - Accurate enough for vblank budget validation?
- **Deliverable**: Automated cycle measurement test
- **Test approach**: Run OAM DMA routine, measure via script, compare to manual Mesen2 count
- **Success**: Automated cycle count matches manual measurement (within tolerance)

---

### Phase 2: Decision Point

**After toys/debug/2, evaluate:**

**Option A: FCEUX Lua is sufficient**
- Proceed to toys/debug/3 (test framework)
- Build `tools/nes-test.pl` wrapper around FCEUX + Lua
- Document patterns in TOY_DEV_NES.md
- Update toys/PLAN.md with automated testing

**Option B: FCEUX Lua insufficient (missing features)**
- Identify which emulator to fork (criteria below)
- Proceed to Phase 3 (emulator fork toys)

**Option C: No viable solution**
- Accept manual validation only
- Document constraints in LEARNINGS.md
- Revert to original toys/PLAN.md

---

### Phase 3: Emulator Fork (if needed)

**Emulator selection criteria:**
1. Cycle-accurate (FCEUX, Mesen C++, Nestopia, ANESE)
2. Actively maintained or clean codebase
3. macOS compatible (native ARM64 or easily portable)
4. Permissive license (MIT/BSD/GPL acceptable)
5. Minimal dependencies (easier to strip GUI)

**toys/debug/3_emulator_choice** - Choose emulator to fork
- **Focus**: Evaluate codebase, build complexity, portability
- **Questions**:
  - Which builds cleanly on macOS ARM64?
  - How coupled is GUI to core emulation?
  - How hard to add `--headless` mode?
- **Deliverable**: Decision doc with chosen emulator + justification
- **Test approach**: Build each candidate, examine code structure
- **Success**: One emulator identified as best fork candidate

**toys/debug/4_headless_build** - Strip GUI, add headless mode
- **Focus**: Compile emulator without GUI dependencies
- **Questions**:
  - Can we build core emulation loop without SDL/GUI?
  - CLI argument parsing for `--headless`?
  - ROM loading and execution?
- **Deliverable**: `nes-headless rom.nes` runs ROM to completion
- **Test approach**: Run toy0, exit code 0 on success
- **Success**: Headless binary boots ROM without GUI

**toys/debug/5_memory_dump** - Add memory inspection
- **Focus**: `--dump-memory` flag outputs JSON
- **Questions**:
  - How to specify addresses to dump?
  - Format: JSON, TAP, custom?
  - Dump on breakpoint or fixed cycle?
- **Deliverable**: `nes-headless --dump-memory 0x0200-0x02FF rom.nes`
- **Test approach**: Perl parses JSON, validates OAM contents
- **Success**: `perl test.pl` reads emulator output, asserts memory state

**toys/debug/6_breakpoints** - Add breakpoint support
- **Focus**: `--breakpoint ADDR` stops execution, dumps state
- **Questions**:
  - Single breakpoint or multiple?
  - Dump all state (CPU, PPU, memory) or selective?
  - Resume execution or exit?
- **Deliverable**: `nes-headless --breakpoint 0x8000 --dump-state rom.nes`
- **Test approach**: Set breakpoint at known location, verify state dump
- **Success**: Automated test validates CPU registers at breakpoint

**toys/debug/7_cycle_counter** - Add cycle counting output
- **Focus**: `--max-cycles N` or breakpoint cycle reporting
- **Questions**:
  - Report total cycles or per-frame?
  - Cycle accuracy validated against reference?
- **Deliverable**: Automated cycle measurement for routines
- **Test approach**: Measure OAM DMA, compare to manual Mesen2 count
- **Success**: Automated count matches manual (±1 cycle tolerance)

---

### Phase 4: Test Framework (either path)

**toys/debug/final** - Build reusable test framework
- **Focus**: `tools/nes-test.pl` wrapper (either FCEUX Lua or headless fork)
- **Questions**:
  - API design: How do toy test.pl files invoke emulator?
  - What helpers needed? (read_memory, assert_cycles, etc.)
  - Integration with Test::More?
- **Deliverable**: Working test framework for hardware validation
- **Test approach**: Rewrite toy0 tests to use framework
- **Success**: `cd toys/toy0_toolchain && perl test.pl` validates hardware state

---

## Success Criteria

**Minimum viable:**
- Load ROM headlessly
- Read arbitrary memory addresses
- Output parseable by Perl (JSON, TAP, CSV)
- Exit code reflects success/failure

**Stretch goals:**
- Cycle counting (measure routine performance)
- Breakpoint support (dump state at specific PC)
- PPU state inspection (registers, nametables, OAM)
- Frame-by-frame stepping

**Dream scenario:**
- Community contribution (upstream PR or standalone tool)
- Blog post: "Automated NES Hardware Testing"
- Other NES devs adopt for their projects

---

## Constraints & Trade-offs

**Accuracy vs speed:**
- Cycle-accurate emulation slower but necessary for timing validation
- Fast emulators (not cycle-accurate) useless for our purpose

**Maintenance burden:**
- FCEUX Lua: No maintenance (upstream maintained)
- Forked emulator: We maintain patches, track upstream

**Portability:**
- FCEUX Lua: Works wherever FCEUX works
- Custom fork: Must support macOS ARM64 + Linux/Windows(?)

**Scope creep risk:**
- Building full-featured debugger is NOT the goal
- Minimal automation for test validation only
- "Simple thing that works" > "comprehensive debugging suite"

---

## Integration with Main Toy Plan

**After debug toys complete:**
1. Update `TOY_DEV_NES.md` with automated testing patterns
2. Revise `toys/PLAN.md` to include automated tests where feasible
3. Document in `tools/` directory (either Lua scripts or headless emulator)
4. Consider: Rewrite toy0 tests to use new framework (validate approach)

**Testing split (revised):**
- **Build infrastructure**: Perl + Test::More (unchanged)
- **Hardware behavior**: Automated where possible (NEW), manual fallback
- **Visual validation**: Manual only (screenshots, human judgment)

---

## Open Questions

**Q1**: Does FCEUX support headless mode? (--no-gui flag or similar?)

**Q2**: FCEUX Lua cycle counter accuracy - can it replace Mesen2 for measurements?

**Q3**: If we fork emulator, which license allows distribution? (GPL, MIT, BSD analysis)

**Q4**: Should headless emulator be NES-specific or support other systems? (SNES, GB, etc.)

**Q5**: Community interest - would others use this tool? (gauge before investing)

---

## Deferred Decisions

**Not deciding yet:**
- Which emulator to fork (if needed)
- JSON vs TAP vs custom output format
- Whether to support real hardware testing (Everdrive + serial output)
- Integration with CI/CD (GitHub Actions, etc.)

**Decide after toys/debug/0-2:**
- FCEUX Lua sufficient or need fork?
- How much automation is realistically achievable?
- Time investment vs value (is manual validation acceptable?)

---

## Status: Ready to Start toys/debug/0

**No blockers**. Research phase starts with documentation reading and capability testing.

**Recommendation**: Start toys/debug/0_survey (catalog existing solutions before building).

**Next steps**:
1. Create `toys/debug/0_survey/` directory
2. Research FCEUX, Mesen, Nestopia docs
3. Test FCEUX Lua with toy0 ROM
4. Document findings in LEARNINGS.md
5. Decide on Phase 2 path

---

## References

- **TOY_DEV_NES.md**: Testing philosophy (will update after this plan)
- **toys/PLAN.md**: Main hardware validation plan (deferred until debug tools ready)
- **learnings/.docdd/5_open_questions.md**: Questions about testing (Q7.x series)
- **toy0_toolchain**: Existing Perl test infrastructure to extend
