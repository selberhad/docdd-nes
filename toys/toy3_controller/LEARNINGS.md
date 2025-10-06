# LEARNINGS — Controller

**Duration**: TBD | **Status**: Planning | **Estimate**: 1-2 hours

## Learning Goals

### Questions to Answer

**From learnings/.docdd/5_open_questions.md:**

**Q1.4 (partial - controller read timing)**: How to measure controller read cycles?
- Phase 1 (this toy): Can we verify controller state changes via RAM inspection?
- Phase 2 (future): Measure actual cycle cost of 3-step read pattern
- Theory: Read pattern involves strobe + 8 reads

**Hardware behavior (from learnings/input_handling.md - validate in practice):**
- Does 3-step strobe pattern work correctly? (write 1, write 0, read 8 times)
- Does button state byte format match theory (%ABSS UDLR)?
- Does jsnes accurately emulate controller hardware ($4016 behavior)?
- Can we read multiple buttons simultaneously?
- What happens if we read without strobing first?

**Testing workflow (NES::Test Phase 1):**
- Does `press_button` from NES::Test work correctly?
- Can we verify button state in RAM after controller read?
- Can we test button combinations (A+B, Up+A, etc.)?
- Frame timing for controller input (when does button press appear)?

**jsnes controller emulation:**
- Does jsnes accurately emulate $4016 strobe and read?
- Are button presses from NES::Test reflected in controller reads?
- Does bit 0 contain button state (other bits undefined)?

### Decisions to Make

**Test strategy:**
- Test single buttons first or combinations from start?
- Should we test all 8 buttons or subset (A, B, Start, directions)?
- How many frames needed to verify controller read worked?
- Test edge detection (newly pressed vs held) or just current state?

**ROM design:**
- Read controller in main loop or in NMI?
- Store button state in zero page or regular RAM?
- Test raw reads ($4016 bit 0) or full 8-button byte?
- How to make button state observable via jsnes RAM inspection?

**Button state format:**
- Use standard %ABSS UDLR format (from wiki)?
- Store in single byte or separate flags?
- Bit order: MSB = A button, LSB = Right button?

**Phase 1 vs Phase 2 split:**
- What can we validate NOW with state inspection?
- What requires Phase 2 (cycle counting for read timing)?
- What requires Phase 3 (edge case debugging in Mesen2)?

### Success Criteria

**Phase 1 (this toy) - State validation:**
- ✅ Single button presses detected correctly (A, B, Start, Up)
- ✅ Button combinations work (A+B, Up+A, etc.)
- ✅ Button state byte format matches theory (%ABSS UDLR)
- ✅ 3-step strobe pattern works (write 1, write 0, read 8 times)
- ✅ play-spec.pl passes with controller input assertions

**Phase 2 (future upgrade):**
- Measure controller read cycle cost (theory: ~140 cycles for full read)
- Verify timing doesn't exceed vblank budget
- Test DPCM conflicts (wiki warns about bit skip during DMC)

**Phase 3 (manual validation):**
- Verify in Mesen2 debugger (controller state display)
- Test on real hardware (controller response feels correct)

---

## Theory (from learnings/input_handling.md)

### 3-Step Controller Read Pattern

**Hardware registers:**
- **$4016** (read): Controller 1 data (bit 0 = button state, bits 1-7 undefined)
- **$4017** (read): Controller 2 data (bit 0 = button state, bits 1-7 undefined)
- **$4016** (write): Strobe signal to latch controller state

**Standard button order** (after strobe):
1. A
2. B
3. Select
4. Start
5. Up
6. Down
7. Left
8. Right

### Basic Read Pattern (Wiki Standard)

```asm
read_controller1:
  ; Step 1: Strobe controller to latch current state
  lda #$01
  sta $4016      ; Start strobe
  lda #$00
  sta $4016      ; End strobe (controller latches state)

  ; Step 2: Read 8 buttons (bit 0 of each read = button state)
  ldx #$08       ; 8 buttons to read
read_loop:
  lda $4016      ; Read button state
  lsr            ; Shift bit 0 into carry
  rol buttons1   ; Rotate carry into buttons1 (builds byte)
  dex
  bne read_loop
  rts

; After calling read_controller1:
; buttons1 = %ABSS UDLR (1 = pressed, 0 = released)
```

