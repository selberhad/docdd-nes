# LEARNINGS — Ppu_init

**Duration**: TBD | **Status**: Planning | **Estimate**: 1-2 hours

## Learning Goals

### Questions to Answer

**From learnings/.docdd/5_open_questions.md:**

**Q1.4 (partial - PPU warmup timing)**: How to measure PPU warmup cycles?
- Phase 1 (this toy): Can we detect vblank flag transitions via jsnes?
- Phase 2 (future): Measure actual 29,658-cycle warmup with cycle-counting emulator
- Theory says ~27,384 cycles to first vblank, ~29,658 total warmup

**Hardware behavior (from learnings/getting_started.md - validate in practice):**
- Does PPU require two vblank waits before being usable?
- Does $2002 bit 7 reliably indicate vblank status?
- What happens if we write to PPUCTRL/PPUMASK too early?
- Does the address latch ($2005/$2006) clear correctly at startup?
- Can we read PPUSTATUS during warmup period?

**Testing workflow (Phase 1 capabilities):**
- Can NES::Test detect PPU register state changes?
- How to assert vblank flag state via jsnes?
- Can we verify registers are cleared to expected power-on values?
- Frame-by-frame progression of PPU initialization observable?

**jsnes emulation accuracy:**
- Does jsnes accurately emulate PPU power-up state?
- Are register values at reset correct ($2000/$2001 = 0, etc.)?
- Does jsnes enforce 2-vblank warmup constraint?

### Decisions to Make

**Test strategy:**
- Test all registers ($2000-$2007) or just critical ones ($2002)?
- Should we test writes to PPUCTRL/PPUMASK during warmup (expect failure)?
- How many frames needed to prove warmup complete? (2? 3? More?)
- Test with minimal init or full standard pattern?

**ROM design:**
- Wait 2 vblanks in main loop or use standard init pattern?
- Test PPUSTATUS polling pattern (BIT $2002 / BPL loop)?
- Initialize other subsystems (stack, APU) or PPU-only focus?
- How to make vblank transitions observable via jsnes?

**Phase 1 vs Phase 2 split:**
- What can we validate NOW with register state inspection?
- What requires Phase 2 (cycle counting for 29,658 cycles)?
- What requires Phase 3 (visual validation - rendering enabled)?

### Success Criteria

**Phase 1 (this toy) - State validation:**
- ✅ PPUSTATUS $2002 bit 7 toggles correctly during vblank transitions
- ✅ PPUCTRL/PPUMASK initialized to 0 at reset
- ✅ Two-vblank wait pattern completes successfully
- ✅ Registers readable/writable after warmup period
- ✅ play-spec.pl passes with PPU state assertions

**Phase 2 (future upgrade):**
- Measure actual warmup cycle count (theory: ~29,658 cycles)
- Verify timing of first vblank (~27,384 cycles from reset)
- Confirm writes to $2000/$2001 ignored before warmup complete

**Phase 3 (manual validation):**
- Rendering works after initialization sequence
- Mesen2 debugger confirms register values at each step

---

## Theory (from learnings/getting_started.md)

### PPU Power-Up State

**Initial Register Values:**

| Register | At Power-On | After Reset |
|----------|-------------|-------------|
| PPUCTRL ($2000) | $00 | $00 |
| PPUMASK ($2001) | $00 | $00 |
| PPUSTATUS ($2002) | +0+x xxxx | U??x xxxx |
| OAMADDR ($2003) | $00 | unchanged |
| $2005/$2006 latch | cleared | cleared |
| PPUSCROLL ($2005) | $0000 | $0000 |
| PPUADDR ($2006) | $0000 | unchanged |
| PPUDATA ($2007) buffer | $00 | $00 |

**Critical Timing Constraints:**
- **~29,658 CPU cycles** must pass before writing PPUCTRL/PPUMASK/PPUSCROLL/PPUADDR
- **Internal reset signal** clears these registers during first vblank
- **Writes ignored** until end of first vblank (~27,384 cycles from power-on)
- **Other registers work immediately**: PPUSTATUS, OAMADDR, OAMDATA, PPUDATA, OAMDMA

### Standard 2-Vblank Wait Pattern

**Theory from wiki:**
```asm
reset:
    sei              ; ignore IRQs
    cld              ; disable decimal mode
    ldx #$ff
    txs              ; set up stack pointer
    inx              ; now X = 0
    stx $2000        ; disable NMI
    stx $2001        ; disable rendering

    ; Clear vblank flag (unknown state at power-on)
    bit $2002

    ; First vblank wait (~27,384 cycles)
@vblankwait1:
    bit $2002
    bpl @vblankwait1

    ; (Clear RAM here during warmup period)

    ; Second vblank wait (ensures PPU fully stabilized)
@vblankwait2:
    bit $2002
    bpl @vblankwait2

    ; Now safe to configure PPU and start rendering
```

