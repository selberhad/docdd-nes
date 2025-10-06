# SPEC — Controller

## Purpose

Validate NES controller read pattern: 3-step strobe + read sequence produces correct button state byte.

**Primary goal**: Prove NES::Test `press_button` works with manual controller reads in assembly.

**Secondary goal**: Establish standard controller read pattern for all future toys.

---

## What This ROM Does

**Initialization (reset):**
1. Standard init sequence (from toy2 pattern):
   - SEI, CLD, initialize stack
   - Disable PPU (PPUCTRL/PPUMASK = 0)
   - 2-vblank warmup wait
   - Initialize button state variable ($0010) to 0

**Main loop (every frame):**
1. Read controller using 3-step pattern:
   - Write $01 to $4016 (start strobe)
   - Write $00 to $4016 (end strobe, latch button state)
   - Read $4016 8 times, build button byte via LSR/ROL

2. Store button byte in RAM ($0010)

3. Loop forever (repeat each frame)

**What ROM does NOT do:**
- No sprite rendering (not testing graphics)
- No NMI handler (read in main loop for simplicity)
- No edge detection (just current button state)
- No button actions (just read and store)

**Rationale**: Minimal ROM that proves controller read works. Validates NES::Test + manual assembly reads.

---

## Input/Output

**Input (via NES::Test):**
- `press_button 'A'` → A button pressed for 1 frame
- `press_button 'A+B'` → A and B pressed simultaneously for 1 frame
- `press_button 'Up'` → Up button pressed for 1 frame
- etc.

**Output (observable via NES::Test):**

**Frame N (button pressed via NES::Test):**
- $0010: $00 (previous state, before read)

**Frame N+1 (after controller read):**
- $0010: Button byte (%ABSS UDLR format)
  - A button: $80 (%10000000)
  - B button: $40 (%01000000)
  - A+B: $C0 (%11000000)
  - Start: $10 (%00010000)
  - Up: $08 (%00001000)
  - etc.

**Button byte format:**
- Bit 7 (MSB): A button
- Bit 6: B button
- Bit 5: Select button
- Bit 4: Start button
- Bit 3: Up button
- Bit 2: Down button
- Bit 1: Left button
- Bit 0 (LSB): Right button

**1 = pressed, 0 = released**

---

## Success Criteria

### Phase 1 (Automated - play-spec.pl)

**Build validation:**
- ✅ ROM assembles and links without errors
- ✅ ROM is correct size (24592 bytes for NROM)
- ✅ iNES header correct (mapper 0)

**State validation (critical):**
- ✅ A button press → $0010 = $80
- ✅ B button press → $0010 = $40
- ✅ Start button press → $0010 = $10
- ✅ Up button press → $0010 = $08
- ✅ A+B combination → $0010 = $C0
- ✅ Up+A combination → $0010 = $88
- ✅ No button pressed → $0010 = $00
- ✅ All 8 buttons tested individually

**NES::Test validation:**
- ✅ play-spec.pl passes all assertions
- ✅ `press_button` works with manual reads
- ✅ Button combinations work correctly
- ✅ State reads deterministic

### Phase 2 (Future - cycle counting)

- Measure controller read cycle cost (theory: ~140 cycles)
- Verify timing fits in vblank budget
- Test DPCM conflict behavior (bit skip during DMC)

### Phase 3 (Manual - Mesen2)

- Load ROM in Mesen2
- Debugger: Verify $0010 contains correct button byte
- Test with keyboard input (Mesen2 controller mapping)

---

## Implementation Constraints

**Memory layout:**
- Button state byte: $0010 (zero page - fast access)
- Code: $8000-$FFFF (16KB PRG-ROM)
- CHR-ROM: 8KB of zeros (no graphics needed)

**Timing:**
- Read controller in main loop (not NMI for simplicity)
- No cycle counting (Phase 1 limitation)
- Frame-by-frame state inspection

**Testing:**
- jsnes controller emulation assumed accurate
- No visual validation (state inspection only)

---

## Test Data Rationale

**Why test all 8 buttons?**
- Validates full read sequence (not just first few buttons)
- Proves byte format correct (%ABSS UDLR)
- Each button has unique bit position

**Why test button combinations?**
- NES::Test supports `press_button 'A+B'` syntax
- Real games need combinations (jump+shoot, etc.)
- Validates multiple bits set correctly

**Why button state at $0010?**
- Zero page = fast access
- Same location as toy2 marker (reuse pattern)
- Easy to inspect via NES::Test RAM assertions

**Why main loop read (not NMI)?**
- Simpler for Phase 1 (no interrupt overhead)
- Still validates 3-step pattern works
- Future toys will use NMI pattern (this proves basics)

**Why %ABSS UDLR format?**
- Wiki standard (documented in learnings/input_handling.md)
- Easy to test with AND masks ($80, $40, $20, etc.)
- Single byte stores all 8 buttons efficiently

**Test sequence:**
1. Individual buttons (A, B, Start, Up) → verify bit positions
2. Combinations (A+B, Up+A) → verify multiple bits
3. No buttons → verify all zeros

---

## Open Questions (to be answered during implementation)

1. Does jsnes accurately emulate $4016 strobe and read?
2. Does NES::Test `press_button` work with manual controller reads?
3. What frame does button state become visible?
   - press_button at frame N → read at frame N? N+1?
4. Does LSR/ROL pattern build byte correctly?
5. Do all 8 button positions work as documented?
6. Does combination syntax (`press_button 'A+B'`) work?

**Resolution strategy**: Build minimal ROM with TDD, observe actual behavior, update LEARNINGS.md.
