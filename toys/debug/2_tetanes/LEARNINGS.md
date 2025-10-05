# Learning Goals: TetaNES CLI Investigation

**Created**: October 2025
**Toy**: toys/debug/2_tetanes
**Purpose**: Evaluate TetaNES Rust emulator for headless testing, compare to jsnes

---

## Questions to Answer

**Q1**: Can TetaNES run headlessly on macOS ARM64?
- Cargo install works?
- CLI execution without GUI?
- --silent flag suppresses display?

**Q2**: What CLI output does TetaNES provide?
- Stdout/stderr format?
- Any state dumping capabilities?
- Exit codes on success/failure?

**Q3**: Can we extract state from TetaNES?
- Memory dumps?
- Register access?
- PPU state inspection?

**Q4**: How accurate is TetaNES vs jsnes?
- Run toy0 ROM on both
- Compare CPU/PPU state
- Which is closer to Mesen2 manual validation?

**Q5**: Can we use tetanes-core library directly?
- Rust binary that links tetanes-core?
- Programmatic state access?
- Effort vs CLI wrapper approach?

---

## Research Path

### Phase 1: Installation & CLI Testing
1. Install: `cargo install tetanes`
2. Run toy0: `tetanes ../../toy0_toolchain/hello.nes`
3. Test --silent: `tetanes --silent ../../toy0_toolchain/hello.nes`
4. Document CLI behavior (output, exit codes, performance)

### Phase 2: State Extraction
**Option A: CLI wrapper**
- Check if TetaNES has debug output flags
- Parse stdout/stderr for state info
- Effort: Low if debug output exists, High if need to patch

**Option B: tetanes-core library**
- Write minimal Rust binary using tetanes-core
- Link library, load ROM, run frames, dump state
- Output JSON to stdout
- Effort: Medium (Rust code + JSON serialization)

**Option C: Modify TetaNES source**
- Fork TetaNES, add `--dump-state` flag
- Effort: Medium-High (understand codebase, add feature)

### Phase 3: Accuracy Validation
1. Run toy0 on TetaNES (via chosen method)
2. Run toy0 on jsnes (already done in toy1)
3. Manually inspect toy0 on Mesen2
4. Compare all three:
   - CPU registers (PC, A, X, Y, SP)
   - PPU state (NMI flag, pattern tables)
   - Memory (OAM, zero page)
5. Document discrepancies

---

## Success Criteria

**Minimum viable:**
- TetaNES runs toy0 ROM successfully
- Can extract basic state (CPU registers at minimum)
- Accuracy ≥ jsnes (comparable or better)

**Ideal:**
- Full state dump (CPU, PPU, memory ranges)
- JSON output (easy Perl integration)
- Higher accuracy than jsnes (closer to Mesen2)
- Fast execution (comparable to jsnes)

**Stretch:**
- Cycle counting (if tetanes-core exposes it)
- Reusable Rust binary for all future toys
- Better than FCEUX Lua (headless + accurate)

---

## Findings

### Installation

**Cargo install:**
- [x] Command executed: `cargo install tetanes`
- [x] macOS ARM64 compatibility verified: ✅ Native ARM64, builds cleanly
- [x] Installation time: ~1 minute 6 seconds (compilation)
- [x] Binary location: `/Users/emadum/.cargo/bin/tetanes`
- [x] Version: 0.12.2

### CLI Testing

**Basic execution:**
- [x] `tetanes rom.nes` tested
- [x] Window behavior: Opens GUI window (wgpu-based renderer)
- [x] Output captured: Logs to stderr (tracing framework)
- [x] Exit code: N/A (runs until killed with timeout)

**Silent mode:**
- [x] `tetanes --silent rom.nes` tested
- [x] GUI suppressed? **NO** - only silences audio, still opens window
- [x] Still functional? Yes, emulation runs with GUI but no sound

**Performance:**
- [x] Execution speed: Fast, native Rust performance
- [x] Comparison to jsnes: Comparable (both instant for 1 frame)

**CLI Limitations:**
- ❌ No true headless mode (always opens window)
- ❌ No debug output flags (no `--dump-state` or similar)
- ❌ No way to extract state via CLI alone

### State Extraction

**Method chosen:**
- [ ] CLI wrapper (parse output) - **NOT VIABLE** (no debug output)
- [x] tetanes-core binary (Rust code) - **ATTEMPTED**
- [ ] Fork + patch (--dump-state flag) - **NOT ATTEMPTED** (too much effort)

**Implementation:**
- [x] Code written: `src/main.rs` (37 lines Rust)
- [x] State extraction works: **PARTIAL**
- [x] Output format: JSON

