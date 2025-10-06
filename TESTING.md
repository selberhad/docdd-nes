# TESTING.md

**Vision**: LLM-assisted NES development with fast, precise feedback loops

## Goals

**Primary: Enable LLM agents to develop NES games iteratively**
- Write assembly → validate instantly (< 1 second)
- Precise error feedback ("Frame 45: sprite Y=100, expected Y=80")
- Deterministic replay (same inputs → same outputs, every time)
- Fast iteration (test 100 variations quickly, no manual GUI)

**TAS-style workflow** (LLM-assisted slow-run):
1. Agent writes assembly
2. Agent generates test scenario (input sequence + assertions)
3. Headless emulator runs deterministically
4. Agent gets precise feedback
5. Agent iterates until tests pass

**Core capabilities needed**:
- Frame-by-frame controller input encoding
- Rich assertions (memory, sprites, PPU state, audio)
- Visual validation (pixel/tile-level: "pixel (120,80) is color $0F" or "tile at (5,3) is pattern $42")
- Headless execution (no GUI, scriptable)
- Cycle-accurate determinism

**Platform support**:
- macOS (required, primary development platform)
- Linux (nice-to-have if minimal extra effort)
- Windows (not a priority)

## Non-Goals

- Frame-perfect speedrun optimization
- Human gameplay recording/replay
- Visual regression testing (screenshots) - initially
- Real-time performance (can be slower than 60fps if accurate)
- Supporting inaccurate emulators for speed

## Current State (October 2025)

**Phase 1 operational** - NES::Test DSL validated across 3.5 toys:
- **35/57 tests passing** (toy0: 6/6, toy1: 20/20, toy2: 5/5, toy3: 4/8 partial, toy4: 0/18 in progress)
- **jsnes accuracy validated** for Phase 1 scope (sprite DMA, PPU init, controller input, NMI timing)
- **Fast iteration** - <1 second per test suite, 257-frame tests run instantly
- **Infrastructure solid** - Persistent harness, TAP output, prove integration, regression testing

