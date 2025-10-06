# SPEC — Ppu_init

## Purpose

Validate PPU 2-vblank warmup sequence: verify PPUSTATUS polling pattern works and PPU registers stabilize after reset.

**Primary goal**: Prove NES::Test Phase 1 can detect PPU register state changes during initialization.

**Secondary goal**: Establish standard PPU init pattern for all future toys.

---

## What This ROM Does

**Initialization (reset):**
1. Standard CPU init:
   - SEI (disable IRQs)
   - CLD (clear decimal mode)
   - Initialize stack pointer ($FF → $01FF)

2. Disable PPU:
   - Write $00 to $2000 (PPUCTRL - disable NMI)
   - Write $00 to $2001 (PPUMASK - disable rendering)

3. Clear vblank flag:
   - Read $2002 once (clears bit 7, unknown state at power-on)

4. Wait for first vblank:
   - Loop: BIT $2002 / BPL (branch while bit 7 = 0)
   - Exits when PPUSTATUS bit 7 = 1 (vblank started)

5. Set marker 1:
   - Write $01 to $0010 (proves first vblank wait completed)

6. Wait for second vblank:
   - Loop: BIT $2002 / BPL (same pattern)
   - Exits when PPUSTATUS bit 7 = 1 again

7. Set marker 2:
   - Write $02 to $0010 (proves second vblank wait completed)
   - PPU warmup now complete

8. Enter infinite loop (ROM does nothing after init)

**What ROM does NOT do:**
- No rendering enabled (PPUMASK stays 0)
- No RAM clearing (not testing memory, just PPU)
- No NMI handler (no vblank interrupts)
- No sprite/background setup (PPU config deferred to later toys)

**Rationale**: Minimal ROM that proves 2-vblank wait pattern works. Establishes init sequence for all future toys.

---

## Input/Output

**Input**: None (no controller, no user interaction)

**Output (observable via NES::Test):**

**Frame 0 (reset executing):**
- $0010: $00 (marker not yet set)
- PPUCTRL ($2000): $00 (disabled)
- PPUMASK ($2001): $00 (disabled)
- PPUSTATUS ($2002): undefined (mid-reset)

**Frame 1 (after first vblank wait):**
- $0010: $01 (first marker set)
- PPUSTATUS bit 7: should have toggled at least once

**Frame 2+ (after second vblank wait):**
- $0010: $02 (second marker set - warmup complete)
- PPU registers stable and ready for configuration

---

## Success Criteria

### Phase 1 (Automated - play-spec.pl)

**Build validation:**
- ✅ ROM assembles and links without errors
- ✅ ROM is correct size (24592 bytes for NROM)
- ✅ iNES header correct (mapper 0)

**State validation (critical):**
- ✅ PPUCTRL ($2000) = $00 at reset
- ✅ PPUMASK ($2001) = $00 at reset
- ✅ Marker $0010 = $00 at frame 0 (before init)
- ✅ Marker $0010 = $01 at frame 1+ (after first vblank)
- ✅ Marker $0010 = $02 at frame 2+ (after second vblank)
- ✅ Vblank wait loops complete (ROM doesn't hang)

**NES::Test validation:**
- ✅ play-spec.pl passes all assertions
- ✅ No crashes or infinite loops detected
- ✅ State reads deterministic (same ROM → same state every run)

### Phase 2 (Future - cycle counting)

- Measure time to first vblank (~27,384 cycles)
- Measure total warmup time (~29,658 cycles)
- Verify PPUSTATUS bit 7 toggle timing matches theory

### Phase 3 (Manual - Mesen2)

- Load ROM in Mesen2
- Debugger: Verify register values at each step
- Breakpoints: Confirm vblank wait loops execute correctly
- Event viewer: Observe PPU state transitions

---

## Implementation Constraints

**Memory layout:**
- Marker byte: $0010 (zero page - fast access, easy to inspect)
- Code: $8000-$FFFF (16KB PRG-ROM)
- CHR-ROM: 8KB of zeros (no graphics needed)

**Timing:**
- No cycle counting (Phase 1 limitation - jsnes doesn't expose cycle API)
- Vblank detection via PPUSTATUS bit 7 polling only
- Frame-by-frame state inspection (not cycle-by-cycle)

**Testing:**
- jsnes determinism assumed (verify during implementation)
- No visual validation (state inspection only)
- Cannot directly test "writes ignored before warmup" (jsnes may not enforce)

---

## Test Data Rationale

**Why marker byte at $0010?**
- Zero page = fast access
- $0010 avoids conflict with toy1's OAM buffer ($0200-$02FF)
- Non-zero values ($01, $02) easy to verify (vs uninitialized $00)
- Observable via jsnes RAM inspection

**Why 2 vblanks?**
- Wiki requirement: PPU needs ~29,658 cycles to stabilize
- First vblank: ~27,384 cycles (internal reset signal clears)
- Second vblank: Additional safety margin (standard practice)
- Future toys will always use this pattern

**Why BIT $2002 / BPL pattern?**
- BIT: Read PPUSTATUS, set CPU N flag from bit 7 (doesn't affect A register)
- BPL: Branch while N flag = 0 (bit 7 = 0, not in vblank)
- Standard 6502 polling idiom (appears in all NES init code)
- Side effect: Reading $2002 clears bit 7 (must read again each loop)

**Why clear vblank flag first?**
- PPUSTATUS state unknown at power-on (wiki: "+0+x xxxx")
- Reading $2002 clears bit 7 regardless of current value
- Ensures first loop starts from known state (bit 7 = 0)

**Why empty CHR-ROM?**
- No rendering in this toy (PPUMASK = 0)
- Graphics validation deferred to future toys
- Simplifies ROM (no graphics data needed)

---

## Open Questions (to be answered during implementation)

1. Does jsnes accurately emulate PPU warmup timing?
   - Will loops complete in realistic frame counts?
   - Does jsnes enforce "writes ignored before warmup" constraint?

2. Can we detect PPUSTATUS bit 7 transitions via jsnes?
   - Is `nes.ppu.ppustatus` readable?
   - Can we observe bit 7 = 1 during vblank, 0 outside?

3. Does warmup work with minimal init?
   - Is stack/APU init required for PPU warmup?
   - Or is PPU independent (as theory suggests)?

4. What frame does each marker appear?
   - Frame 1 for first marker? Frame 2?
   - Does jsnes frame timing match theory?

5. Does reading $2002 clear bit 7 immediately in jsnes?
   - Can we observe this side effect?
   - Or is it abstracted away in jsnes implementation?

**Resolution strategy**: Build minimal ROM, run play-spec with frame-by-frame assertions. Update LEARNINGS.md with findings.
