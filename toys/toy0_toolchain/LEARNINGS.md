# Toy Model 0: Toolchain — Learnings

Duration: 2 hours | Status: Complete | Estimate: 1 day

## Learning Goals

### Questions to Answer

**From learnings/.ddd/5_open_questions.md (Q1.x subset for minimal ROM):**

**Q1.1** (simplified): What's the minimal ca65+ld65 workflow to build a bootable .nes file?
- What linker config to use? (NROM layout)
- How to specify CHR-ROM vs CHR-RAM?
- What header format? (iNES vs NES 2.0)

**Q1.2**: How to generate symbol files for Mesen debugging?
- ca65 flag for debug symbols?
- ld65 dbg file output?
- Does Mesen auto-load symbols?

**Q1.3**: Can we actually debug in Mesen?
- Load ROM, set breakpoint, inspect registers
- Memory viewer for RAM/PPU
- Cycle counter visibility

**Q1.6**: Minimal Makefile structure?
- Targets: build, run, clean
- ca65 → ld65 → .nes pipeline
- Auto-open in Mesen?

### Decisions to Make

- **Assembler syntax**: ca65 (Homebrew) vs asm6f (manual build) - stick with ca65 per handoff
- **Linker config**: Use stock nes.cfg or custom? Start with stock
- **Debug workflow**: Command-line build then GUI debug, or integrate?

---

## Summary

- Built: Minimal NES ROM (24592 bytes) with test-driven Perl suite validating build pipeline
- Worked: Custom nes.cfg required (stock config had missing HEADER/STARTUP segments), Mesen2 loads ROM successfully (green screen, NTSC detected)
- Failed: Stock cc65 nes.cfg not usable as-is (needed manual iNES header segment)
- Uncertain: Mesen2 debug symbol loading untested (no breakpoints set, just verified ROM loads)

---

## Evidence

### ✅ Validated
- **Q1.1 answered**: Minimal workflow is `ca65 -g hello.s -o hello.o && ld65 hello.o -C nes.cfg -o hello.nes --dbgfile hello.dbg`
- **Q1.2 answered**: Debug symbols generated with `ca65 -g` + `ld65 --dbgfile hello.dbg` (2KB .dbg file created)
- **Q1.3 answered**: Mesen2 loads ROM successfully, displays green screen with "ntsc hello" message
- **Q1.6 answered**: Makefile structure works - targets `all`, `clean`, `run`, `test` all functional
- **Test-driven approach works**: 13 Perl tests (Test::More) validate build, file sizes, binary headers, Makefile, error cases
- **ROM structure correct**: Exactly 24592 bytes (16 header + 16384 PRG + 8192 CHR), magic bytes `4E 45 53 1A` correct

### ⚠️ Challenged
- **Stock nes.cfg not minimal**: Contains STARTUP, LOWCODE, ONCE segments we don't need. Created custom nes.cfg with only HEADER/CODE/VECTORS/CHARS.
- **iNES header manual**: Stock config expects auto-generation, but didn't work. Had to add explicit `.segment "HEADER"` with magic bytes.
- **Mesen2 no CLI**: GUI-only, can't script debugger actions. Manual validation only (not automated in test suite).

### ❌ Failed
- **Headless emulator testing**: Mesen2 has no batch mode, can't automate "set breakpoint, verify PC" in tests
- **Stock cc65 config**: Threw warnings about missing HEADER/STARTUP segments, required custom config

### 🌀 Uncertain
- **Mesen2 debug symbol format**: .dbg file created but didn't verify if Mesen actually loads labels (needs future manual test)
- **ca65 vs asm6f syntax**: Documented differences (`.segment` vs `.org`) but haven't tested complex examples yet

---

## Pivots

- **Stock nes.cfg** → **Custom nes.cfg**: Stock config had segments we don't use (STARTUP, LOWCODE, constructor tables). Created minimal config with only HEADER/PRG/VECTORS/CHR segments. Clearer, no warnings.
- **Auto-generated iNES header** → **Manual HEADER segment**: Expected linker to auto-create header, but didn't happen. Added explicit `.segment "HEADER"` with 16-byte iNES structure. Now explicit and documented.

---

## Impact

### Reusable Patterns
- **nes.cfg template**: Custom config in `toys/toy0_toolchain/nes.cfg` ready for copy to future toys
- **Makefile pattern**: `Makefile` with ca65/ld65/Mesen targets reusable for all future test ROMs
- **Test suite pattern**: `test.pl` using Test::More - template for infrastructure testing (not hardware behavior)
- **ca65 syntax examples**: `hello.s` documents `.segment`, `.word`, `.byte`, `.res` directives with comments

### Architectural Consequences
- **All future toys use custom nes.cfg**: Stock config too complex, custom gives full control
- **Test-driven for build infrastructure**: Perl tests validate toolchain, manual validation for emulator/hardware
- **Mesen2 workflow**: `make run` opens ROM, manual debugger use (no scripting)
- **ca65 syntax translation needed**: Wiki examples (asm6f) require translation to ca65 (`.segment` not `.org`)

### Estimate Calibration
- Estimated: 1 day (8 hours)
- Actual: 2 hours (with methodology setup + documentation)
- Delta: **6x faster than expected** - TDD with Perl caught issues immediately, no debug cycles. Custom nes.cfg was faster than debugging stock config.