**What works:**
- ✅ Load ROM via tetanes-core library
- ✅ Run frames: `deck.clock_frame()`
- ✅ Access Work RAM: `deck.wram()` returns 2048 bytes (0x0000-0x07FF)
- ✅ Save state: `deck.save_state()` creates 12KB binary file

**What doesn't work:**
- ❌ **No CPU register access** (PC, A, X, Y, SP not exposed in ControlDeck API)
- ❌ **No PPU state access** (flags, registers not exposed)
- ❌ **No OAM access** (sprite memory not exposed)
- ❌ **Save state is binary** (proprietary "TETANES" format, not human-readable)

**Root cause:** tetanes-core ControlDeck API is **high-level**, designed for emulator UIs:
- Exposes: `wram()`, `sram()`, `frame_buffer()`, `audio_samples()`
- Hides: CPU struct, PPU struct, internal state

**To get CPU/PPU access would require:**
1. Fork tetanes-core
2. Add public getters for CPU/PPU structs
3. Serialize state to JSON manually
4. Effort: **High** (several hours, ongoing maintenance)

### Accuracy Comparison

**toy0 ROM state comparison:**

| Component | TetaNES | jsnes | Mesen2 (manual) | Winner |
|-----------|---------|-------|-----------------|--------|
| CPU PC    | N/A (not accessible) | 32769 | ? | jsnes |
| CPU A     | N/A (not accessible) | 0 | ? | jsnes |
| CPU X     | N/A (not accessible) | 0 | ? | jsnes |
| CPU Y     | N/A (not accessible) | 0 | ? | jsnes |
| CPU SP    | N/A (not accessible) | 511 | ? | jsnes |
| PPU flags | N/A (not accessible) | 0 | ? | jsnes |
| WRAM[0]   | 254 (random) | 255 | ? | Comparable |

**Verdict:**
**jsnes wins by API accessibility** - TetaNES is likely more accurate, but testing it requires forking the library. jsnes provides direct state access out of the box.

---

## Decision Matrix

**Actual result: TetaNES is NOT TESTABLE without forking**

**Why jsnes wins:**
1. ✅ **API accessibility**: Direct access to `cpu.mem`, `cpu.REG_*`, `ppu.*`
2. ✅ **Already working**: toy1 complete with 16 passing tests
3. ✅ **No maintenance**: npm package, no forking required
4. ✅ **JSON output**: Easy Perl integration

**Why TetaNES fails for testing:**
1. ❌ **No state access**: CPU/PPU internals not exposed
2. ❌ **Requires fork**: Would need to modify tetanes-core library
3. ❌ **High effort**: Several hours to add accessors + ongoing maintenance
4. ❌ **Not headless**: CLI still opens window (no true headless mode)

**TetaNES advantages (not realized):**
- Higher accuracy (>90% game compat) - **CAN'T VERIFY** without state access
- Native performance - **IRRELEVANT** if can't extract test data
- Active development - **DOESN'T HELP** if API isn't test-friendly

---

## Final Recommendation

**❌ Do NOT use TetaNES for automated testing**

**Reasons:**
1. API designed for emulator UIs, not test automation
2. Would require forking tetanes-core (high maintenance burden)
3. jsnes already provides everything we need
4. Effort doesn't justify potential accuracy gains (can't measure without forking first)

**✅ Stick with jsnes (from toy1)**
- Working solution (16 tests passing)
- Direct state access
- Zero maintenance
- Good enough for our use case

**Next steps:**
1. ✅ Mark toy2 as complete (TetaNES investigated, rejected)
2. ✅ Use jsnes wrapper from toy1 for future hardware validation
3. ⏭️ If jsnes proves inaccurate later, revisit wasm-nes or FCEUX Lua
4. ⏭️ Document jsnes as recommended approach in TOY_DEV_NES.md

---

## Artifacts Created

**Code:**
- `Cargo.toml` - Rust project dependencies (tetanes-core, serde_json)
- `src/main.rs` - Minimal tetanes-core wrapper (51 lines)
- Binary: `target/release/tetanes-headless` (works but limited)

**Documentation:**
- This LEARNINGS.md
- Cached READMEs in `.webcache/` (tetanes, plastic)

**Key Finding:**
tetanes-core ControlDeck API provides:
```rust
deck.wram() -> &[u8]           // Work RAM (2048 bytes)
deck.sram() -> &[u8]           // Save RAM
deck.frame_buffer() -> &[u8]   // Video output
deck.audio_samples() -> &[f32] // Audio output
deck.save_state(path)          // Binary save state
```

But does NOT provide:
```rust
// NOT AVAILABLE:
deck.cpu()    // No CPU access
deck.ppu()    // No PPU access
deck.peek()   // No memory peek
deck.cycles() // No cycle counter
```

**Lesson learned:** High-level emulator libraries optimize for UI use cases, not test automation. Always check API before committing to a library.