**Key points:**
1. **Strobe first**: Write 1 then 0 to $4016 (latches current button state)
2. **Read 8 times**: Each read of $4016 returns next button in sequence
3. **Only bit 0 valid**: Bits 1-7 are undefined (open bus), must mask or shift
4. **Result byte format**: %ABSS UDLR (MSB = A, LSB = Right)

### Button Masks

```asm
BUTTON_A      = $80  ; %10000000
BUTTON_B      = $40  ; %01000000
BUTTON_SELECT = $20  ; %00100000
BUTTON_START  = $10  ; %00010000
BUTTON_UP     = $08  ; %00001000
BUTTON_DOWN   = $04  ; %00000100
BUTTON_LEFT   = $02  ; %00000010
BUTTON_RIGHT  = $01  ; %00000001
```

**Usage:**
```asm
check_a_button:
  lda buttons1
  and #BUTTON_A
  beq a_not_pressed
  ; A button is pressed!
a_not_pressed:
```

### Common Pitfalls (from wiki)

**Pitfall 1: Reading without strobe**
- Forgetting to write 1→0 to $4016 → stale/garbage data

**Pitfall 2: Strobing during read**
- Writing to $4016 inside 8-button loop → corrupted data
- **CRITICAL**: Strobe ONCE before loop, not per button

**Pitfall 3: Ignoring bit masking**
- Reading full byte from $4016 without shifting bit 0 → garbage in bits 1-7
- Must use LSR or AND #$01 to isolate bit 0

---

## Questions to Answer Through Practice

**Controller Read Behavior:**
1. Does jsnes accurately emulate 3-step read pattern?
2. Does NES::Test `press_button` work with manual controller reads?
3. What frame does button press become visible? (frame 0? 1? 2?)
4. Can we verify all 8 buttons individually?
5. Do button combinations work (A+B, Up+Right, etc.)?

**Button State Format:**
1. Does %ABSS UDLR byte format work as documented?
2. Are button masks correct ($80, $40, $20, etc.)?
3. Can we use AND/BIT to test buttons from byte?

**Testing Infrastructure:**
1. Can NES::Test assertions verify button state in RAM?
2. How to structure play-spec for button presses?
3. Does `press_button 'A+B'` syntax work for combinations?
4. What's the minimal test that proves controller read worked?

**Timing:**
1. Does controller read work in main loop (not NMI)?
2. What's the relationship between frame number and button state?
3. Does jsnes update controller state frame-by-frame correctly?

---

## Decisions to Make

**Test ROM scope:**
- [ ] Test all 8 buttons or subset (A, B, Start, Up)?
- [ ] Test combinations or single buttons first?
- [ ] Test in main loop or NMI handler?

**Button state storage:**
- [ ] Store in zero page ($0010) or regular RAM?
- [ ] Use standard %ABSS UDLR format?
- [ ] Single byte or separate flags per button?

**Validation approach:**
- [ ] Assert exact byte values or individual button bits?
- [ ] Test sequential button presses or all at once?
- [ ] How many frames needed per test?

**Phase 1 limitations:**
- [ ] What controller behavior is NOT testable without cycle counter?
- [ ] Which aspects require Phase 2 (DPCM conflict testing)?
- [ ] Which aspects require Phase 3 (edge detection timing)?

---

## Findings

**Duration**: 1.5 hours (paused for debugging) | **Status**: Partial | **Result**: 3/8 tests passing, jsnes controller issues discovered

### ✅ Validated

**3-step controller read pattern works:**
- Strobe pattern (write $01, write $00 to $4016) correctly latches state
- 8-read loop with LSR/ROL builds button byte correctly
- **Critical**: Must clear button byte before each read (ROL accumulates previous state)
- Some buttons work correctly (Up, no-buttons state)

**NES::Test `press_button` integration:**
- Frame timing: button press at frame N → readable at frame N+1
- Button state appears after one frame delay (as expected)
- Combination syntax `press_button 'A+B'` works

**TDD workflow continues to be efficient:**
- Found and fixed critical bug in nes-test-harness.js during development
- Incremental commits helped isolate issues

