# PLAN — Controller

## Strategy

**Test-First Development:**
1. Write play-spec.pl assertions (Red)
2. Write minimal assembly to pass (Green)
3. Commit working increment
4. Repeat until all assertions pass

**Incremental steps:**
- Build infrastructure first (reuse from toy2)
- Test ROM loads and inits properly
- Add controller read subroutine incrementally
- Test individual buttons first, then combinations

---

## Steps

### 1. [x] Scaffold toy directory
- `tools/new-toy.pl controller` → toys/toy3_controller/
- Files created: SPEC.md, PLAN.md, README.md, LEARNINGS.md
- **Status**: ✅ Complete

### 2. [ ] Copy build infrastructure from toy2

**Copy files:**
```bash
cp toys/toy2_ppu_init/nes.cfg toys/toy3_controller/
cp toys/toy2_ppu_init/Makefile toys/toy3_controller/
```

**Modify Makefile:**
- Change ROM name: `ppu_init.nes` → `controller.nes`
- Change source: `ppu_init.s` → `controller.s`
- Keep test target (will update play-spec.pl)

**Test:**
```bash
cd toys/toy3_controller
make clean
# Should succeed (no source yet, expected failure)
```

**Commit:** `chore(toy3): Copy build infrastructure from toy2`

### 3. [ ] Write failing play-spec.pl (Red)

**Create play-spec.pl:**
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use NES::Test;

load_rom "$Bin/controller.nes";

# Test A button
press_button 'A';
at_frame 1 => sub {
    assert_ram 0x0010 => 0x80;  # A = bit 7
};

# Test B button
press_button 'B';
at_frame 2 => sub {
    assert_ram 0x0010 => 0x40;  # B = bit 6
};

# Test Start button
press_button 'Start';
at_frame 3 => sub {
    assert_ram 0x0010 => 0x10;  # Start = bit 4
};

# Test Up button
press_button 'Up';
at_frame 4 => sub {
    assert_ram 0x0010 => 0x08;  # Up = bit 3
};

# Test A+B combination
press_button 'A+B';
at_frame 5 => sub {
    assert_ram 0x0010 => 0xC0;  # A+B = bits 7+6
};

# Test Up+A combination
press_button 'Up+A';
at_frame 6 => sub {
    assert_ram 0x0010 => 0x88;  # Up+A = bits 3+7
};

# Test no buttons (should be 0)
at_frame 7 => sub {
    assert_ram 0x0010 => 0x00;  # No buttons
};

done_testing();
```

**Test:** `perl play-spec.pl` → **fails** (no ROM yet, expected)

**Commit:** `test(toy3): Write failing play-spec for controller input`

### 4. [ ] Write minimal assembly skeleton

**Create controller.s:**
```asm
; toy3_controller - Validate controller read pattern
; Tests: 3-step strobe + read, button state byte format

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode

    ; Initialize stack
    LDX #$FF
    TXS

    ; TODO: Disable PPU
    ; TODO: Wait 2 vblanks
    ; TODO: Read controller
    ; TODO: Store button state

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CHARS"
    .res 8192, $00
```

**Test:** `make` → builds successfully, `perl play-spec.pl` → **fails** (no controller logic)

**Commit:** `feat(toy3): Add minimal ROM skeleton`

### 5. [ ] Add standard init sequence (from toy2)

**Add PPU init and vblank waits:**
```asm
reset:
    SEI
    CLD

    LDX #$FF
    TXS

    ; Disable PPU
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0
    STX $2001           ; PPUMASK = 0

    ; Initialize button state
    STX $0010           ; buttons = 0

    ; Clear vblank flag
    BIT $2002

    ; Wait first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1

    ; Wait second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; PPU ready, fall through to main loop

loop:
    ; TODO: Read controller
    JMP loop
```

**Test:** `make && perl play-spec.pl`
- ROM should build and run
- Tests still fail (no controller read)

**Commit:** `feat(toy3): Add standard init sequence from toy2`

### 6. [ ] Add controller read subroutine

**Add read_controller1 subroutine:**
```asm
loop:
    JSR read_controller1
    JMP loop

read_controller1:
    ; Step 1: Strobe controller
    LDA #$01
    STA $4016           ; Start strobe
    LDA #$00
    STA $4016           ; End strobe (latches state)

    ; Step 2: Read 8 buttons
    LDX #$08            ; 8 buttons to read
read_loop:
    LDA $4016           ; Read bit 0
    LSR                 ; Shift bit 0 to carry
    ROL $0010           ; Rotate carry into buttons
    DEX
    BNE read_loop

    RTS
```

**Test:** `make && perl play-spec.pl` → **should start passing tests!**

**If tests fail:** Debug button byte format, check frame timing

**Commit:** `feat(toy3): Add controller read subroutine - TESTS PASSING`

### 7. [ ] Test all 8 buttons individually

**Extend play-spec.pl:**
```perl
# Add tests for remaining buttons
press_button 'Select';
at_frame 8 => sub {
    assert_ram 0x0010 => 0x20;  # Select = bit 5
};

