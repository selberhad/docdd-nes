# PLAN — NMI Handler

## Overview

**Goal**: Validate NMI handler execution and frame synchronization in jsnes through TDD workflow.

**Scope**:
- NMI handler that increments frame counter
- Sprite X position updates via OAM DMA in NMI
- Integration of toy1 (OAM DMA) + toy2 (PPU init) patterns
- Automated tests via play-spec.pl

**Priorities**:
1. NMI handler executes (observable via frame counter)
2. OAM DMA works in NMI context (sprite animation)
3. Tests pass (validates jsnes NMI emulation)

## Methodology

**TDD Workflow**:
- Write tests FIRST (play-spec.pl defines expected behavior)
- Implement assembly code (nmi.s)
- Run tests: Red (failing) → Green (passing)
- Commit after each step
- Document findings in LEARNINGS.md

**What to test**:
- ✅ Frame counter increments every frame
- ✅ Sprite X position updates every frame
- ✅ Counter wraparound at 256
- ✅ OAM DMA works in NMI handler

**What NOT to test** (Phase 1):
- ❌ Cycle counting (needs profiling tools - Phase 2)
- ❌ PPUCTRL register details (trust jsnes emulation)
- ❌ Visual sprite rendering (headless testing only)

---

## Step 1: Scaffold ROM Build

### Goal
Set up build infrastructure using `new-rom.pl` to create Makefile, nes.cfg, assembly skeleton, and test template.

### Tasks
1. Run `../../tools/new-rom.pl nmi` from toy4_nmi directory
2. Verify files created: Makefile, nes.cfg, nmi.s, play-spec.pl
3. Test build: `make` produces nmi.nes
4. Test clean: `make clean` removes build artifacts

### Success Criteria
- [ ] Makefile exists and builds ROM
- [ ] nes.cfg configures NROM mapper correctly
- [ ] nmi.s skeleton created
- [ ] play-spec.pl template ready for tests
- [ ] `make && make clean` works without errors

---

## Step 2: Write Test Scenarios

### Goal
Define expected behavior via play-spec.pl BEFORE implementing assembly code (TDD: Red first).

### Step 2.a: Write Failing Tests

**Test outline** (from SPEC.md test scenarios):

1. **Simple test**: Frame counter increments
   - Frame 1 → counter = 0x01
   - Frame 2 → counter = 0x02
   - Frame 10 → counter = 0x0A

2. **Complex test**: Sprite animation
   - Frame 1 → sprite_x = 0x01, OAM[3] = 0x01
   - Frame 10 → sprite_x = 0x0A, OAM[3] = 0x0A
   - Frame 60 → sprite_x = 0x3C, OAM[3] = 0x3C

3. **Wraparound test**: Counter overflow
   - Frame 255 → counter = 0xFF
   - Frame 256 → counter = 0x00 (wrapped)
   - Frame 257 → counter = 0x01

4. **Integration test**: OAM DMA + PPU init
   - Frame 1 → both counter and sprite updated
   - Frame 10 → both incremented together

**Expected**: All tests FAIL (ROM not implemented yet - RED phase)

### Step 2.b: Implement Tests

**Tasks**:
1. Write `play-spec.pl` with 4 test scenarios
2. Use NES::Test DSL (`load_rom`, `at_frame`, `assert_ram`)
3. Run `perl play-spec.pl` → expect ALL FAILURES (Red)

**Pattern** (illustrative only, not literal code):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use lib '../../lib';
use NES::Test;

load_rom 'nmi.nes';

# Test 1: Frame counter
at_frame 1 => sub { assert_ram 0x0010 => 0x01; };
at_frame 10 => sub { assert_ram 0x0010 => 0x0A; };

# Test 2: Sprite animation
at_frame 1 => sub { assert_ram 0x0203 => 0x01; };
at_frame 10 => sub { assert_ram 0x0203 => 0x0A; };

