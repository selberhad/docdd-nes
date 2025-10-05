# Learning Goals: NES Emulator Automation Survey

**Created**: October 2025
**Toy**: toys/debug/0_survey
**Purpose**: Research existing NES emulator automation capabilities before building custom solution

---

## Questions to Answer

### FCEUX
**Q1**: Does FCEUX run on macOS ARM64?
- Homebrew availability?
- Native ARM64 or Rosetta 2?
- GUI vs headless modes?

**Q2**: What can FCEUX Lua scripting do?
- Memory read/write (CPU, PPU, OAM)?
- Register access (CPU, PPU)?
- Cycle counter access?
- Breakpoint support?
- Frame advance/step execution?
- Output to stdout/file?

**Q3**: Can FCEUX run headless (without GUI)?
- CLI flags for automation?
- Lua script → run → exit workflow?
- Exit codes on success/failure?

**Q4**: FCEUX Lua API documentation quality?
- Official docs complete?
- Examples available?
- Community support active?

### Mesen
**Q5**: Does Mesen (C++ version, not Mesen2) have CLI/scripting?
- Mesen2 is GUI-only (confirmed)
- Original Mesen: Automation hooks?
- Scriptable API?

**Q6**: Mesen source code accessibility?
- Clean codebase for potential fork?
- macOS build complexity?
- License (GPL, MIT, BSD)?

### Nestopia
**Q7**: Does Nestopia support automation?
- CLI interface?
- Scripting hooks?
- Debugger API?

**Q8**: Nestopia codebase evaluation?
- Active maintenance status?
- macOS ARM64 compatibility?
- Fork potential if needed?

### ANESE
**Q9**: Does ANESE (educational emulator) support automation?
- Minimal codebase = easier to modify?
- Cycle accuracy sufficient?
- Scriptable or CLI?

**Q10**: ANESE as fork candidate?
- Code cleanliness?
- Documentation quality?
- Build complexity?

### General
**Q11**: Which emulator is most cycle-accurate?
- FCEUX vs Mesen vs Nestopia accuracy comparison
- Sufficient for our cycle counting needs?

**Q12**: Best path forward?
- Use existing solution (FCEUX Lua)?
- Fork emulator for custom headless mode?
- Accept manual validation only?

---

## Success Criteria

**Minimum viable outcome:**
- Know which emulator(s) support automation
- Understand FCEUX Lua capabilities (most promising)
- Identify fork candidate if scripting insufficient

**Ideal outcome:**
- FCEUX Lua can read memory, count cycles, run headless
- No custom emulator fork needed
- Clear path to automated hardware tests

**Fallback:**
- Document why automation isn't feasible
- Accept manual validation workflow
- Revisit when better tools exist

---

## Research Methodology

1. **Documentation phase**: Read official docs (FCEUX Lua API, emulator READMEs)
2. **Installation phase**: Install FCEUX, test on toy0 ROM
3. **Capability testing**: Write minimal Lua scripts to test features
4. **Evaluation**: Compare against our needs (memory, cycles, headless)
5. **Decision**: Recommend path forward (Lua vs fork vs manual)

---

## Findings

### FCEUX Investigation

**Installation:**
- [x] Homebrew availability checked - ✅ Available (`brew install fceux`)
- [x] macOS ARM64 compatibility verified - ✅ Native ARM64 bottle
- [x] Version tested: 2.6.6_7 (61 dependencies installed, ~300MB)

**Lua API Capabilities** (from cached docs: `.webcache/fceux/LuaFunctionsList.html`):
- ✅ **Memory read**: `memory.readbyte(addr)`, `memory.readbyterange(addr, len)`
- ✅ **CPU registers**: `memory.getregister("pc")`, `memory.setregister("pc", val)`
- ✅ **PPU memory**: `ppu.readbyte(addr)`, `ppu.readbyterange(addr, len)`
- ✅ **Cycle counter**: `debugger.getcyclescount()`, `debugger.resetcyclescount()`
- ✅ **Frame control**: `emu.frameadvance()`, `emu.framecount()`
- ✅ **Breakpoints**: `debugger.hitbreakpoint()` (custom breakpoint handler)
- ✅ **Output**: `print()` outputs to terminal (confirmed in test)

