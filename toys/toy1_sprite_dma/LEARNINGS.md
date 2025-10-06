# LEARNINGS — Sprite_dma

**Duration**: TBD | **Status**: Planning | **Estimate**: TBD

## Learning Goals

### Questions to Answer

**From learnings/.docdd/5_open_questions.md:**

**Q1.4 (partial - Phase 1 limitations)**: How to measure cycle counts in automated tests?
- Phase 1 (this toy): Can we verify OAM DMA *happened* via state inspection?
- Phase 2 (future): Measure actual 513-cycle timing with cycle-counting emulator

**Hardware behavior (not in open questions, but critical):**
- Does writing to $4014 reliably trigger OAM DMA?
- Does jsnes accurately emulate OAM DMA (shadow buffer → PPU OAM)?
- Can we verify sprite data in PPU OAM via jsnes's `nes.ppu.spriteMem`?
- What's the minimal sprite setup to confirm rendering would work?

**Testing workflow (this toy is first real Phase 1 test):**
- Does NES::Test DSL work for hardware validation (beyond toy0's simple checks)?
- Can we write meaningful assertions about sprite state?
- How to structure play-spec for non-interactive ROMs?

### Decisions to Make

**Test strategy:**
- What sprite configuration proves DMA worked? (1 sprite? 4 sprites? Full 64?)
- Should we test partial OAM updates or always full 256-byte buffer?
- How to verify DMA timing without cycle counter (Phase 1 limitation)?

**ROM design:**
- Initialize sprites during main loop or during NMI?
- Test with rendering enabled or disabled?
- How to make sprite state observable via jsnes (what data patterns to use)?

**Phase 1 vs Phase 2 split:**
- What can we validate NOW with jsnes state inspection?
- What requires Phase 2 (cycle counting, frame buffer)?
- What requires Phase 3 (visual validation in Mesen2)?

### Success Criteria

**Phase 1 (this toy) - State validation:**
- ✅ Shadow OAM buffer at $0200-$02FF populated with sprite data
- ✅ Writing to $4014 triggers DMA (PPU OAM matches shadow OAM)
- ✅ Sprite data verifiable via jsnes's `nes.ppu.spriteMem` array
- ✅ play-spec.pl passes with meaningful assertions

**Phase 2 (future upgrade):**
- Measure OAM DMA cycle count (theory: 513 cycles)
- Verify DMA timing doesn't exceed vblank budget

**Phase 3 (manual validation):**
- Sprite visually appears in Mesen2 at expected position
- Correct tile, palette, flip attributes applied

---

## Theory (from learnings/sprite_techniques.md)

### OAM DMA Pattern

**Shadow OAM buffer:**
- Reserve $0200-$02FF (256 bytes, page-aligned) for sprite data in RAM
- Update sprites during game logic (fast, no timing constraints)
- DMA entire buffer to PPU OAM during vblank

**DMA Trigger:**
```asm
lda #$02        ; High byte of shadow OAM ($0200)
sta $4014       ; Start DMA transfer
; CPU stalled for 513 cycles (+ 1 if odd cycle)
; PPU OAM now contains copy of $0200-$02FF
```

**Timing (theory):**
- 513 cycles on even CPU cycle, 514 on odd cycle
- Occurs during vblank (2273 cycle budget)
- Atomic operation (no partial updates visible)

### Sprite Structure (4 bytes each, 64 sprites max)

**Per-sprite OAM layout:**
- Byte 0: Y position (0-239, sprite top edge)
- Byte 1: Tile number (pattern table index)
- Byte 2: Attributes (palette, priority, flip H/V)
- Byte 3: X position (0-255, sprite left edge)

**OAM Indices:**
- Sprite 0: Bytes 0-3
- Sprite 1: Bytes 4-7
- ...
- Sprite 63: Bytes 252-255

---

## Questions to Answer Through Practice

**OAM DMA Behavior:**
1. Does DMA work with rendering disabled (PPUMASK = 0)?
2. Can we DMA from addresses other than $0200? (Theory: yes, any page-aligned)
3. What happens if DMA triggered outside vblank? (Corruption risk)
4. Does jsnes accurately emulate DMA timing and behavior?

**Testing Infrastructure:**
1. Can NES::Test assertions verify sprite state reliably?
2. How to structure play-spec for initialization-only ROMs (no input)?
3. What's the minimal test that proves DMA worked?

**Practical Constraints:**
1. Do we need PPU initialized before DMA works?
2. Does sprite 0 behave differently (sprite 0 hit implications)?
3. Can we test with empty CHR-ROM (tiles all zeros)?

---

## Decisions to Make

**Test ROM scope:**
- [ ] Single sprite or multiple sprites?
- [ ] Test during init or during NMI loop?
- [ ] Rendering enabled or disabled?

**Sprite test data:**
- [ ] What Y/X positions? (visible range? off-screen?)
- [ ] What tile numbers? (does it matter with empty CHR?)
- [ ] What attributes? (palette, flip - observable via state?)

**Validation approach:**
- [ ] Assert exact OAM bytes or just verify non-zero?
- [ ] Test full 256-byte buffer or just first few sprites?
- [ ] How to prove DMA happened vs direct OAM writes?

---

## Findings

*To be filled during implementation*

### ✅ Validated

### ⚠️ Challenged

### ❌ Failed

### 🌀 Uncertain

---

## Patterns for Production

*To be extracted after toy completion*

**Reusable code patterns:**
- OAM DMA initialization sequence
- Shadow OAM buffer layout ($0200-$02FF convention)
- Sprite data structure (helper functions?)

**Testing patterns:**
- play-spec structure for state validation toys
- Assertions for sprite/OAM data
- Phase 1 limitations and workarounds

**Integration notes:**
- How to integrate DMA into main game NMI handler
- Memory layout conventions (shadow OAM placement)
- Build patterns (Makefile, assembly structure)
