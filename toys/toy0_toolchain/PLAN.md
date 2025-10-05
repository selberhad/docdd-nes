# Toy Model 0: Toolchain — Plan

## Overview

**Goal:** Validate cc65 + Mesen2 toolchain by building minimal bootable ROM
**Scope:** Assembly workflow, linker config, debug symbols, Makefile automation
**Priorities:** P0: Manual build works, P1: Makefile automates it, P2: Debug symbols

## Methodology

**TDD approach:** Test-first with Perl test suite validating build outputs
**Test framework:** Test::More (Perl core module, no deps)
**Validation strategy:** Automated tests check exit codes, file existence, file sizes, binary content
**What to test:**
- ca65/ld65 exit codes (success/failure cases)
- Output file existence (hello.o, hello.nes, hello.dbg)
- ROM file size (24592 bytes exact)
- iNES header magic bytes (4E 45 53 1A)
- Makefile targets (build, clean, dependencies)
**What not to test:**
- Emulator GUI behavior (manual validation only)
- Debugger interaction (manual validation only)
- Visual output (just verify ROM loads)

---

## Step 1: Research cc65 Documentation

### Goal
Understand ca65/ld65 syntax and NROM linker config before writing any code.

### Step 1.a: Read Documentation
- Read `/opt/homebrew/Cellar/cc65/2.19/share/doc/ca65.txt` (assembler syntax, directives, segments)
- Read `/opt/homebrew/Cellar/cc65/2.19/share/doc/ld65.txt` (linker config format, memory layouts)
- Check `/opt/homebrew/Cellar/cc65/2.19/share/cc65/cfg/` for stock NES configs
- Note ca65 syntax differences from asm6f (wiki examples won't work directly)

### Step 1.b: Cache Documentation
- Copy relevant ca65 sections to `.webcache/ca65_segments.txt`
- Copy ld65 config examples to `.webcache/ld65_config.txt`
- Document key syntax differences in notes (`.segment` vs asm6f `.bank`, etc.)

### Success Criteria
- [ ] Understand `.segment` directive for CODE/VECTORS
- [ ] Know how to specify PRG/CHR ROM sizes in linker config
- [ ] Identified whether stock nes.cfg exists or need custom config

---

## Step 2: Test Suite Setup

### Goal
Create Perl test suite that will validate build outputs (test-first approach).

### Step 2.a: Write test.pl (Red Phase)
Create `test.pl` with failing tests:
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test: ca65 assembles without error
is(system("ca65 hello.s -o hello.o -g"), 0, "ca65 assembles hello.s");
ok(-f "hello.o", "hello.o created");

# Test: ld65 links without error
is(system("ld65 hello.o -C nes.cfg -o hello.nes --dbgfile hello.dbg"), 0,
   "ld65 links to hello.nes");

# Test: ROM file size
is(-s "hello.nes", 24592, "ROM is exactly 24592 bytes");

# Test: iNES header magic bytes
open my $fh, '<:raw', 'hello.nes' or die $!;
read $fh, my $header, 4;
is(unpack('H*', $header), '4e45531a', 'iNES header magic correct');
close $fh;

# Test: Debug symbols exist
ok(-f "hello.dbg", "Debug symbols file created");

done_testing();
```

### Step 2.b: Run tests (should fail)
```bash
chmod +x test.pl
perl test.pl
# Expected: All tests fail (no hello.s, no nes.cfg yet)
```

### Success Criteria
- [ ] test.pl created with Test::More
- [ ] Tests check ca65/ld65 exit codes
- [ ] Tests validate ROM size and header
- [ ] Tests fail (Red phase - no implementation yet)

---

## Step 3: Minimal Assembly Source

### Goal
Write absolute minimal hello.s that defines reset vector and infinite loop.

### Step 3.a: Write hello.s
Pattern (ca65 syntax):
```asm
.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CODE"
reset:
    SEI
    CLD
loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI
```

### Step 3.b: Write nes.cfg linker config
Minimal NROM layout (use pattern from SPEC.md or stock cc65 config)

### Step 3.c: Add comments explaining ca65 vs asm6f
Document syntax differences for future reference

### Success Criteria
- [ ] hello.s uses correct ca65 segment syntax
- [ ] VECTORS segment defines 3 words at $FFFA-$FFFF
- [ ] CODE segment has reset handler + infinite loop
- [ ] nes.cfg defines NROM memory layout
- [ ] Comments note syntax differences from wiki examples

---

## Step 4: Manual Build (ca65 + ld65)

### Goal
Assemble and link hello.s into bootable .nes file, make tests pass (Green phase).

### Step 4.a: Assemble with ca65
Command: `ca65 hello.s -o hello.o -g`
- `-g` flag for debug info
- Check for errors (undefined labels, bad directives)
- Verify hello.o created

### Step 4.b: Link with ld65
Command: `ld65 hello.o -C nes.cfg -o hello.nes --dbgfile hello.dbg`

### Step 4.c: Run tests (Green phase)
```bash
perl test.pl
# Expected: All tests pass
```

### Success Criteria
- [ ] ca65 assembles without errors
- [ ] ld65 links without errors
- [ ] **perl test.pl passes all tests**
- [ ] hello.nes is exactly 24592 bytes (verified by test)
- [ ] Header starts with `4E 45 53 1A` (verified by test)
- [ ] hello.dbg exists (verified by test)

**Commit:** `feat(toy0): Step 4 complete - manual build workflow validated, tests passing`

---

## Step 5: Mesen2 Debugging Validation

### Goal
Load ROM in Mesen2, verify debugger works, test breakpoints.

### Step 4.a: Launch in Mesen2
Command: `/Applications/Mesen.app/Contents/MacOS/Mesen hello.nes`
- Or: `open -a Mesen hello.nes`
- Verify ROM loads without error dialog
- Check emulator window shows (likely black screen, that's expected)

### Step 4.b: Test Debugger
- Open debugger (menu or hotkey, check Mesen docs)
- Verify disassembly shows code
- Check PC (program counter) points to reset handler address
- Memory viewer: check $8000-$BFFF shows PRG-ROM code

### Step 4.c: Test Breakpoint
- Set breakpoint at `reset` label (if symbols loaded) or address
- Reset emulator
- Verify execution breaks at expected location
- Step through instructions (SEI, CLD, JMP)

### Success Criteria
- [ ] ROM loads in Mesen2 without errors
- [ ] Debugger shows disassembly
- [ ] PC points to reset handler on boot
- [ ] Breakpoint at reset works
- [ ] Can step through instructions
- [ ] Memory viewer shows code at $8000+

**Commit:** `feat(toy0): Step 5 complete - Mesen2 debugging validated`

---

## Step 6: Makefile Automation

### Goal
Automate build workflow with Makefile targets: all, clean, run, test.

### Step 6.a: Add Makefile tests to test.pl (Red phase)
Add to test.pl:
```perl
# Test: Makefile builds correctly
system("make clean") == 0 or die "make clean failed";
is(system("make"), 0, "Makefile builds successfully");
ok(-f "hello.nes", "make produces hello.nes");

# Test: make clean removes artifacts
system("make") == 0 or die "make failed";
system("make clean") == 0 or die "make clean failed";
ok(!-f "hello.nes", "make clean removes hello.nes");
ok(!-f "hello.o", "make clean removes hello.o");
```

Run `perl test.pl` → should fail (no Makefile yet)

### Step 6.b: Create Makefile
Pattern:
```makefile
# Paths (macOS Homebrew cc65)
CA65 = /opt/homebrew/bin/ca65
LD65 = /opt/homebrew/bin/ld65
MESEN = /Applications/Mesen.app/Contents/MacOS/Mesen

# Targets
all: hello.nes

hello.o: hello.s
	$(CA65) $< -o $@ -g

hello.nes: hello.o nes.cfg
	$(LD65) $< -C nes.cfg -o $@ --dbgfile hello.dbg

clean:
	rm -f *.o *.nes *.dbg *.lst

run: hello.nes
	$(MESEN) $<

test: hello.nes
	perl test.pl

.PHONY: all clean run test
```

### Step 6.c: Run tests (Green phase)
```bash
perl test.pl
# OR
make test
# Expected: All tests pass including Makefile tests
```

### Success Criteria
- [ ] **perl test.pl passes all tests** (including Makefile validation)
- [ ] `make` builds hello.nes from source
- [ ] `make clean` removes build artifacts (verified by test)
- [ ] `make run` opens ROM in Mesen2
- [ ] `make test` runs test suite
- [ ] Makefile tracks dependencies (rebuilds on .s or .cfg change)
- [ ] Documented Homebrew path assumptions in comments

**Commit:** `feat(toy0): Step 6 complete - Makefile automation working, tests passing`

---

## Step 7: Error Cases (Red-Green-Refactor)

### Goal
Test error handling (invalid assembly, missing config) to ensure build fails cleanly.

### Step 7.a: Write error tests (Red phase)
Add to test.pl:
```perl
# Test: Invalid assembly syntax fails
system("cp hello.s hello.s.bak");
system("echo 'INVALID_INSTRUCTION' >> hello.s");
isnt(system("ca65 hello.s -o hello_bad.o 2>/dev/null"), 0,
     "ca65 fails on invalid syntax");
system("mv hello.s.bak hello.s");

# Test: Missing linker config fails
isnt(system("ld65 hello.o -o hello_bad.nes 2>/dev/null"), 0,
     "ld65 fails without config");
```

### Step 7.b: Verify tests pass (Green phase)
Run `perl test.pl` → error tests should pass (confirming errors are handled)

### Step 7.c: Document error behavior
Add comments to LEARNINGS.md about error message quality

### Success Criteria
- [ ] Tests verify ca65 fails on bad syntax
- [ ] Tests verify ld65 fails without config
- [ ] Error messages are readable (manual verification)
- [ ] **All tests pass including error cases**

**Commit:** `test(toy0): Step 7 complete - error case validation`

---

## Step 8: Documentation & Learnings

### Goal
Capture exact workflow in LEARNINGS.md for future toys.

### Step 6.a: Update LEARNINGS.md Findings
- Document exact ca65/ld65 commands that worked
- Note ca65 syntax differences from asm6f (segment directives, etc.)
- Record any macOS-specific paths or Homebrew quirks
- Answer all Q1.1, Q1.2, Q1.3, Q1.6 questions from learning goals

### Step 6.b: Update README.md
- Finalize 100-200 word orientation
- Document key files (hello.s, nes.cfg, Makefile)
- Note gotchas (ca65 syntax, Homebrew paths)

### Success Criteria
- [ ] LEARNINGS.md answers all learning goal questions
- [ ] Exact build command sequence documented
- [ ] ca65 syntax differences noted with examples
- [ ] README.md provides 10-second context refresh

**Commit:** `docs(toy0): Step 8 complete - learnings and README finalized`

---

## Risks

- **ca65 syntax differs from wiki**: Most tutorials use asm6f → Mitigation: Read ca65 docs first, translate in comments
- **Linker config complexity**: ld65 configs can be cryptic → Mitigation: Start with stock or minimal custom config
- **CHR-ROM handling unclear**: May need manual concat → Mitigation: Test linker config approach first
- **Mesen2 symbol format**: May not support ca65 dbg files → Mitigation: Use raw addresses if symbols don't load

## Dependencies

**Verified installed:**
- cc65 2.19 (Homebrew ARM64)
- Mesen2 (/Applications/Mesen.app)
- SDL2 (Homebrew)

**Knowledge dependencies:**
- `learnings/wiki_architecture.md` - NES memory map, vectors ($FFFA-$FFFF)
- `learnings/getting_started.md` - Init sequence (SEI, CLD)
- `learnings/mappers.md` - NROM layout (16KB PRG @ $8000-$BFFF, 8KB CHR)
