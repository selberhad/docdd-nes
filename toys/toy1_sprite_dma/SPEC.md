# SPEC — Sprite_dma

## Purpose

Validate OAM DMA mechanism: shadow OAM buffer in RAM → PPU OAM via $4014 write.

**Primary goal**: Prove NES::Test Phase 1 can detect sprite state changes after DMA.

**Secondary goal**: Establish minimal sprite setup pattern for future toys.

---

## What This ROM Does

**Initialization (reset):**
1. Initialize 4 test sprites in shadow OAM buffer ($0200-$020F)
   - Sprite 0: Y=100, Tile=$42, Attr=$01, X=80
   - Sprite 1: Y=110, Tile=$43, Attr=$02, X=90
   - Sprite 2: Y=120, Tile=$44, Attr=$03, X=100
   - Sprite 3: Y=130, Tile=$45, Attr=$00, X=110

2. Trigger OAM DMA by writing `#$02` to `$4014`

3. Enter infinite loop (ROM does nothing after DMA)

**What ROM does NOT do:**
- No PPU initialization (no rendering enabled)
- No NMI handler (no vblank interrupts)
- No controller input
- No visual output (CHR-ROM empty)

**Rationale**: Minimal ROM that proves DMA works. Complexity added in later toys.

---

## Input/Output

**Input**: None (no controller, no user interaction)

**Output (observable via NES::Test):**

**Before DMA (frame 0):**
- Shadow OAM ($0200-$020F): Populated with test sprite data
- PPU OAM (nes.ppu.spriteMem[0-15]): Zeros (or undefined)

**After DMA (frame 1):**
- Shadow OAM ($0200-$020F): Unchanged (still has sprite data)
- PPU OAM (nes.ppu.spriteMem[0-15]): **Matches shadow OAM** (DMA succeeded)

---

## Success Criteria

### Phase 1 (Automated - play-spec.pl)

**Build validation:**
- ✅ ROM assembles and links without errors
- ✅ ROM is correct size (24592 bytes for NROM)
- ✅ iNES header correct (mapper 0)

**State validation (critical):**
- ✅ Shadow OAM buffer contains expected sprite data before DMA
- ✅ PPU OAM matches shadow OAM after DMA trigger
- ✅ All 4 test sprites copied correctly (16 bytes total)
- ✅ Sprite 0 data: Y=100, Tile=$42, Attr=$01, X=80
- ✅ Sprite 1 data: Y=110, Tile=$43, Attr=$02, X=90
- ✅ Sprite 2 data: Y=120, Tile=$44, Attr=$03, X=100
- ✅ Sprite 3 data: Y=130, Tile=$45, Attr=$00, X=110

**NES::Test validation:**
- ✅ play-spec.pl passes all assertions
- ✅ No crashes or hangs
- ✅ State reads deterministic (same ROM → same state every run)

### Phase 2 (Future - cycle counting)

- Measure OAM DMA cycle count (theory: 513 cycles)
- Verify DMA completes before vblank ends (if triggered in NMI)

### Phase 3 (Manual - Mesen2)

- Load ROM in Mesen2
- Visual: No sprites visible (rendering disabled, expected)
- Debugger: Verify OAM memory viewer shows sprite data
- Memory dump: $0200-$020F matches expected values

---

## Implementation Constraints

**Memory layout:**
- Shadow OAM: $0200-$02FF (256 bytes, only first 16 bytes used in this toy)
- Code: $8000-$FFFF (16KB PRG-ROM)
- CHR-ROM: 8KB of zeros (no graphics needed for state validation)

**Timing:**
- No vblank synchronization (DMA happens during init, not in NMI)
- No cycle counting (Phase 1 limitation)

**Testing:**
- jsnes determinism assumed (verify during implementation)
- No visual validation (state inspection only)

---

## Test Data Rationale

**Why 4 sprites?**
- More than 1 proves DMA works for multiple sprites
- Less than 64 keeps assertions simple
- 16 bytes (4 sprites × 4 bytes) is easy to verify

**Why these specific values?**
- Y positions: 100, 110, 120, 130 (sequential, easy to verify)
- Tile numbers: $42-$45 (sequential, visually distinct in hex)
- Attributes: $01, $02, $03, $00 (different palettes, easy to verify)
- X positions: 80, 90, 100, 110 (sequential, on-screen if rendering enabled)

**Why empty CHR-ROM?**
- Visual rendering not tested in Phase 1
- Simplifies ROM (no graphics data needed)
- Tile numbers still observable via OAM data

---

## Open Questions (to be answered during implementation)

1. Does jsnes accurately emulate OAM DMA without rendering enabled?
2. Can we reliably read nes.ppu.spriteMem[0-15] via NES::Test?
3. Do we need any PPU initialization for DMA to work?
4. Does DMA timing matter if not in vblank (init vs NMI)?

**Resolution strategy**: Build minimal ROM, run play-spec, observe behavior. Update LEARNINGS.md with findings.