**Phase 1 limitations discovered:**
- ❌ No cycle counting (jsnes doesn't expose it) - Phase 2 required
- ❌ No frame buffer access (VRAM visibility limited) - Phase 2 required
- ⚠️ Frame progression must increase within single test file - workaround: split into t/*.t files
- ✅ Deterministic execution validated (same inputs → same outputs, every time)
- ✅ **Full autonomy maintained** - all validation automated, no manual testing required

**Phase 2 needs** (when Phase 1 limits hit):
- Cycle counting for vblank budget validation
- Frame buffer access for pixel/tile assertions
- VRAM inspection for nametable/pattern table validation

**Next**: Complete toy4 (NMI), implement remaining toys, document patterns for production

---

## Lessons Learned (October 2025)

**From 3.5 toys and 35 passing tests:**

### Test Structure Patterns

**✅ Multiple test files > single file**
- Each t/*.t file starts fresh emulator instance
- Avoids frame progression conflicts (can test frames 1, 2, 10 in each)
- Maps cleanly to test scenarios in SPEC.md
- Example: toy4 has 4 files (01-simple.t, 02-sprite.t, 03-wraparound.t, 04-integration.t)

**✅ Use prove for test suites**
- `play-spec.pl` → `exec 'prove', '-v', 't/'`
- TAP output, parallel execution, clear summary
- Integrates with run-all-tests.pl for regression testing

**✅ Scaffolding tools save time**
- `new-rom.pl` generates: Makefile, nes.cfg, .s skeleton, play-spec.pl template
- `new-toy.pl` creates: SPEC.md, PLAN.md, README.md, LEARNINGS.md
- Both tools validated and refined through use (directory detection bugs fixed)

### Debugging Patterns

**✅ Clean rebuild before deep debugging**
- toy3 lesson: Mysterious failures? Try `make clean && make` first
- Stale artifacts cause weird behavior (ROM doesn't match assembly)
- Saves hours of debugging (learned the hard way)

**✅ Timeboxing works**
- toy3 controller bug: 3 debugging attempts → timebox → move on
- Partial validation (4/8 tests) > no validation
- Document findings, return later with fresh perspective
- Unblocks other subsystems (toy4 NMI doesn't need controller working)

**✅ DEBUG=1 for tracing**
- NES::Test supports verbosity levels
- Helps diagnose test harness issues vs ROM bugs
- Example: `DEBUG=1 perl play-spec.pl`

### Test Writing Patterns

**✅ TDD discipline pays off**
- Write tests FIRST (Red phase - all failing)
- Implement assembly (Green phase - tests pass)
- Commit after each step
- Fast feedback loop (<1 second test runs)

**✅ Integration tests validate combinations**
- toy1 (OAM DMA) + toy2 (PPU init) + toy4 (NMI) = integration test
- Reuse validated patterns from earlier toys
- Catches interaction bugs early

**✅ Regression testing catches breakage**
- `run-all-tests.pl` runs all toys
- Detects when new code breaks old functionality
- Fast enough to run before every commit

### Emulator Behavior

**✅ jsnes determinism validated**
- Same inputs → same outputs (100% reliable across toys)
- Frame-accurate state inspection works
- Controller emulation accurate (toy3 bug was in ROM, not jsnes)
- OAM DMA timing correct (toy1 validated)

**✅ jsnes limitations clear**
- No cycle counting (can't validate vblank budget)
- Limited VRAM visibility (nametable inspection hard)
- Phase 2 will need different emulator for these features

**✅ Phase 2 emulator needs identified**
- Cycle counting requires different backend (jsnes doesn't expose)
- VRAM inspection needs direct access (nametable/pattern table reading)
- Potential candidates: FCEUX Lua API, TetaNES fork, custom jsnes extension
- Build Phase 2 tools when Phase 1 limits actually block progress

---

## Open Questions

### Input Encoding
**Q1**: ✅ **DECIDED: Perl DSL for play-specs**
- Play-specs are executable Perl scripts with custom DSL (not serialized data)
- Combines TAS-style input sequences + state assertions in one format
- Integrates with Test::More (TAP output)
- LLM-friendly (generates code better than arbitrary formats)
- Example:
```perl
use NES::Test;
load_rom "hello.nes";
at_frame 0 => sub { assert_cpu_pc 0x8000; };
press_button 'A';
at_frame 1 => sub { assert_ram 0x00 => 1; };
```

**Q2**: ✅ **DECIDED: Implicit frame progression (forward-only, monotonic)**
- DSL auto-advances emulator to requested frame
- Only dumps state when assertions execute (lazy evaluation)
- Declarative: `at_frame 100` advances from current frame to 100
- No keyframes/rewind - forward-only execution (simpler, sufficient)
- **Frame numbers must increase within a single test** (implementation constraint)
- **Workaround**: Split into multiple t/*.t files (each starts fresh emulator)
- Example:
```perl
at_frame 0   => sub { assert_cpu_pc 0x8000; };
press_button 'A';          # advances 1 frame with A pressed
at_frame 100 => sub { ... }; # auto-advances 99 frames
# Cannot go back to at_frame 1 here - use separate test file
```

### Assertion Language
**Q3**: ✅ **DECIDED: All three layers (composable)**
- **Low-level primitives** (always available): `assert_ram 0x0200 => 0x50`, `assert_cpu_pc 0x8000`
- **Mid-level helpers** (shipped with `NES::Test`): `assert_sprite 0, y => 80`, `assert_tile 5, 3 => 0x42`
- **High-level semantics** (user-defined): Custom helpers for game logic
- Unix philosophy: Small primitives compose into larger abstractions
- LLM can use any layer depending on game knowledge
- Example:
```perl
# Low:  assert_ram 0x50 => 1;
# Mid:  assert_sprite 0, y => 80;
# High: sub assert_player_jumped { ... }  # user-defined
```

**Q4**: ✅ **DECIDED: Both tile-level (primary) and pixel-level (when needed)**
- **Tile-level** (NES-native, stable): `assert_tile 5, 3 => 0x42`, `assert_palette 0, 3 => 0x30`
- **Pixel-level** (fine-grained): `assert_pixel 120, 80 => 0x0F`, `assert_framebuffer_matches 'expected.png'`
- Tile abstractions are LLM-friendly (hardware-native thinking)
- Pixel for edge cases (sprite positioning, scrolling artifacts, visual regression)
- Implementation details (Q6-Q8) deferred - design for ergonomics, not emulator limitations

**Q5**: ⏭️ **DEFERRED: Audio assertions**
- Complex (FFT analysis? Waveform comparison?)
- Not critical for initial LLM development workflow
- Focus on visual/state validation first
- Revisit when audio subsystem in main game (toy6_audio)

### Emulator Selection
**Q6**: ✅ **VALIDATED: jsnes sufficient for Phase 1**
- **Tested across 3.5 toys** - sprite DMA, PPU init, controller input, NMI timing all work
- **Deterministic** - Same inputs → same outputs (validated via regression tests)
- **Fast** - 257-frame tests run instantly, full toy suites < 1 second
- **Accurate enough** - Phase 1 scope (state inspection, basic timing) works reliably
- **Limitations known** - No cycle counting, limited VRAM access (Phase 2 needs)
- DSL design is emulator-agnostic (can swap backend for Phase 2)
- **Fully automated** - No manual testing, all validation via test harness

**Q7**: ✅ **DECIDED: Cycle counting required for LLM development**
- NES is cycle-budget constrained (vblank = 2273, OAM DMA = 513)
- LLM needs automated validation: "Does this fit in vblank?"
- Without cycle counting, LLM is blind to timing constraints
- DSL design:
```perl
at_frame 1 => sub {
    assert_vblank_cycles_lt 2273;           # vblank budget check
    assert_routine_cycles 'oam_dma' => 513; # validate timing
};
```
- **Implementation note**: jsnes doesn't expose cycles → need FCEUX Lua, fork TetaNES, or alternative

**Q8**: ✅ **DECIDED: Frame buffer access required**
- Pixel assertions already decided in Q4: `assert_pixel 120, 80 => 0x0F`
- Visual regression: `assert_framebuffer_matches 'expected.png'`
- Required for validating sprite positioning, scrolling, rendering artifacts
- Emulator must expose frame buffer for DSL to work

### TAS Integration
**Q9**: ⏭️ **DEFERRED: Import/export TAS formats (eventual goal)**
- Build Perl DSL first (independent format)
- Future: Import FM2/BK2 → convert to play-spec
- Future: Export play-spec → FM2/BK2 for TAS tools
- Not immediate priority (LLM workflow comes first)
- Benefit: Leverage TAS community tools (BizHawk, FCEUX editor) later

**Q10**: ✅ **DECIDED: Perfect determinism required (non-negotiable)**
- NES hardware is completely deterministic (no hardware RNG, finite state)
- Same initial state + same inputs = same outputs, always
- Any non-determinism is an emulator bug (not acceptable)
- DSL must enforce:
  - Known initial RAM state (zero or specific pattern)
  - Cycle-accurate execution (no timing drift)
  - Same emulator version (document in play-spec)
- **Implementation:** Validate emulator determinism before building DSL
- Non-deterministic emulator = unsuitable for testing (disqualified)

### Workflow Integration
**Q11**: ✅ **DECIDED: Progressive automation (3-phase approach)**

**Phase 1: jsnes subset (immediate)**
- State assertions: `assert_ram`, `assert_cpu_pc`, `assert_sprite`, `assert_ppu`
- Frame control: `at_frame N`, `press_button`
- Available now, build toys with this
- Validates: sprite DMA works, controller input, PPU state

**Phase 2: Extended DSL (when Phase 1 limits hit)**
- Cycle counting: `assert_vblank_cycles_lt 2273`, `assert_routine_cycles`
- Frame buffer: `assert_pixel`, `assert_framebuffer_matches`
- Requires: FCEUX Lua, TetaNES fork, or alternative emulator
- Build when we know exactly what's needed (experience from Phase 1)

**Phase 3: Advanced automation (when needed)**
- Complex visual validation (build pixel diff tools, pattern matching)
- Performance profiling (instrument emulator for detailed metrics)
- Real hardware compatibility (build automated hardware test rig if needed)

**toys/PLAN.md integration:**
- ✅ Each toy has t/*.t test files (Phase 1 automation)
- ✅ run-all-tests.pl for regression testing across all toys
- ✅ Automated debugging tools (inspect-rom.pl for ROM analysis, DEBUG=1 for tracing)
- ✅ Scaffolding tools (new-toy.pl, new-rom.pl) generate test infrastructure automatically

**Q12**: ✅ **DECIDED: LLM generates both play-spec and assembly from human requirements**

**The workflow:**
1. **Human writes SPEC.md** (natural language): "When player presses A, sprite jumps"
2. **LLM generates play-spec** (executable contract):
   ```perl
   press_button 'A';
   at_frame 1 => sub { assert_sprite 0, y => { $_ < 100 }; };
   ```
3. **Human reviews play-spec** ("Is this what I meant?")
4. **LLM generates assembly** to make tests pass
5. **LLM iterates** until play-spec passes

**Why this works:**
- play-spec = formalized executable contract (not just documentation)
- LLM translates human intent → precise assertions
- Both play-spec and assembly are regenerable from SPEC.md
- "Code is disposable, specs are durable" - play-spec IS the durable spec

**DDD for LLMs:** Natural language → executable contract → passing implementation

### Tooling
**Q13**: ✅ **DECIDED: Perl DSL (`NES::Test` module)**
- Play-specs are Perl scripts using `NES::Test` DSL
- Module wraps jsnes (or other emulator), provides assertion helpers
- Perl spawns Node.js process, controls emulator, validates output
- Reuses existing pattern from toys/debug/1_jsnes_wrapper

**Q14**: ✅ **DECIDED: TAP (Test Anything Protocol)**
- Native Test::More integration (TAP output)
- Standard Perl test output (ok/not ok)
- Works with existing tooling (prove, harness)
- LLM-friendly (simple text format, clear pass/fail)
