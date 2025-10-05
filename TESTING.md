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

## Current State

**Phase 1 (complete)**: jsnes wrapper for basic state inspection
- 16 tests passing
- CPU/PPU/OAM access via JSON
- Headless Node.js execution
- Accuracy unvalidated

**Next**: Define input encoding format, assertion language, emulator selection

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

**Q2**: ✅ **DECIDED: Implicit frame progression (forward-only)**
- DSL auto-advances emulator to requested frame
- Only dumps state when assertions execute (lazy evaluation)
- Declarative: `at_frame 100` advances from current frame to 100
- No keyframes/rewind - forward-only execution (simpler, sufficient)
- Example:
```perl
at_frame 0   => sub { assert_cpu_pc 0x8000; };
press_button 'A';          # advances 1 frame with A pressed
at_frame 100 => sub { ... }; # auto-advances 99 frames
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
**Q6**: ⏭️ **DEFERRED: jsnes accuracy validation**
- Compare against Mesen2 when implementing `NES::Test`
- Design DSL independent of emulator choice
- Fallbacks ready: wasm-nes, FCEUX Lua, or fork TetaNES

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

**Phase 3: Human/Mesen2 (what can't be automated)**
- Complex visual judgment (does it "look right"?)
- Edge case debugging (non-deterministic issues)
- Real hardware validation (Everdrive testing)

**toys/PLAN.md integration:**
- Categorize each toy's validation as Phase 1/2/3
- Start automating with Phase 1 DSL immediately
- Manual Mesen2 fills gaps until Phase 2 ready

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
