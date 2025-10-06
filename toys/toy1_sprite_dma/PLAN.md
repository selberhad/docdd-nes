# PLAN — Sprite_dma

## Strategy

**Test-First Development:**
1. Write play-spec.pl assertions (Red)
2. Write minimal assembly to pass (Green)
3. Commit working increment
4. Repeat until all assertions pass

**Incremental steps:**
- Build infrastructure first (Makefile, nes.cfg)
- Test ROM loads before testing DMA behavior
- Add sprite data incrementally (1 sprite → 4 sprites)
- DMA last (proves shadow OAM → PPU OAM transfer)

---

## Steps

### 1. [x] Scaffold toy directory
- `tools/new-toy.pl sprite_dma` → toys/toy1_sprite_dma/
- Files created: SPEC.md, PLAN.md, README.md, LEARNINGS.md
- **Status**: ✅ Complete

### 2. [ ] Copy build infrastructure from toy0

**Copy files:**
```bash
cp toys/toy0_toolchain/nes.cfg toys/toy1_sprite_dma/
cp toys/toy0_toolchain/Makefile toys/toy1_sprite_dma/
```

**Modify Makefile:**
- Change ROM name: `hello.nes` → `sprite_dma.nes`
- Change source: `hello.s` → `sprite_dma.s`
- Keep test target (will update test.pl later)

**Test:**
```bash
cd toys/toy1_sprite_dma
make clean
# Should succeed (no source yet, expected failure)
```

**Commit:** `chore(toy1): Copy build infrastructure from toy0`

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

load_rom "$Bin/sprite_dma.nes";

# Frame 0: Before DMA
at_frame 0 => sub {
    # Verify shadow OAM populated
    assert_ram 0x0200 => 100;  # Sprite 0 Y
    assert_ram 0x0201 => 0x42; # Sprite 0 tile
    assert_ram 0x0202 => 0x01; # Sprite 0 attr
    assert_ram 0x0203 => 80;   # Sprite 0 X

    # PPU OAM should be empty (zeros or undefined)
    # NOTE: May need to verify jsnes initializes spriteMem to zeros
};

# Frame 1: After DMA
at_frame 1 => sub {
    # PPU OAM should match shadow OAM
    assert_sprite 0, y => 100, tile => 0x42, attr => 0x01, x => 80;
    assert_sprite 1, y => 110, tile => 0x43, attr => 0x02, x => 90;
    assert_sprite 2, y => 120, tile => 0x44, attr => 0x03, x => 100;
    assert_sprite 3, y => 130, tile => 0x45, attr => 0x00, x => 110;
};

done_testing();
```

**Test:** `perl play-spec.pl` → **fails** (no ROM yet, expected)

**Commit:** `test(toy1): Write failing play-spec for OAM DMA`

### 4. [ ] Write minimal assembly (skeleton)

**Create sprite_dma.s:**
```asm
; toy1_sprite_dma - Validate OAM DMA mechanism
; Tests: Shadow OAM ($0200) → PPU OAM via $4014

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI
    CLD

    ; TODO: Initialize shadow OAM
    ; TODO: Trigger DMA

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

**Test:** `make` → builds successfully, `perl play-spec.pl` → **fails** (no sprite data)

**Commit:** `feat(toy1): Add minimal ROM skeleton`

### 5. [ ] Initialize shadow OAM (1 sprite)

**Add to reset routine:**
```asm
reset:
    SEI
    CLD

    ; Initialize sprite 0 in shadow OAM ($0200-$0203)
    LDA #100        ; Y position
    STA $0200
    LDA #$42        ; Tile number
    STA $0201
    LDA #$01        ; Attributes
    STA $0202
    LDA #80         ; X position
    STA $0203

loop:
    JMP loop
```

**Test:** `make && perl play-spec.pl`
- Shadow OAM assertions should pass
- PPU OAM assertions still fail (no DMA yet)

**Commit:** `feat(toy1): Initialize sprite 0 in shadow OAM`

### 6. [ ] Add remaining 3 sprites

