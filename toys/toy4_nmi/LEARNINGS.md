# LEARNINGS — NMI Handler

**Duration**: TBD | **Status**: Planning | **Estimate**: 1-2 hours

## Learning Goals

### Questions to Answer

**From learnings/timing_and_interrupts.md - Validate NMI theory in practice:**

**Q1: Does jsnes emulate NMI correctly?**
- Does jsnes fire NMI when $2000 bit 7 set?
- Does NMI fire every vblank (~60Hz)?
- Can we observe NMI execution via RAM counter?
- Is NMI timing consistent across frames?

**Q2: OAM DMA in NMI handler works?**
- Can we combine toy1 (OAM DMA) + NMI handler patterns?
- Does OAM DMA work inside NMI handler (not just main loop)?
- Does sprite position update every frame via NMI?
- Is the 513-514 cycle cost observable?

**Q3: Frame synchronization patterns work?**
- **Pattern 1 (Main only)**: NMI sets flag, main loop polls, uploads OAM DMA?
- **Pattern 2 (NMI only)**: All logic in NMI, main loop does nothing?
- **Pattern 3 (NMI+Main)**: PPU updates in NMI, game logic in main?
- Which pattern is testable via RAM inspection with jsnes?

**Q4: Observable NMI behavior in RAM?**
- Can we track NMI count (frame counter)?
- Can we verify NMI handler executed (debug markers)?
- Can we observe sprite position updates driven by NMI?
- What's the minimal testable NMI behavior for Phase 1 (jsnes)?

### Decisions to Make

**NMI handler pattern for testing:**
- [ ] Use "Main only" pattern (simplest - NMI sets flag, main does work)?
- [ ] Use "NMI only" pattern (all work in NMI)?
- [ ] Test both patterns?

**NMI flag storage:**
- [ ] Zero page byte for NMI flag ($0010)?
- [ ] Frame counter separate from NMI flag?

**Observable behavior:**
- [ ] Increment frame counter in NMI?
- [ ] Update sprite position in NMI?
- [ ] Both (counter + sprite animation)?

**Integration with toy1/toy2:**
- [ ] Reuse toy1 OAM DMA pattern exactly?
- [ ] Reuse toy2 PPU init pattern exactly?
- [ ] Combine both with NMI handler?

### Success Criteria

**Phase 1 (this toy) - NMI validation via jsnes:**
- ✅ NMI handler executes every frame (verified via frame counter in RAM)
- ✅ OAM DMA works in NMI handler (sprite updates every frame)
- ✅ Main loop synchronized with vblank (waits for NMI flag)
- ✅ Frame counter increments reliably (60fps observable)
- ✅ play-spec.pl passes with NMI + sprite update assertions

**Phase 2 (future upgrade):**
- Measure NMI handler cycle cost (theory: 2273 cycles budget)
- Verify PPUCTRL NMI enable works ($2000 bit 7)
- Test NMI + IRQ interaction (not needed for basic games)

**Phase 3 (manual validation):**
- Verify in Mesen2 debugger (breakpoint in NMI handler)
- Visual confirmation of sprite animation driven by NMI

---

## Theory (from learnings/timing_and_interrupts.md)

### NMI (Non-Maskable Interrupt)

**What it is:**
- Interrupt fired by PPU at start of vblank (~60Hz on NTSC)
- Vector at $FFFA-$FFFB points to NMI handler address
- Enabled via $2000 bit 7 (PPUCTRL NMI enable)
- Cannot be disabled once enabled (except via $2000)

**Vblank timing:**
- **NTSC**: 2273 CPU cycles available during vblank
- **PAL**: 7459 CPU cycles (longer vblank)
- Must complete PPU updates before rendering starts

**Typical cycle budget:**
- OAM DMA: 513-514 cycles
- Scroll registers: ~20 cycles
- VRAM updates: Variable (budget remaining cycles)
- Music: ~500-1000 cycles (can run during rendering if needed)

### NMI Handler Patterns (3 Main Styles)

#### Pattern 1: Main Only (Simplest)
**Pattern**: NMI sets flag, main loop does all work

