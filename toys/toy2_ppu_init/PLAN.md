# PLAN — Ppu_init

## Strategy

**Test-First Development:**
1. Write play-spec.pl assertions (Red)
2. Write minimal assembly to pass (Green)
3. Commit working increment
4. Repeat until all assertions pass

**Incremental steps:**
- Build infrastructure first (reuse from toy1)
- Test ROM loads before testing PPU behavior
- Add vblank wait loops incrementally (first wait → second wait)
- Marker bytes to prove loops executed

---

## Steps

### 1. [x] Scaffold toy directory
- `tools/new-toy.pl ppu_init` → toys/toy2_ppu_init/
- Files created: SPEC.md, PLAN.md, README.md, LEARNINGS.md
- **Status**: ✅ Complete

### 2. [ ] Copy build infrastructure from toy1

**Copy files:**
```bash
cp toys/toy1_sprite_dma/nes.cfg toys/toy2_ppu_init/
cp toys/toy1_sprite_dma/Makefile toys/toy2_ppu_init/
```

**Modify Makefile:**
- Change ROM name: `sprite_dma.nes` → `ppu_init.nes`
- Change source: `sprite_dma.s` → `ppu_init.s`
- Keep test target (will update play-spec.pl)

**Test:**
```bash
cd toys/toy2_ppu_init
make clean
# Should succeed (no source yet, expected failure)
```

**Commit:** `chore(toy2): Copy build infrastructure from toy1`

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

load_rom "$Bin/ppu_init.nes";

# Frame 1: After reset, before first vblank completes
at_frame 1 => sub {
    # PPU should be disabled
    assert_ppu_ctrl 0x00;
    assert_ppu_mask 0x00;

    # Marker should be 0 (init not complete)
    assert_ram 0x0010 => 0x00;
};

# Frame 2: After first vblank wait
at_frame 2 => sub {
    # First marker should be set
    assert_ram 0x0010 => 0x01;
};

# Frame 3: After second vblank wait
at_frame 3 => sub {
    # Second marker should be set (warmup complete)
    assert_ram 0x0010 => 0x02;
};

done_testing();
```

**Test:** `perl play-spec.pl` → **fails** (no ROM yet, expected)

**Commit:** `test(toy2): Write failing play-spec for PPU init`

### 4. [ ] Write minimal assembly (skeleton)

**Create ppu_init.s:**
```asm
; toy2_ppu_init - Validate PPU 2-vblank warmup sequence
; Tests: PPUSTATUS polling, vblank wait loops

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode

    ; Initialize stack
    LDX #$FF
    TXS

    ; TODO: Disable PPU
    ; TODO: Clear vblank flag
    ; TODO: Wait first vblank
    ; TODO: Wait second vblank

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

**Test:** `make` → builds successfully, `perl play-spec.pl` → **fails** (no init logic)

**Commit:** `feat(toy2): Add minimal ROM skeleton`

### 5. [ ] Disable PPU and clear vblank flag

**Add to reset routine:**
```asm
reset:
    SEI
    CLD

    LDX #$FF
    TXS

    ; Disable PPU
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Clear vblank flag (unknown state at power-on)
    BIT $2002

loop:
    JMP loop
```

**Test:** `make && perl play-spec.pl`
- PPUCTRL/PPUMASK assertions should pass
- Marker assertions still fail (no vblank waits)

**Commit:** `feat(toy2): Disable PPU and clear vblank flag`

### 6. [ ] Add first vblank wait loop

**Add after BIT $2002:**
```asm
    ; Clear vblank flag
    BIT $2002

    ; Wait for first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1     ; Loop while bit 7 = 0

    ; Set marker 1 (proves first vblank reached)
    LDA #$01
    STA $0010

loop:
    JMP loop
```

**Test:** `make && perl play-spec.pl`
- Frame 2 marker assertion should pass
- Frame 3 marker still fails (no second wait)

**Commit:** `feat(toy2): Add first vblank wait loop`

### 7. [ ] Add second vblank wait loop