**Extend shadow OAM init:**
```asm
    ; Sprite 0
    LDA #100
    STA $0200
    LDA #$42
    STA $0201
    LDA #$01
    STA $0202
    LDA #80
    STA $0203

    ; Sprite 1
    LDA #110
    STA $0204
    LDA #$43
    STA $0205
    LDA #$02
    STA $0206
    LDA #90
    STA $0207

    ; Sprite 2
    LDA #120
    STA $0208
    LDA #$44
    STA $0209
    LDA #$03
    STA $020A
    LDA #100
    STA $020B

    ; Sprite 3
    LDA #130
    STA $020C
    LDA #$45
    STA $020D
    LDA #$00
    STA $020E
    LDA #110
    STA $020F
```

**Test:** `make && perl play-spec.pl`
- All shadow OAM assertions pass
- PPU OAM assertions still fail

**Commit:** `feat(toy1): Initialize all 4 test sprites`

### 7. [ ] Trigger OAM DMA

**Add DMA trigger after sprite init:**
```asm
    ; Trigger OAM DMA
    LDA #$02        ; High byte of shadow OAM address
    STA $4014       ; Start DMA transfer
    ; CPU stalled for ~513 cycles during DMA
```

**Test:** `make && perl play-spec.pl` → **all tests should pass!**

**Commit:** `feat(toy1): Trigger OAM DMA via $4014`

### 8. [ ] Verify and document findings

**Run final validation:**
- All play-spec.pl tests pass
- ROM loads in Mesen2 (manual check)
- Review cycle budget (manual if needed)

**Update LEARNINGS.md:**
- Move questions from "Questions to Answer" → "Findings"
- Document jsnes behavior (accurate DMA? any quirks?)
- Update "Patterns for Production" with working code
- Note any deviations from theory

**Commit:** `docs(toy1): Update LEARNINGS.md with findings`

### 9. [ ] Write README.md

**Document toy for future reference:**
- What this toy validates
- How to run tests
- Key findings (DMA works, jsnes accurate, etc.)
- Patterns to reuse

**Commit:** `docs(toy1): Write README.md summary`

---

## Risks

**jsnes DMA accuracy:**
- **Risk**: jsnes may not accurately emulate OAM DMA
- **Mitigation**: Compare with Mesen2 manual validation (Phase 3)
- **Fallback**: Document discrepancy, note Phase 2 upgrade needed

**State inspection timing:**
- **Risk**: Uncertain when jsnes updates ppu.spriteMem (during DMA? after frame?)
- **Mitigation**: Test at multiple frames (0, 1, 2) to observe behavior
- **Fallback**: Adjust play-spec timing if needed

**Determinism:**
- **Risk**: jsnes state may vary between runs
- **Mitigation**: Run play-spec multiple times, verify consistency
- **Fallback**: Document non-determinism, investigate jsnes version/config

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
- learnings/sprite_techniques.md (OAM DMA theory)
- TOY_DEV_NES.md (testing methodology)

---

## Success Metrics

**Code quality:**
- Clean assembly (comments, clear structure)
- Minimal (only what's needed for validation)
- Reusable patterns extracted

**Testing:**
- All play-spec.pl tests pass
- Deterministic (same ROM → same results)
- Fast (< 5 seconds to run)

**Documentation:**
- LEARNINGS.md complete with findings
- README.md clear and concise
- Questions answered or spawned

**Knowledge transfer:**
- OAM DMA pattern proven for future toys
- NES::Test Phase 1 validated for hardware toys
- Build/test workflow established

---

## Time Estimate

**Total: 2-3 hours** (first hardware validation toy, includes learning)

- Step 2 (infrastructure): 15 minutes
- Step 3 (play-spec): 30 minutes
- Steps 4-7 (assembly): 1 hour (incremental, TDD)
- Steps 8-9 (docs): 30-45 minutes

**Comparison to toy0:**
- toy0: 2 hours (6x faster than estimated 1 day)
- toy1: Similar complexity, but hardware validation (more unknowns)
- TDD workflow should keep us efficient