# Test 3: Wraparound (use set_frame to fast-forward)
# Test 4: Integration
```

### Success Criteria
- [ ] play-spec.pl contains 4 test scenarios
- [ ] Tests use NES::Test DSL correctly
- [ ] `perl play-spec.pl` runs (expect failures - Red phase)
- [ ] All tests documented with comments

---

## Step 3: Implement Assembly Code

### Goal
Implement nmi.s with NMI handler + initialization code to make tests pass (TDD: Green phase).

### Step 3.a: CPU Initialization

**Pattern** (from toy2 PPU init):
```asm
.segment "HEADER"
  ; iNES header (16 bytes)
  .byte "NES", $1A
  .byte $01        ; 1x 16KB PRG-ROM
  .byte $01        ; 1x 8KB CHR-ROM
  .byte $00, $00   ; Mapper 0 (NROM)
  .res 8, $00      ; Padding

.segment "CODE"
reset:
  SEI              ; Disable IRQ
  CLD              ; Clear decimal mode
  LDX #$FF
  TXS              ; Set up stack

  ; Clear frame counter and sprite_x
  LDA #$00
  STA $0010
  STA $0011

  ; (Continue in Step 3.b)
```

**Tasks**:
1. Create iNES header (NROM mapper)
2. Implement CPU init (SEI, CLD, stack setup)
3. Clear RAM ($0010, $0011)

### Step 3.b: PPU Warmup

**Pattern** (from toy2):
```asm
  ; Wait for PPU warmup (2 vblanks)
  BIT $2002
vblank1:
  BIT $2002
  BPL vblank1

vblank2:
  BIT $2002
  BPL vblank2

  ; (Continue in Step 3.c)
```

**Tasks**:
1. Implement 2-vblank warmup pattern
2. Clear vblank flag before waiting

### Step 3.c: OAM Setup

**Pattern** (from toy1):
```asm
  ; Set up OAM sprite
  LDA #$78         ; Y = 120
  STA $0200
  LDA #$00         ; Tile = 0
  STA $0201
  LDA #$00         ; Attributes = 0
  STA $0202
  LDA #$00         ; X = 0 (will be updated by NMI)
  STA $0203

  ; (Continue in Step 3.d)
```

**Tasks**:
1. Initialize OAM buffer ($0200-$0203)
2. Set sprite position, tile, attributes

### Step 3.d: Enable NMI

**Pattern** (from learnings/timing_and_interrupts.md):
```asm
  ; Enable NMI
  LDA #%10000000   ; NMI enable (bit 7)
  STA $2000

  ; Main loop (idle - all work in NMI)
main_loop:
  JMP main_loop
```

**Tasks**:
1. Enable NMI via $2000 bit 7
2. Infinite main loop (NMI does all work)

### Step 3.e: NMI Handler

**Pattern** (from SPEC.md):
```asm
nmi_handler:
  ; Increment frame counter
  INC $0010

  ; Update sprite X position
  INC $0011
  LDA $0011
  STA $0203        ; OAM byte 3 (X position)

  ; Upload OAM via DMA
  LDA #$02
  STA $4014

  RTI
```

**Tasks**:
1. Implement NMI handler
2. Increment frame counter ($0010)
3. Increment sprite_x ($0011)
4. Update OAM buffer ($0203)
5. Trigger OAM DMA ($4014)
6. RTI (return from interrupt)

### Step 3.f: Vectors

**Pattern**:
```asm
.segment "VECTORS"
  .addr nmi_handler, reset, 0   ; NMI, RESET, IRQ