**Key Points:**
1. **BIT $2002**: Read PPUSTATUS, bit 7 → N flag (negative if vblank active)
2. **BPL** (Branch if Plus): Loop while bit 7 = 0 (not in vblank)
3. **First wait**: Ensures at least one vblank has passed
4. **Second wait**: Ensures PPU internal state stabilized
5. **Clear vblank first**: State unknown at power-on, clear before testing

### PPUSTATUS Register ($2002)

**Bit 7 (Vblank flag):**
- Set at start of vblank (~2273 cycles before rendering begins)
- Cleared at end of vblank (when rendering starts)
- **Reading $2002 clears bit 7** (critical side effect!)
- Used for polling: `BIT $2002` sets CPU N flag from bit 7

**Other bits:**
- Bit 6: Sprite 0 hit (not relevant for init)
- Bit 5: Sprite overflow (not relevant for init)
- Bits 4-0: Open bus (undefined, ignore)

---

## Questions to Answer Through Practice

**PPU Warmup Behavior:**
1. Does jsnes enforce 2-vblank wait requirement?
2. What happens if we write to $2000/$2001 immediately at reset?
3. Does $2002 bit 7 toggle correctly on frame boundaries?
4. How many frames until PPU registers stabilize? (2 confirmed? 3 safe?)
5. Does "clear vblank flag first" matter (BIT $2002 before first loop)?

**PPUSTATUS Behavior:**
1. Does reading $2002 clear bit 7 immediately?
2. Can we poll $2002 continuously without side effects (besides bit 7 clear)?
3. What's the initial state of $2002 at power-on? (jsnes accurate?)
4. Does $2002 clearing affect address latch ($2005/$2006 write sequence)?

**Testing Infrastructure:**
1. Can NES::Test assertions verify PPU register state?
2. How to assert specific bits in $2002 (vblank flag)?
3. Can we track frame-by-frame register changes?
4. What's the minimal test that proves warmup completed?

**Frame Timing:**
1. Frame 0 vs Frame 1 observable state (from toy1: frame 1+ required)
2. Does vblank flag set at frame 1? Frame 2?
3. How to structure assertions for multi-frame initialization?

---

## Decisions to Make

**Test ROM scope:**
- [ ] Test minimal init (just vblank wait) or full pattern (stack, APU, RAM clear)?
- [ ] Poll PPUSTATUS in loop or check specific frames?
- [ ] Test register writes during warmup (expect ignored) or skip?

**Vblank detection approach:**
- [ ] Use standard BIT/BPL pattern or direct reads and assertions?
- [ ] Assert at specific frames (1, 2, 3) or loop until condition met?
- [ ] Test both "wait for set" and "wait for clear" patterns?

**Register validation:**
- [ ] Check all registers $2000-$2007 or just $2002 (PPUSTATUS)?
- [ ] Assert exact values or just verify behavior (flag transitions)?
- [ ] Test address latch clearing separately?

**Phase 1 limitations:**
- [ ] What PPU behavior is NOT testable without cycle counter?
- [ ] Which aspects require Phase 2 (Mesen cycle profiling)?
- [ ] Which aspects require Phase 3 (visual rendering validation)?

---

## Findings

**Duration**: TBD | **Status**: Planning | **Result**: TBD

### ✅ Validated
*To be filled during implementation*

### ⚠️ Challenged
*To be filled during implementation*

### ❌ Failed
*To be filled during implementation*

### 🌀 Uncertain
*To be filled during implementation*

---

## Patterns for Production

*To be filled with working code patterns after validation*

**Expected patterns:**
```asm
; Standard PPU init sequence (to be validated):
reset:
    sei              ; Disable IRQs
    cld              ; Clear decimal mode
    ldx #$ff
    txs              ; Initialize stack
    inx              ; X = 0
    stx $2000        ; Disable NMI
    stx $2001        ; Disable rendering

    bit $2002        ; Clear vblank flag

@vblankwait1:
    bit $2002        ; Read PPUSTATUS
    bpl @vblankwait1 ; Loop while bit 7 = 0

    ; Clear RAM here (if needed)

@vblankwait2:
    bit $2002
    bpl @vblankwait2

    ; PPU now ready for configuration
```
