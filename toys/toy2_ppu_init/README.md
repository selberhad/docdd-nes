# Toy 2: PPU Init — 2-Vblank Warmup Validation

**Status**: ✅ Complete (5/5 tests passing)
**Duration**: 30 minutes
**Purpose**: Validate PPU 2-vblank warmup sequence and establish standard init pattern

---

## What This Toy Validates

**PPU initialization requirements:**
- PPUSTATUS polling pattern (BIT $2002 / BPL)
- Vblank flag transitions (bit 7 toggles correctly)
- 2-vblank warmup completes without hanging
- Frame timing (when PPU becomes ready)

**Key finding**: jsnes accurately emulates PPU warmup behavior.

---

## How to Run

**Build and test:**
```bash
cd toys/toy2_ppu_init
make                  # Assembles ppu_init.s → ppu_init.nes
perl play-spec.pl     # Runs automated tests (5 assertions)
```

**Expected output:**
```
ok 1 - PPU CTRL = 0x00
ok 2 - PPU MASK = 0x00
ok 3 - RAM[0x0010] = 0x00
ok 4 - RAM[0x0010] = 0x01
ok 5 - RAM[0x0010] = 0x02
1..5
```

**Manual validation (Mesen2):**
```bash
make run              # Opens ROM in Mesen2
```

---

## Key Findings

### ✅ Validated

**PPU 2-vblank warmup works as documented:**
- First vblank completes by frame 2
- Second vblank completes by frame 3
- BIT $2002 / BPL pattern reliably detects vblank transitions
- jsnes PPUSTATUS bit 7 accurate

**Frame timing:**
- Frame 1: Reset code executing (marker = 0)
- Frame 2: First vblank complete (marker = 1)
- Frame 3: Second vblank complete, PPU ready (marker = 2)

### ⚠️ Critical Lesson: RAM Not Zero-Initialized

**Initial assumption (WRONG):**
- Assumed NES initializes RAM to 0 at power-on

**Reality:**
- NES RAM starts with **undefined values** (often 0xFF)
- Must **explicitly initialize** all RAM variables
- Wiki doesn't emphasize this enough for beginners

**Fix:**
```asm
; After disabling PPU:
INX                 ; X = 0
STX $0010           ; Initialize marker to 0
```

---

## Patterns for Reuse

**Standard PPU init sequence (copy to all future toys):**

```asm
reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode
    LDX #$FF
    TXS                 ; Initialize stack
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Initialize RAM variables here

    BIT $2002           ; Clear vblank flag

vblankwait1:
    BIT $2002
    BPL vblankwait1     ; Loop while bit 7 = 0

    ; Clear RAM here (optional)

vblankwait2:
    BIT $2002
    BPL vblankwait2     ; Loop while bit 7 = 0

    ; PPU now ready - safe to configure
```

**Key points:**
- Always initialize RAM variables (NES doesn't zero RAM!)
- Clear vblank flag before first wait (unknown state at power-on)
- Two vblank waits required (first stabilizes, second ensures ready)
- BIT $2002 / BPL pattern is standard 6502 polling idiom

---

## Phase 1 Limitations

**What we CANNOT test:**
- 29,658 cycle warmup timing (jsnes doesn't expose cycles)
- "Writes ignored before warmup" behavior (can't measure)
- Exact cycle count of vblank wait loops

**Phase 2 upgrade needed:**
- Cycle counting for timing validation
- Verify writes to $2000/$2001 during warmup

**Phase 3 (manual):**
- Validate on real hardware (Mesen2 debugger, Everdrive)

---

## Files

- **ppu_init.s** - Assembly source (minimal PPU init)
- **ppu_init.nes** - Built ROM (24592 bytes, NROM mapper 0)
- **play-spec.pl** - Automated test suite (5 tests)
- **SPEC.md** - Behavioral specification
- **PLAN.md** - TDD implementation plan (9 steps)
- **LEARNINGS.md** - Detailed findings and questions answered

---

## Integration with Toy 1

**Combines with toy1_sprite_dma:**
- toy1: OAM DMA works (shadow OAM → PPU OAM)
- toy2: PPU init works (2-vblank warmup)
- **Future toy3**: Combine both (init + sprites)

---

## What's Next

**toy3 candidates:**
1. **toy3_controller** - Controller input (3-step read sequence)
2. **toy3_sprite_init** - Combine toy1 + toy2 (full init + sprite DMA)
3. **toy4_nmi** - NMI handler (vblank interrupt, OAM DMA in NMI)

**Recommended:** toy3_controller (new subsystem) or toy3_sprite_init (integration)

---

**See LEARNINGS.md for detailed findings and SPEC.md for behavioral contract.**