```asm
nmi_handler:
  inc nmi_flag   ; Signal vblank occurred
  rti

main_loop:
  lda nmi_flag
  beq main_loop  ; Wait for NMI
  lda #0
  sta nmi_flag

  ; Do all work (OAM DMA, game logic, etc.)
  lda #$02
  sta $4014      ; OAM DMA

  jmp main_loop
```

**Pros**: Simple, easy to debug
**Cons**: If logic exceeds 1 frame, timing inconsistent

#### Pattern 2: NMI Only (Super Mario Bros. Style)
**Pattern**: All logic in NMI, main loop idles

```asm
nmi_handler:
  ; All work happens here
  lda #$02
  sta $4014      ; OAM DMA
  jsr read_controller
  jsr update_game
  rti

main_loop:
  jmp main_loop  ; Infinite loop
```

**Pros**: Consistent timing, music never slows
**Cons**: Must fit all logic in vblank (~2273 cycles)

#### Pattern 3: NMI + Main (Recommended for Complex Games)
**Pattern**: PPU updates in NMI, game logic in main

```asm
nmi_handler:
  pha            ; Save registers
  ; PPU updates only
  lda #$02
  sta $4014      ; OAM DMA
  ; Set scroll, upload VRAM buffer, etc.
  inc nmi_flag   ; Signal NMI occurred
  pla            ; Restore registers
  rti

main_loop:
  lda nmi_flag
  beq main_loop
  lda #0
  sta nmi_flag

  ; Game logic (can exceed 1 frame)
  jsr update_game
  jmp main_loop
```

**Pros**: Music timing consistent, logic can exceed 1 frame
**Cons**: More complex, requires double-buffering

### Enabling NMI

```asm
; Enable NMI in PPUCTRL ($2000)
lda #%10000000   ; NMI enable (bit 7)
sta $2000

; Disable NMI
lda #%00000000   ; NMI disable
sta $2000
```

**CRITICAL**: Must wait for PPU warmup (2 vblanks) before enabling NMI (from toy2)

---

## Questions to Answer Through Practice

**NMI Execution:**
1. Does jsnes fire NMI when $2000 bit 7 set?
2. Is NMI frequency observable (60fps frame counter)?
3. Can we verify NMI handler runs (debug marker in RAM)?
4. Does NMI vector at $FFFA work correctly?

**OAM DMA in NMI:**
1. Does OAM DMA work inside NMI handler?
2. Can sprites update every frame via NMI?
3. Does toy1 OAM DMA pattern work in NMI context?

**Frame Synchronization:**
1. Does main loop wait for NMI correctly (polling flag)?
2. Does NMI flag set/clear pattern work?
3. Can we observe frame-by-frame sprite updates?

**Integration:**
1. Can we combine toy1 (OAM DMA) + toy2 (PPU init) + NMI?
2. Does full init sequence + NMI enable work?
3. Are there edge cases in jsnes NMI emulation?

---

## Decisions to Make

**Test ROM scope:**
- [ ] Test Pattern 1 (Main only) or Pattern 2 (NMI only)?
- [ ] Include frame counter + sprite animation or just counter?
- [ ] Test NMI enable/disable or just enable?

**Observable behavior:**
- [ ] Frame counter in RAM ($0010)?
- [ ] Sprite X position updates every frame?
- [ ] Debug markers in NMI handler?

**Validation approach:**
- [ ] Assert frame counter increments?
- [ ] Assert sprite position changes?
- [ ] How many frames to test (10? 60?)?

**Integration strategy:**
- [ ] Copy toy1 OAM DMA code exactly?
- [ ] Copy toy2 PPU init code exactly?
- [ ] Combine both with NMI handler?

---

## Findings

**Duration**: TBD | **Status**: Planning | **Result**: TBD

### ✅ Validated

(To be filled after implementation)

### ⚠️ Challenged

(To be filled after implementation)

### ❌ Failed

(To be filled after implementation)

### 🌀 Uncertain

(To be filled after implementation)

---

## Patterns for Production

(To be extracted after validation)

**NMI handler pattern:**
```asm
; (To be documented after testing)
```

**Frame synchronization pattern:**
```asm
; (To be documented after testing)
```

**OAM DMA in NMI pattern:**
```asm
; (To be documented after testing)
```

**Key lessons learned:**
(To be documented after testing)