```

**Tasks**:
1. Set NMI vector to nmi_handler
2. Set RESET vector to reset
3. IRQ unused (set to 0)

### Success Criteria
- [ ] nmi.s assembles without errors
- [ ] ROM builds (24592 bytes)
- [ ] CPU init complete
- [ ] PPU warmup implemented
- [ ] OAM setup complete
- [ ] NMI enabled
- [ ] NMI handler implemented
- [ ] Vectors set correctly

---

## Step 4: Run Tests (Red → Green)

### Goal
Execute play-spec.pl and verify all tests pass (TDD: Green phase).

### Tasks
1. Build ROM: `make`
2. Run tests: `perl play-spec.pl`
3. If failures: Debug assembly code
4. If passes: Celebrate!

### Expected Results

**Initial run** (after Step 2): ALL FAILURES (Red)
**After implementation** (after Step 3): ALL PASS (Green)

### Debugging Strategy (if failures)

**If frame counter doesn't increment:**
- Check NMI enable ($2000 bit 7 set?)
- Check NMI vector points to nmi_handler
- Check INC $0010 in NMI handler

**If sprite doesn't update:**
- Check OAM DMA ($4014 written?)
- Check OAM buffer ($0203 updated?)
- Check sprite_x incremented before OAM write

**If tests hang:**
- Check main loop doesn't exit (infinite JMP)
- Check NMI handler has RTI
- Check PPU warmup completes

### Success Criteria
- [ ] `make` succeeds (ROM builds)
- [ ] `perl play-spec.pl` runs
- [ ] Test 1 passes (frame counter increments)
- [ ] Test 2 passes (sprite animation)
- [ ] Test 3 passes (wraparound)
- [ ] Test 4 passes (integration)
- [ ] **ALL tests pass** (0 failures)

---

## Step 5: Document Findings

### Goal
Update LEARNINGS.md with actual results from testing (validate theory vs practice).

### Tasks

1. **Update Findings section**:
   - ✅ Validated: What worked (NMI fired, OAM DMA worked, tests passed)
   - ⚠️ Challenged: Any difficulties (debugging, unexpected behavior)
   - ❌ Failed: Any dead ends (if applicable)
   - 🌀 Uncertain: Open questions for Phase 2

2. **Extract patterns**:
   - Working NMI handler code
   - Frame synchronization pattern
   - OAM DMA in NMI pattern
   - Key lessons learned

3. **Answer questions**:
   - Mark questions from LEARNINGS.md as answered
   - Document jsnes NMI emulation accuracy
   - Note any deviations from theory

4. **Update duration**:
   - Record actual time spent
   - Compare to estimate (1-2 hours)

### Success Criteria
- [ ] LEARNINGS.md Findings section complete
- [ ] Patterns for Production documented
- [ ] Questions answered
- [ ] Duration recorded
- [ ] Status updated to "Complete"

---

## Risks

**Risk 1: jsnes NMI emulation bugs**
- **Mitigation**: Test in Mesen2 if jsnes behaves unexpectedly
- **Likelihood**: Low (jsnes well-tested)

**Risk 2: OAM DMA timing issues**
- **Mitigation**: Reuse toy1 exact pattern (known working)
- **Likelihood**: Low (jsnes handles OAM DMA correctly)

**Risk 3: Test harness limitations**
- **Mitigation**: Add DEBUG=1 output, check frame timing
- **Likelihood**: Medium (new NMI timing features)

**Risk 4: Counter overflow edge cases**
- **Mitigation**: Test wraparound explicitly (scenario 3)
- **Likelihood**: Low (INC wraps automatically)

---

## Dependencies

**Prerequisites**:
- ✅ toy1_sprite_dma complete (OAM DMA pattern validated)
- ✅ toy2_ppu_init complete (PPU warmup pattern validated)
- ✅ NES::Test Phase 1 working (jsnes harness functional)
- ✅ tools/new-rom.pl available (scaffolding script)

**External dependencies**:
- ca65/ld65 (assembler/linker)
- jsnes (emulator via NES::Test)
- Perl Test::More (test framework)

**Knowledge dependencies**:
- learnings/timing_and_interrupts.md (NMI theory)
- learnings/sprite_techniques.md (OAM DMA theory)
- learnings/getting_started.md (PPU warmup theory)

---

## Commit Plan

**After each numbered step**:
1. `feat(toy4): complete Step 1 - scaffold ROM build`
2. `test(toy4): complete Step 2 - write test scenarios (Red)`
3. `feat(toy4): complete Step 3 - implement assembly code (Green)`
4. `test(toy4): complete Step 4 - all tests pass`
5. `docs(toy4): complete Step 5 - document findings in LEARNINGS.md`

**Final commit**:
- `feat(toy4): toy4_nmi complete - NMI handler validated`

**Update ORIENTATION.md** after completion:
- `docs(ORIENTATION): toy4_nmi complete - update progress`

---

## Notes

**Why "NMI Only" pattern?**
- Simplest to test (no flag synchronization)
- All work in NMI handler (easy to observe)
- Can test "Main only" pattern in future toy if needed

**Why increment sprite_x every frame?**
- Observable sprite animation (moves across screen)
- Validates OAM DMA works in NMI context
- Integrates toy1 pattern (OAM DMA)

**Why separate frame counter from sprite_x?**
- Tests two independent counters
- Validates NMI handler can update multiple RAM locations
- More robust test (if one breaks, other might still work)

**Estimated time**: 1-2 hours (based on toy1/toy2 actuals: 30-45 min each)