**Add after first vblank:**
```asm
    ; Set marker 1
    LDA #$01
    STA $0010

    ; Wait for second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2     ; Loop while bit 7 = 0

    ; Set marker 2 (warmup complete)
    LDA #$02
    STA $0010

loop:
    JMP loop
```

**Test:** `make && perl play-spec.pl` → **all tests should pass!**

**Commit:** `feat(toy2): Add second vblank wait loop - ALL TESTS PASS`

### 8. [ ] Verify and document findings

**Run final validation:**
- All play-spec.pl tests pass
- ROM loads in Mesen2 (manual check)
- Verify vblank loops don't hang

**Update LEARNINGS.md:**
- Move questions from "Questions to Answer" → "Findings"
- Document jsnes PPU behavior (vblank flag accurate? frame timing correct?)
- Update "Patterns for Production" with working init sequence
- Note any deviations from theory (frame timing, register values)

**Key questions to answer:**
- Does jsnes enforce 2-vblank warmup?
- What frame does each marker appear? (theory: frame 2 and 3)
- Does PPUSTATUS bit 7 toggle correctly?
- Any differences from wiki documentation?

**Commit:** `docs(toy2): Update LEARNINGS.md with PPU init findings`

### 9. [ ] Write README.md

**Document toy for future reference:**
- What this toy validates (PPU warmup, vblank wait pattern)
- How to run tests (`make && perl play-spec.pl`)
- Key findings (jsnes timing accurate, vblank flag works, etc.)
- Patterns to reuse (standard init sequence for all future toys)

**Commit:** `docs(toy2): Write README.md summary`

---

## Risks

**jsnes vblank flag accuracy:**
- **Risk**: jsnes may not accurately emulate PPUSTATUS bit 7 transitions
- **Mitigation**: Compare with Mesen2 manual validation (Phase 3)
- **Fallback**: Document discrepancy, note Phase 2 upgrade needed

**Frame timing assumptions:**
- **Risk**: Uncertain when markers appear (frame 1? 2? 3?)
- **Mitigation**: Test at multiple frames, adjust play-spec based on actual behavior
- **Fallback**: Update SPEC.md with observed timing

**Infinite loop risk:**
- **Risk**: Vblank wait loops never exit (jsnes bug or implementation error)
- **Mitigation**: Timeout in play-spec? Manual check in Mesen2?
- **Fallback**: Debug with jsnes console logging, verify bit 7 transitions

**Phase 1 limitations:**
- **Risk**: Can't verify 29,658 cycle timing without cycle counter
- **Mitigation**: Accept limitation, document for Phase 2
- **Fallback**: Note in LEARNINGS.md - "cycle count unvalidated in Phase 1"

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
- learnings/getting_started.md (PPU power-up state, init sequence)
- TOY_DEV_NES.md (testing methodology)
- toys/toy1_sprite_dma/ (TDD workflow reference)

---

## Success Metrics

**Code quality:**
- Clean assembly (comments, clear structure)
- Minimal (only what's needed for validation)
- Reusable init pattern for future toys

**Testing:**
- All play-spec.pl tests pass
- Deterministic (same ROM → same results)
- Fast (< 5 seconds to run)

**Documentation:**
- LEARNINGS.md complete with PPU timing findings
- README.md clear and concise
- Standard init pattern documented for reuse

**Knowledge transfer:**
- PPU init pattern proven for all future toys
- Vblank wait loop validated (BIT $2002 / BPL)
- jsnes PPU accuracy assessed
- Frame timing understood (when state becomes observable)

---

## Time Estimate

**Total: 1-2 hours** (simpler than toy1, less unknown behavior)

- Step 2 (infrastructure): 10 minutes (copy from toy1)
- Step 3 (play-spec): 20 minutes (simpler assertions)
- Steps 4-7 (assembly): 45 minutes (incremental, TDD, standard pattern)
- Steps 8-9 (docs): 15-30 minutes

**Comparison to toy1:**
- toy1: 45 minutes actual (2-3 hour estimate)
- toy2: Simpler (no sprite data, just register init)
- Well-understood pattern (wiki has standard code)
- TDD workflow proven efficient in toy1

**Estimated: 1 hour**