**Headless Mode:**
- ❌ **No headless flag** - `--help` shows no `--headless`, `--nogui`, or `--batch` options
- ⚠️ **GUI required**: FCEUX opens Qt GUI even when running with `--loadlua`
- ⚠️ **os.exit() blocked**: Lua script can call `os.exit(0)` but GUI stays open
- **Workaround potential**: Virtual display (xvfb on Linux, headless macOS session?)

**Verdict:**
**Partially viable** - Lua API is excellent, but GUI dependency limits automation

### Alternative Emulators

**Mesen (original C++):**
- [x] Status: Archived (0.9.9, development stopped 2020)
- [x] Recommendation: Use Mesen2 instead (but Mesen2 is GUI-only)
- ❌ **Not viable**: Outdated, superseded by Mesen2

**Mesen2:**
- [x] Already installed (`/Applications/Mesen.app`)
- [x] Status: Current, cycle-accurate, excellent debugger
- ❌ **GUI-only**: No CLI, no scripting, manual validation only
- ✅ **Keep for manual validation**: Best debugger for visual inspection

**Nestopia UE:**
- [x] Homebrew available (`brew install nestopia-ue`)
- [x] README checked: No mention of CLI/scripting/automation
- ❌ **Likely GUI-only**: No evidence of automation support

**ANESE:**
- [ ] Not investigated (minimal educational emulator, likely overkill to fork)

**Verdict:**
No emulator found with true headless + scripting support on macOS

### JavaScript/Node.js Emulators

