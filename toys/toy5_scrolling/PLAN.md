# PLAN — Scrolling

## Overview

**Goal**: Validate PPUSCROLL register updates in NMI handler through TDD workflow (RAM-based validation, Phase 1).

**Scope**:
- NMI handler with auto-scroll (scroll_x increments each frame)
- PPUSCROLL writes ($2005) every frame during vblank
- Integration of toy4 (NMI handler) pattern with scroll updates
- Automated tests via t/*.t play-specs

**Priorities**:
1. PPUSCROLL register writes work (observable via RAM)
2. Auto-scroll increments correctly (scroll_x += 1 per frame)
3. Wraparound at 256 works (0xFF → 0x00)
4. Tests pass (validates jsnes PPUSCROLL emulation)

## Methodology

**TDD Workflow**:
- Write tests FIRST (t/*.t files define expected behavior)
- Implement assembly code (scroll.s)
- Run tests: Red (failing) → Green (passing)
- Commit after each step
- Document findings in LEARNINGS.md

**What to test**:
- ✅ scroll_x increments every frame
- ✅ Wraparound at 256 (0xFF → 0x00)
- ✅ Integration with toy4 NMI pattern
- ✅ PPUSCROLL latch reset ($2002 read)

**What NOT to test** (Phase 1):
- ❌ Visual scrolling output (no frame buffer access)
- ❌ Nametable VRAM writes (deferred to Phase 2)
- ❌ Vertical scrolling (horizontal-only sufficient)
- ❌ Cycle counting (needs profiling tools - Phase 2)

---

## Step 1: Scaffold ROM Build

### Goal
Set up build infrastructure using `new-rom.pl` to create Makefile, nes.cfg, assembly skeleton, and test templates.

### Tasks
1. Run `perl ../../tools/new-rom.pl scroll` from toy5_scrolling directory
2. Verify files created: Makefile, nes.cfg, scroll.s, play-spec.pl
3. Create test directory: `mkdir t`
4. Test build: `make` produces scroll.nes
5. Test clean: `make clean` removes build artifacts

### Success Criteria
- [ ] Makefile exists and builds ROM
- [ ] nes.cfg configures NROM mapper correctly
- [ ] scroll.s skeleton created
- [ ] play-spec.pl template ready
- [ ] `make && make clean` works without errors

---

## Step 2: Write Test Scenarios

### Goal
Define expected behavior via t/*.t play-specs BEFORE implementing assembly code (TDD: Red first).

### Step 2.a: Write Failing Tests

**Test outline** (from SPEC.md test scenarios):

1. **t/01-horizontal-scroll.t**: scroll_x increments
   - Frame 4 → scroll_x = 0, scroll_y = 0
   - Frame 5 → scroll_x = 1
   - Frame 14 → scroll_x = 10 (0x0A)
   - Frame 68 → scroll_x = 64 (0x40)
   - Frame 132 → scroll_x = 128 (0x80)

2. **t/02-wraparound.t**: Overflow behavior
   - Frame 258 → scroll_x = 254 (0xFE)
   - Frame 259 → scroll_x = 255 (0xFF)
   - Frame 260 → scroll_x = 0 (wraparound)
   - Frame 261 → scroll_x = 1
   - Frame 264 → scroll_x = 4

3. **t/03-integration.t**: NMI integration
   - Frame 4 → scroll_x = 0 (first NMI - toy4 offset)
   - Frame 10 → scroll_x = 6
   - Frame 20 → scroll_x = 16 (0x10)

**Expected**: All tests FAIL (ROM not implemented yet - RED phase)

### Step 2.b: Implement Tests

**Tasks**:
1. Create `t/01-horizontal-scroll.t` with 5 assertions
2. Create `t/02-wraparound.t` with 5 assertions
3. Create `t/03-integration.t` with 3 assertions
4. Use NES::Test DSL (`load_rom`, `at_frame`, `assert_ram`)
5. Run `prove t/*.t` → expect ALL FAILURES (Red)

**Pattern** (illustrative, not literal):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../debug/1_jsnes_wrapper";
use NES::Test;

load_rom "$FindBin::Bin/scroll.nes";

at_frame 4 => sub {
    assert_ram 0x10 => 0x00;  # scroll_x
    assert_ram 0x11 => 0x00;  # scroll_y
};

at_frame 5 => sub {
    assert_ram 0x10 => 0x01;  # scroll_x incremented
};

run_test;
```

### Success Criteria
- [ ] 3 test files created (t/01, t/02, t/03)
- [ ] 13 total assertions defined (5 + 5 + 3)
- [ ] `prove t/*.t` runs (all RED - expected failures)
- [ ] Tests follow NES::Test DSL pattern

---

## Step 3: Implement Minimal NMI Handler

### Goal
Implement NMI handler with PPUSCROLL updates to pass tests (TDD: Green phase).

### Step 3.a: Initialize RAM Variables

**Tasks**:
1. Update `scroll.s` reset handler
2. Initialize scroll_x at $10 (LDA #$00, STA $10)
3. Initialize scroll_y at $11 (LDA #$00, STA $11)
4. Add 2-vblank PPU warmup (from toy2 pattern)
5. Enable NMI (LDA #%10000000, STA $2000)

**Pattern**:
```asm
reset:
    SEI              ; Disable IRQ
    CLD              ; Clear decimal mode
    LDX #$FF
    TXS              ; Set up stack

    ; Clear scroll variables
    LDA #$00
    STA $10          ; scroll_x = 0
    STA $11          ; scroll_y = 0

    ; PPU warmup (2 vblanks)
    BIT $2002
:
    BIT $2002
    BPL :-
:
    BIT $2002
    BPL :-

    ; Enable NMI
    LDA #%10000000
    STA $2000

    ; Main loop (Pattern 2: NMI only)
loop:
    JMP loop
```

### Step 3.b: Implement NMI Handler

**Tasks**:
1. Create nmi_handler label
2. Increment scroll_x (INC $10)
3. Reset PPU latch (BIT $2002)
4. Write PPUSCROLL X (LDA $10, STA $2005)
5. Write PPUSCROLL Y (LDA $11, STA $2005)
6. RTI

**Pattern**:
```asm
nmi_handler:
    ; Increment scroll position (auto-scroll)
    INC $10          ; scroll_x += 1

    ; Reset PPU latch
    BIT $2002

    ; Write PPUSCROLL (X, then Y)
    LDA $10          ; scroll_x
    STA $2005        ; PPUSCROLL X
    LDA $11          ; scroll_y (always 0)
    STA $2005        ; PPUSCROLL Y

    RTI
```

### Step 3.c: Set NMI Vector

**Tasks**:
1. Update `.segment "VECTORS"` section
2. Set NMI vector to nmi_handler address
3. Verify vector at $FFFA-$FFFB

**Pattern**:
```asm
.segment "VECTORS"
    .word nmi_handler    ; NMI vector
    .word reset          ; Reset vector
    .word 0              ; IRQ vector
```

### Success Criteria
- [ ] scroll.s compiles without errors
- [ ] scroll.nes builds successfully
- [ ] NMI handler increments scroll_x
- [ ] PPUSCROLL writes happen every frame
- [ ] `prove t/*.t` shows GREEN (all tests pass)

---

## Step 4: Verify and Document

### Goal
Confirm all tests pass and document findings in LEARNINGS.md.

### Step 4.a: Run Full Test Suite

**Tasks**:
1. Run `make clean && make` (clean build)
2. Run `prove t/*.t` (all scenarios)
3. Verify 13/13 assertions pass
4. Check for any warnings or errors

### Step 4.b: Update LEARNINGS.md

**Tasks**:
1. Fill "Findings" section with validated/challenged/failed/uncertain
2. Document patterns for production
3. Answer questions from "Questions to Answer Through Practice"
4. Update duration and status header

**Key findings to document**:
- ✅ Does PPUSCROLL work in jsnes?
- ✅ Does auto-scroll increment correctly?
- ✅ Does wraparound work (0xFF → 0x00)?
- ✅ Does integration with toy4 NMI work?
- ⏭️ What deferred to Phase 2? (visual validation, VRAM writes)

### Success Criteria
- [ ] All 13 assertions pass (3 test files)
- [ ] LEARNINGS.md updated with findings
- [ ] Patterns for production documented
- [ ] Duration/status header updated

---

## Step 5: Commit and Update Status

### Goal
Commit work and update project status tracking.

### Tasks
1. Commit with message: `feat(toy5): Complete scrolling - PPUSCROLL validation (13/13 tests passing)`
2. Update `toys/STATUS.md` with toy5 results
3. Update `ORIENTATION.md` if needed (or let STATUS.md handle it)

### Success Criteria
- [ ] Clean git commit created
- [ ] Commit message follows convention
- [ ] STATUS.md updated
- [ ] Work ready for next toy

---

## Risks

**Risk 1: jsnes PPUSCROLL emulation incomplete**
- **Likelihood**: Low (jsnes is well-tested)
- **Mitigation**: If $2005 writes don't work, document limitation and defer to Phase 2 emulator
- **Impact**: Would invalidate scrolling tests, require alternative validation

**Risk 2: Latch reset behavior unclear**
- **Likelihood**: Medium (PPU latch timing is subtle)
- **Mitigation**: Follow exact pattern from learnings (BIT $2002 before writes)
- **Impact**: Tests may fail if latch not reset correctly

**Risk 3: Frame offset different from toy4**
- **Likelihood**: Low (toy4 established 4-frame offset pattern)
- **Mitigation**: Start tests at frame 4 (toy4 finding)
- **Impact**: Off-by-N frame errors if offset changes

**Risk 4: Can't validate without visual output**
- **Likelihood**: High (Phase 1 limitation - expected)
- **Mitigation**: RAM inspection proves PPUSCROLL writes happen
- **Impact**: Defer visual validation to Phase 2, accept RAM-only validation

---

## Dependencies

**From previous toys**:
- **toy4**: NMI handler pattern (Pattern 2: NMI only, 4-frame init offset)
- **toy2**: PPU warmup pattern (2 vblank waits)
- **debug/1_jsnes_wrapper**: NES::Test DSL, jsnes harness

**Learning docs**:
- **learnings/graphics_techniques.md**: Scrolling theory, PPUSCROLL timing
- **learnings/wiki_architecture.md**: PPU register details, nametable layout
- **learnings/timing_and_interrupts.md**: Vblank timing, NMI handler patterns

**Tools**:
- **tools/new-rom.pl**: ROM scaffolding
- **Makefile**: Build system (ca65/ld65)
- **prove**: Test runner (Perl Test::Harness)

**External**:
- **jsnes**: Headless emulator for automated testing
- **cc65**: Assembler (ca65) and linker (ld65)