press_button 'Down';
at_frame 9 => sub {
    assert_ram 0x0010 => 0x04;  # Down = bit 2
};

press_button 'Left';
at_frame 10 => sub {
    assert_ram 0x0010 => 0x02;  # Left = bit 1
};

press_button 'Right';
at_frame 11 => sub {
    assert_ram 0x0010 => 0x01;  # Right = bit 0
};
```

**Test:** `make && perl play-spec.pl` → **all buttons should pass**

**Commit:** `test(toy3): Add tests for all 8 buttons`

### 8. [ ] Verify and document findings

**Run final validation:**
- All play-spec.pl tests pass
- ROM loads in Mesen2 (manual check)
- Button byte format verified

**Update LEARNINGS.md:**
- Move questions from "Questions to Answer" → "Findings"
- Document jsnes controller behavior (accurate? any quirks?)
- Update "Patterns for Production" with working code
- Note any deviations from theory

**Key questions to answer:**
- Does jsnes emulate $4016 correctly?
- Does NES::Test `press_button` work with manual reads?
- What frame does button state appear? (press at N, read at N+1?)
- Do all 8 buttons work as documented?
- Do combinations work correctly?

**Commit:** `docs(toy3): Update LEARNINGS.md with controller findings`

### 9. [ ] Write README.md

**Document toy for future reference:**
- What this toy validates (controller read, 3-step pattern, byte format)
- How to run tests (`make && perl play-spec.pl`)
- Key findings (jsnes accurate, button format works, etc.)
- Patterns to reuse (controller read subroutine for all future toys)

**Commit:** `docs(toy3): Write README.md summary`

---

## Risks

**jsnes controller emulation accuracy:**
- **Risk**: jsnes may not accurately emulate $4016 strobe/read
- **Mitigation**: Compare with Mesen2 manual validation (Phase 3)
- **Fallback**: Document discrepancy, note Phase 2 upgrade needed

**NES::Test press_button integration:**
- **Risk**: `press_button` may not trigger manual controller reads correctly
- **Mitigation**: Test early, verify button state appears in RAM
- **Fallback**: Debug NES::Test, check jsnes button state injection

**Frame timing assumptions:**
- **Risk**: Uncertain when button press becomes visible (frame N? N+1?)
- **Mitigation**: Test at multiple frames, observe actual behavior
- **Fallback**: Adjust play-spec timing based on findings

**Button byte format:**
- **Risk**: LSR/ROL pattern may build byte incorrectly (bit order wrong?)
- **Mitigation**: Test all 8 buttons individually, verify bit positions
- **Fallback**: Reverse bit order if needed, document deviation

**Phase 1 limitations:**
- **Risk**: Can't measure cycle cost without cycle counter
- **Mitigation**: Accept limitation, document for Phase 2
- **Fallback**: Note in LEARNINGS.md - "cycle count unvalidated in Phase 1"

---

## Dependencies

**Build tools:**
- ca65/ld65 (installed via toy0)
- Make
- Perl + Test::More

**Testing infrastructure:**
- NES::Test Phase 1 (lib/NES/Test.pm)
- nes-test-harness.js (lib/nes-test-harness.js)
- jsnes npm package

**Reference docs:**
- learnings/input_handling.md (controller theory)
- TOY_DEV_NES.md (testing methodology)
- toys/toy2_ppu_init/ (init sequence reference)

---

## Success Metrics

**Code quality:**
- Clean assembly (comments, clear structure)
- Minimal (only what's needed for validation)
- Reusable controller read pattern

**Testing:**
- All play-spec.pl tests pass (15+ assertions for 8 buttons + combinations)
- Deterministic (same ROM → same results)
- Fast (< 5 seconds to run)

**Documentation:**
- LEARNINGS.md complete with controller findings
- README.md clear and concise
- Standard controller read pattern documented for reuse

**Knowledge transfer:**
- Controller read pattern proven for all future toys
- NES::Test `press_button` validated
- Button byte format confirmed (%ABSS UDLR)
- jsnes controller accuracy assessed

---

## Time Estimate

**Total: 1-2 hours** (similar to toy2, well-understood pattern)

- Step 2 (infrastructure): 10 minutes (copy from toy2)
- Step 3 (play-spec): 20 minutes (more assertions than toy2, but straightforward)
- Steps 4-6 (assembly): 45 minutes (init + controller read, standard pattern)
- Steps 7-9 (docs): 15-30 minutes

**Comparison to toy1 and toy2:**
- toy1: 45 minutes actual (2-3 hour estimate) - 3x faster
- toy2: 30 minutes actual (1-2 hour estimate) - 2x faster
- toy3: Similar complexity to toy2 (standard read pattern, well-documented)
- TDD workflow proven efficient (2x-3x faster than estimates)

**Estimated: 1 hour**
