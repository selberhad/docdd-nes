# Toy 3: Controller — 3-Step Read Pattern Validation

**Status**: ⚠️ Partial (3/8 tests passing, jsnes controller issues)
**Duration**: 1.5 hours (paused for debugging)
**Purpose**: Validate NES controller read pattern and button state byte format

---

## Current State

**Working:**
- ✅ 3-step strobe pattern (write $01/$00 to $4016)
- ✅ 8-read loop with LSR/ROL
- ✅ Some buttons work (Up, no-buttons)
- ✅ NES::Test `press_button` integration
- ✅ Found and fixed critical nes-test-harness.js bug

**Not Working:**
- ❌ Most buttons don't register (A, B, Start, etc.)
- ❌ jsnes controller emulation inconsistent
- ❌ Full byte format validation incomplete

---

## Critical Bug Fixed

**nes-test-harness.js button A validation bug:**

```javascript
// BUG (commit e8d04dc):
if (!BUTTONS[buttonName]) { ... }  // WRONG: fails for button A (value 0)

// FIX:
if (!(buttonName in BUTTONS)) { ... }  // CORRECT: checks key existence
```

**Impact**: Button A was unusable in all previous toys. Now fixed for future controller work.

---

## How to Run

```bash
cd toys/toy3_controller
make                  # Build ROM
perl play-spec.pl     # Run tests (3/8 passing)
```

**Current test results:**
```
ok 1 - RAM[0x0010] = 0x00     # No buttons
not ok 2 - RAM[0x0010] = 0x80  # A button (FAILS)
not ok 3 - RAM[0x0010] = 0x40  # B button (FAILS)
not ok 4 - RAM[0x0010] = 0x10  # Start (FAILS)
ok 5 - RAM[0x0010] = 0x08     # Up button (WORKS!)
not ok 6 - RAM[0x0010] = 0xC0  # A+B combo (FAILS)
not ok 7 - RAM[0x0010] = 0x88  # Up+A combo (FAILS)
ok 8 - RAM[0x0010] = 0x00     # No buttons
```

---

## Key Findings

### ✅ Validated

**Controller read pattern works (partially):**
- Strobe timing correct
- LSR/ROL byte-building correct
- **Critical lesson**: Must clear button byte before each read (ROL accumulates!)

**Frame timing:**
- Button press at frame N → readable at frame N+1
- Matches expected behavior

### ⚠️ jsnes Controller Emulation Issues

**Why some buttons work and others don't:**
- Up button ($08) works perfectly
- A/B/Start buttons don't register
- Possible jsnes emulation bug or our harness integration issue

**Next steps:**
1. Debug jsnes button state directly
2. Test manually in Mesen2 (Phase 3)
3. Consider alternative emulator for Phase 2

---

## Code Pattern (Partial Validation)

```asm
read_controller1:
    ; Strobe controller
    LDA #$01
    STA $4016       ; Start strobe
    LDA #$00
    STA $4016       ; End strobe

    ; CRITICAL: Clear before reading (ROL accumulates)
    STA $0010

    ; Read 8 buttons
    LDX #$08
read_loop:
    LDA $4016       ; Read bit 0
    LSR             ; Shift to carry
    ROL $0010       ; Build byte
    DEX
    BNE read_loop

    RTS
; $0010 should = %ABSS UDLR (partially confirmed)
```

---

## Files

- **controller.s** - Assembly source (3-step read pattern)
- **controller.nes** - Built ROM
- **play-spec.pl** - Automated tests (8 tests, 3 passing)
- **SPEC.md** - ROM behavior specification
- **PLAN.md** - TDD implementation plan
- **LEARNINGS.md** - Detailed findings and bug documentation

---

## What's Next

**Immediate:**
1. Debug jsnes controller state (why only some buttons work?)
2. Add console logging to nes-test-harness.js
3. Compare jsnes implementation to NES spec

**Phase 3 validation:**
- Test ROM manually in Mesen2 (keyboard controller input)
- Verify button reads work with real controller emulation

**Future:**
- Consider Phase 2 emulator switch (TetaNES, FCEUX) if jsnes unsuitable
- Complete 8-button validation once emulator issues resolved
- Establish standard controller read pattern for all future toys

---

**Status**: Paused at 3/8 tests passing. Controller read logic appears correct, but jsnes emulation needs debugging.

**See LEARNINGS.md for detailed bug report and analysis.**