**jsnes** (https://github.com/bfirsh/jsnes):
- [x] Runs in Node.js (no browser needed!)
- [x] README + source cached (`.webcache/jsnes-*.txt`)
- ✅ **Direct API access**:
  - `nes.cpu.mem[addr]` - direct memory read (64KB array)
  - `nes.cpu.REG_PC`, `REG_ACC`, `REG_X`, `REG_Y` - CPU registers
  - `nes.ppu` - PPU object
  - `nes.frame()` - step one frame
  - Returns cycle count per instruction
- ✅ **True headless**: Node.js CLI, no GUI
- ✅ **npm package**: `npm install jsnes`
- ⚠️ **Accuracy unknown**: Not cycle-accurate like FCEUX/Mesen
- ⚠️ **No built-in cycle counter**: Would need to track cycles manually

**node-nes** (https://github.com/Glavin001/node-nes):
- [x] Node.js port of jsnes (likely redundant)
- ❓ Last updated unknown (jsnes already supports Node.js)
- **Verdict**: Use jsnes directly instead

**Verdict:**
**jsnes is VERY promising** - true headless, direct API, Node.js native

### wasm-nes (Rust → WASM)

**@kabukki/wasm-nes** (https://github.com/kabukki/wasm-nes):
- [x] Rust-based NES emulator compiled to WASM
- [x] README + source cached (`.webcache/wasm-nes-*`)
- ✅ **npm package**: `@kabukki/wasm-nes`
- ✅ **Node.js compatible**: WASM runs in Node
- ✅ **Memory read API**: `emulator.read(address)` exposed via wasm-bindgen
- ✅ **Public API**:
  - `new(rom: Vec<u8>, sample_rate: f64)` - load ROM
  - `cycle_until_frame()` - run one frame
  - `read(address: u16)` - read CPU memory
  - `update_controller()` - input
  - `get_framebuffer()` - video output
  - `get_audio()` - audio output
- ⚠️ **Accuracy**: 38% test ROM pass rate (70% CPU, 24% PPU, 17% APU)
  - Known limitations: "Precise PPU timing", "Some sprites not displayed correctly"
  - Open bus behavior missing
- ⚠️ **Less mature**: Lower accuracy than FCEUX/Mesen
- ✅ **Well-documented**: Test ROM results published, clear accuracy metrics

**Comparison to jsnes:**
- wasm-nes: Rust, documented 38% accuracy, memory read API
- jsnes: JavaScript, unknown accuracy, direct object access

**Verdict:**
**Interesting alternative** - Rust may be more accurate than JS, but 38% is lower than desired. API is clean (`read(address)`).

### Rust/WASM Options

**Minimal wrapper approaches:**
1. **Node.js wrapper around jsnes** (easiest):
   - Write `nes-headless.js` CLI tool
   - Loads ROM, runs N frames, dumps memory/registers as JSON
   - Call from Perl: `my $state = decode_json(\`node nes-headless.js rom.nes --frames=1\`)`
   - Effort: ~1 hour

2. **Rust NES emulator → WASM → Node.js**:
   - Find Rust NES emulator (nes-emulator, tetanes, etc.)
   - Compile to WASM
   - Call from Node.js
   - Effort: ~3-5 hours (if emulator has good API)

3. **Rust CLI wrapper**:
   - Find Rust NES emulator with headless support
   - Build minimal CLI (`nes-test --rom foo.nes --dump-memory`)
   - Call from Perl
   - Effort: ~2-4 hours (depends on emulator API)

**Rust NES emulators discovered:**

**TetaNES** (https://github.com/lukexor/tetanes):
- [x] README cached (`.webcache/tetanes-readme.md`)
- ✅ **tetanes-core library**: Headless emulation core
- ✅ **CLI support**: `tetanes [OPTIONS] [PATH]` with --silent flag
- ✅ **High compatibility**: 30+ mappers, >90% licensed games
- ✅ **Cross-platform**: Linux, macOS, Windows, Web
- ✅ **Active development**: Maintained, documented
- ✅ **Cargo install**: `cargo install tetanes`
- **Verdict**: VERY promising for headless CLI usage

**Plastic** (https://github.com/Amjad50/plastic):
- [x] README cached (`.webcache/plastic-readme.md`)
- ✅ **plastic-core library**: Emulation core
- ✅ **TUI support**: Terminal UI with ratatui (text-based display!)
- ✅ **Accurate**: 6502 CPU with accurate timing, PPU "almost accurate"
- ✅ **Cargo install**: `cargo install plastic_tui`
- ⚠️ **TUI limitations**: One char per pixel (very small fonts needed)
- **Verdict**: Interesting for terminal-only validation

---

### Testing Frameworks

**nes-test** (https://github.com/cppchriscpp/nes-test):
- [x] Research complete (Jasmine + Mesen-based)
- ✅ **Automated testing**: Test runner for NES ROMs
- ✅ **Mesen integration**: Auto-downloads Mesen, controls it programmatically
- ⚠️ **Mesen dependency**: Still uses Mesen (GUI emulator)
- ⚠️ **Platform**: Windows/Linux (Mac unsupported by Mesen)
- **Verdict**: Framework is interesting but still dependent on Mesen

**Nostalgist.js** (https://nostalgist.js.org/):
- [x] Research complete (RetroArch wrapper)
- ✅ **RetroArch-based**: Emscripten builds of RetroArch cores
- ⚠️ **Heavy**: Full RetroArch for just NES testing
- ⚠️ **Web-focused**: Primarily for browser use
- **Verdict**: Overkill for our use case

---

## Revised Recommendation (Post-Research)

**Option ranking** (easiest → hardest):

1. **✅ jsnes + Node.js wrapper** (CURRENT - DONE)
   - Effort: Low (~1 hour to build wrapper) - **DONE in toy1**
   - Pros: True headless, direct API, npm ecosystem, no GUI, already working
   - Cons: Unknown accuracy, no cycle counter
   - Status: Prototype complete, accuracy validation pending

2. **🆕 TetaNES CLI** (STRONG ALTERNATIVE)
   - Effort: Low-Medium (~2-3 hours - cargo install + build wrapper)
   - Pros: Rust-based (likely accurate), >90% game compat, CLI native, --silent flag
   - Cons: Requires Rust toolchain, need to build wrapper around CLI output
   - **NEW DISCOVERY**: tetanes-core library for programmatic control
   - Use if: Want higher accuracy + native performance
   - Next: `cargo install tetanes`, test with toy0, compare to jsnes

3. **⚠️ wasm-nes + Node.js wrapper** (ALTERNATIVE)
   - Effort: Low-Medium (~2 hours - WASM init + wrapper)
   - Pros: Rust-based, clean API (`read(address)`), npm package
   - Cons: Documented 38% accuracy (low), PPU timing issues
   - Use if: jsnes <38% accurate but don't want Rust toolchain

4. **⚠️ FCEUX Lua** (FALLBACK)
   - Effort: Medium (Lua scripting, GUI overhead)
   - Pros: Mature, cycle-accurate, proven, has cycle counter
   - Cons: GUI required, slower, complex setup
   - Use if: All headless options fail accuracy tests

5. **⚠️ Plastic TUI** (NICHE)
   - Effort: Medium (cargo install + understand TUI output)
   - Pros: Terminal-based visual validation, accurate CPU timing
   - Cons: TUI rendering is gimmick (1 char per pixel), not for automation
   - Use if: Want visual + terminal-only validation

6. **❌ Fork emulator** (LAST RESORT)
   - Effort: Very High (maintenance burden)
   - Only if: All above options fail

---

## Final Recommendation (REVISED)

**Path chosen:**
- [x] **Option A: jsnes + Node.js wrapper** (toys/debug/1_jsnes_wrapper - COMPLETE)
- [ ] Option B: wasm-nes (if jsnes < 38% accuracy)
- [ ] Option C: FCEUX Lua (if WASM options insufficient)
- [ ] Option D: Custom Rust NES CLI (if need >38% accuracy)
- [ ] Option E: Fork emulator (last resort)

**Rationale:**

**Why jsnes wins:**
- ✅ **True headless**: Node.js CLI, no GUI overhead
- ✅ **Direct API**: `nes.cpu.mem[addr]`, registers directly accessible (no scripting layer)
- ✅ **Fast setup**: `npm install jsnes`, write wrapper in <1 hour
- ✅ **Easy integration**: JSON output → Perl `decode_json()` → Test::More assertions
- ✅ **No maintenance**: npm package maintained upstream

**Accuracy concerns addressed:**
- ⚠️ jsnes may not be cycle-accurate (unverified)
- ✅ **Validation strategy**: Test with toy0, compare to Mesen2 manual validation
- ✅ **Fallback ready**: If jsnes wrong, FCEUX Lua is Plan B

**Comparison:**
- **vs wasm-nes**: jsnes simpler setup (no WASM init), but wasm-nes has documented accuracy (38%)
- **vs FCEUX Lua**: jsnes simpler (no GUI, direct API vs Lua scripting)
- **vs Rust CLI**: jsnes faster to prototype (npm vs find+build Rust emulator)
- **vs Fork**: jsnes has zero maintenance burden

**Next steps:**
1. ✅ `toys/debug/1_jsnes_wrapper` - Build Node.js CLI wrapper (COMPLETE)
2. ✅ Load toy0 ROM, run 1 frame, dump memory/registers as JSON (COMPLETE)
3. ✅ Write Perl test that validates output structure (COMPLETE - 16 tests passing)
4. ⏭️ **NEXT**: Validate jsnes accuracy vs Mesen2 manual inspection
5. **Decision point**:
   - If jsnes ≥38% accurate: Use jsnes, skip wasm-nes
   - If jsnes <38% accurate: Build wasm-nes wrapper (toys/debug/2_wasm_nes)
   - If both <60% accurate: Fallback to FCEUX Lua (toys/debug/3_fceux_lua)
6. If accurate enough: Build `tools/nes-test.js` + `tools/nes-test.pl` production wrappers