### ⚠️ Challenged

**CRITICAL BUG FOUND: nes-test-harness.js button validation:**
- **Bug**: `if (!BUTTONS[buttonName])` failed for button A (value 0)
- **Cause**: jsnes.Controller.BUTTON_A = 0, so `!BUTTONS['A']` → `!0` → true (treated as missing)
- **Fix**: Changed to `if (!(buttonName in BUTTONS))` to properly check key existence
- **Impact**: Button A was completely unusable in all previous toys (toy1, toy2 didn't use controller)
- **Commit**: e8d04dc "fix(test): Fix button validation bug in nes-test-harness"

**jsnes controller emulation inconsistency:**
- ✅ Up button ($08) works correctly
- ✅ No buttons ($00) works correctly
- ❌ A button ($80) doesn't register (reads as $00)
- ❌ B button ($40) doesn't register (reads as $00)
- ❌ Start button ($10) doesn't register (reads as $00)
- ❌ Button combinations inconsistent

**Possible causes:**
1. jsnes button polarity issue (inverted logic?)
2. jsnes buttonDown/buttonUp not updating internal state correctly
3. Missing jsnes initialization step
4. Button read timing issue (reading too early/late?)

### ❌ Failed

**Full 8-button validation:**
- Cannot validate all buttons work until jsnes issue resolved
- 3/8 tests passing (38% success rate)
- Button state byte format unconfirmed for most buttons

**Phase 1 limitation revealed:**
- jsnes controller emulation may not be accurate enough for full validation
- May need Phase 2 (different emulator) sooner than expected

### 🌀 Uncertain

**jsnes controller accuracy:**
- Why does Up work but A/B/Start don't?
- Is this a jsnes bug or our implementation issue?
- Does jsnes require specific initialization we're missing?
- Are we reading at the wrong time in the frame?

**Next steps to resolve:**
1. Debug jsnes button state directly (console log in harness)
2. Compare jsnes controller implementation to NES spec
3. Test with Mesen2 manually (Phase 3 validation)
4. Consider alternative: TetaNES, FCEUX Lua, or different emulator for Phase 2

**Pattern validation incomplete:**
- Cannot confirm %ABSS UDLR byte format until all buttons work
- LSR/ROL pattern seems correct (Up works as expected)
- Strobe timing appears correct (no-buttons clears properly)

---

## Patterns for Production

**Controller read pattern (PARTIAL - jsnes issues, works for some buttons):**

```asm
read_controller1:
    ; Step 1: Strobe controller
    LDA #$01
    STA $4016           ; Start strobe
    LDA #$00
    STA $4016           ; End strobe (latches state)

    ; CRITICAL: Clear button byte before reading
    ; (ROL accumulates, must start from 0 each frame)
    STA $0010           ; A still = 0 from above

    ; Step 2: Read 8 buttons
    LDX #$08            ; 8 buttons to read
read_loop:
    LDA $4016           ; Read bit 0
    LSR                 ; Shift bit 0 to carry
    ROL $0010           ; Rotate carry into buttons
    DEX
    BNE read_loop

    RTS

; After return: $0010 = %ABSS UDLR (theory - partially validated)
; - Bit 7: A button
; - Bit 6: B button
; - Bit 5: Select
; - Bit 4: Start
; - Bit 3: Up (CONFIRMED working)
; - Bit 2: Down
; - Bit 1: Left
; - Bit 0: Right
```

**Key lessons learned:**

1. **Must clear target byte before ROL loop:**
   ```asm
   STA $0010    ; Clear before reading (ROL accumulates!)
   ```

2. **Frame timing for NES::Test:**
   ```perl
   press_button 'Up';
   at_frame N+1 => sub {
       assert_ram 0x0010 => 0x08;  # Readable next frame
   };
   ```

3. **nes-test-harness.js button validation bug (FIXED):**
   ```javascript
   // WRONG (treats button A as invalid):
   if (!BUTTONS[buttonName]) { ... }

   // CORRECT (checks key existence):
   if (!(buttonName in BUTTONS)) { ... }
   ```

**Status**: Pattern works in principle, but jsnes controller emulation needs debugging before full validation possible.
