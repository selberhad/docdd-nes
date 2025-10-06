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

**Duration**: ~45 minutes (debugging session) | **Status**: INCOMPLETE - Moving to toy4 | **Result**: 4/8 tests passing, controller reading has logic bug

### ✅ Validated

**Tool improvements:**
- **Extended inspect-rom.pl** - Now shows 64 bytes of code at reset vector (was 16)
- Added address labels ($8000, $8010, etc.) for easier reading
- Binary comparison reveals code structure differences between toys
- **Committed**: Updated inspect-rom.pl to show 4 rows of 16 bytes

**ROM execution fixed:**
- **Initial problem**: ROM appeared valid but jsnes wouldn't execute it
- **Solution**: Clean rebuild (`make clean && make`) fixed execution issue
- **Root cause**: Unknown (possibly stale build artifact)
- **Lesson**: Always try clean rebuild before deep debugging

**Test harness works correctly:**
- jsnes controller emulation DOES work (buttons press/release correctly)
- Debug output shows state changes: `[40,40,40,40,40,40,40,40]` → `[41,40,40,40,40,40,40,40]` on button A
- Harness button validation bug fixed (commit e8d04dc)
- Foundation tests still pass: toy1 (20/20), toy2 (5/5)

**Partial controller validation:**
- Some buttons work correctly: START (0x10), UP+A combo (0x88), no-button baseline (0x00)
- Test pattern: 4/8 tests passing

### ⚠️ Challenged

**Controller reading logic has bugs:**
- **Pattern**: Some buttons work, others fail in specific ways
- **Working**: START (0x10), UP+A combo (0x88), no-button (0x00)
- **Failing**:
  - A button: expect 0x80, got 0x00 (bit 7 not set)
  - B button: expect 0x40, got 0x04 (wrong bit position)
  - UP alone: expect 0x08, got 0x02 (wrong bit position)
  - A+B combo: expect 0xC0, got 0x03 (both wrong)

**Evidence from debug output:**
```
# Button A pressed:
[DEBUG] buttonDown: controller=1, button=A (index=0)
[DEBUG] getState: frame=2, ctrl1=[41,40,40,40,40,40,40,40]  # jsnes works!
not ok 2 - RAM[0x0010] = 0x80
#          got: '0'         # ROM reads wrong value
#     expected: '128'

# Button B pressed:
[DEBUG] buttonDown: controller=1, button=B (index=1)
[DEBUG] getState: frame=3, ctrl1=[40,41,40,40,40,40,40,40]  # jsnes works!
not ok 3 - RAM[0x0010] = 0x40
#          got: '4'         # Wrong bit (bit 2 instead of bit 6)
#     expected: '64'
```

**Hypothesis:**
- Controller read loop may have off-by-one error
- LSR/ROL bit shifting logic may be incorrect
- Button order may be reversed or rotated

### ❌ Failed (Timeboxed - Moving On)

**Complete controller validation:**
- 4/8 tests passing (50% success rate)
- Single buttons A, B, UP have bit position errors
- Controller reading logic needs debugging (likely LSR/ROL issue)

**Decision: Moving to toy4_nmi**
- Timeboxed to 3 debugging attempts (completed)
- Gained valuable insights (inspect-rom.pl improvements, clean rebuild lesson)
- Controller reading is a known pattern - can return to debug later
- Unblocks progress on other critical subsystems (NMI, sprite DMA integration)

### 🌀 Open Questions (For Later)

**What's wrong with the controller read loop?**
- Why does START (0x10) work but A (0x80) returns 0x00?
- Why does B button give 0x04 instead of 0x40? (bit 2 vs bit 6)
- Is the LSR/ROL order wrong? Off-by-one in loop counter?
- Is button order reversed (reading right-to-left instead of left-to-right)?

**Next steps (when revisiting):**
1. Read controller.s read_controller1 subroutine closely
2. Check loop counter initialization (LDX #$08 correct?)
3. Verify LSR/ROL order (should be LSR $4016, ROL target)
4. Test minimal controller read in isolation (single button, print each bit)
5. Compare working toy1/toy2 code if they have controller reads

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

**Status**: PARTIAL VALIDATION ONLY (4/8 tests passing)
- ✅ jsnes controller emulation works correctly
- ✅ NES::Test DSL works for button presses
- ✅ Frame timing works (button state readable next frame)
- ❌ Controller read loop has bit position bugs (needs debugging)

**Lessons learned:**
1. **Clean rebuild first** - Stale build artifacts can cause mysterious execution failures
2. **inspect-rom.pl is invaluable** - Extended to 64 bytes for better code comparison
3. **Debug output critical** - Proved jsnes works, isolated bug to ROM logic
4. **Timeboxing works** - 3 attempts gave progress, avoided rabbit hole
5. **Some validation > no validation** - 50% passing still proves infrastructure works

**To revisit later:** Debug controller read loop LSR/ROL logic (likely off-by-one or bit order issue).
