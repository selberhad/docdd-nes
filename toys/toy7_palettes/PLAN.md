# PLAN — Palettes

<!-- Read docs/guides/PLAN_WRITING.md before writing this document -->

## Overview

**Goal**: Validate NES palette RAM behavior through automated testing using extended Phase 1 DSL.

**Scope**: Test palette writes, mirroring (backdrop, unused entries, region), and readback.

**Priorities**:
1. Extend test infrastructure (jsnes harness + NES::Test DSL)
2. Build minimal ROM (write palettes, idle)
3. Validate all mirroring behaviors via automated assertions

**Methodology**: TDD - write tests first (Red), implement ROM + infrastructure (Green), commit after each step.

---

## Step 1: Extend jsnes Harness for Palette Inspection

### Goal
Expose palette RAM from jsnes to test harness so Perl can assert on palette values.

### Step 1.a: Write Tests (Placeholder)
- Create `t/01-basic-write.t` with skeleton test
- Use `assert_palette 0x3F00 => 0x0F` (not yet implemented - test will fail to compile)
- Documents interface contract before implementation

### Step 1.b: Implement Harness Extension
**Tasks**:
1. Open `lib/nes-test-harness.js`
2. Find `getState` command handler
3. Add palette RAM extraction:
   ```javascript
   palette: Array.from(nes.ppu.paletteMem || nes.ppu.vramMem.slice(0x3F00, 0x3F20))
   ```
   (Check jsnes source for actual palette storage location)
4. Test harness returns palette array in state object

**Pattern** (illustrative):
```javascript
getState: (args) => {
    const state = {
        // ... existing CPU, PPU, OAM ...
        palette: Array.from(nes.ppu.paletteMem) // 32 bytes
    };
    return {status: 'ok', data: state};
}
```

### Step 1.c: Add assert_palette to NES::Test DSL
**Tasks**:
1. Open `lib/NES/Test.pm`
2. Add `assert_palette` to `@EXPORT`
3. Implement function:
   ```perl
   sub assert_palette {
       my ($addr, $expected) = @_;
       my $state = _get_state();
       my $index = $addr - 0x3F00;  # Convert address to array index
       my $actual = $state->{palette}[$index];
       is($actual, $expected, sprintf("Palette[0x%04X] = 0x%02X", $addr, $expected));
   }
   ```
4. Handle mirroring internally (e.g., $3F20 → index 0)

### Success Criteria
- [ ] jsnes harness returns 32-byte palette array in state
- [ ] `assert_palette(addr, value)` exported from NES::Test
- [ ] Function converts PPU address ($3F00+) to array index
- [ ] Test compiles (still fails - no ROM yet)

**Commit**: `feat(toy7): add palette inspection to test DSL`

---

## Step 2: Scaffold ROM Build

### Goal
Create minimal ROM that assembles and runs (no palette logic yet).

### Step 2.a: Scaffold ROM
**Tasks**:
1. Run `cd toys/toy7_palettes && ../../tools/new-rom.pl palette`
2. Creates: `Makefile`, `nes.cfg`, `palette.s`, `play-spec.pl`
3. Verify skeleton ROM builds: `make`

### Step 2.b: Write Minimal ROM
**Pattern** (illustrative):
```asm
.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "CODE"
reset:
    SEI
    CLD
    LDX #$FF
    TXS

    ; Wait 2 vblanks (standard PPU warmup)
    BIT $2002
vblank1:
    BIT $2002
    BPL vblank1
vblank2:
    BIT $2002
    BPL vblank2

    ; TODO: Write palettes here

loop:
    JMP loop

nmi_handler:
    RTI

irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
```

### Success Criteria
- [ ] ROM builds without errors
- [ ] ROM runs in test harness (loads, doesn't crash)
- [ ] `at_frame 1` test can read state (even if palette empty)

**Commit**: `feat(toy7): scaffold palette ROM build`

---

## Step 3: Basic Palette Write

### Goal
Write single palette entry, validate via assert_palette.

### Step 3.a: Write Tests
**File**: `t/01-basic-write.t`
```perl
use NES::Test::Toy 'palette';

at_frame 1 => sub {
    assert_palette 0x3F00 => 0x0F;  # Backdrop = black
    assert_palette 0x3F01 => 0x30;  # BG pal 0, color 1 = white
};

done_testing();
```

### Step 3.b: Implement ROM Palette Writes
**Tasks**:
1. After vblank warmup, write to palette RAM:
   ```asm
   ; Write $0F to $3F00 (backdrop)
   LDA $2002  ; Reset PPUADDR latch
   LDA #$3F
   STA $2006  ; High byte
   LDA #$00
   STA $2006  ; Low byte ($3F00)
   LDA #$0F
   STA $2007  ; Write black

   ; Write $30 to $3F01
   LDA #$30
   STA $2007  ; Auto-increment writes to $3F01
   ```

### Success Criteria
- [ ] Test passes: `assert_palette 0x3F00 => 0x0F`
- [ ] Test passes: `assert_palette 0x3F01 => 0x30`
- [ ] Sequential writes work without re-setting PPUADDR

**Commit**: `test(toy7): add basic palette write test`
**Commit**: `feat(toy7): implement basic palette writes`

---

## Step 4: Backdrop Mirroring ($3F00 = $3F10)

### Goal
Validate that $3F00 and $3F10 share storage.

### Step 4.a: Write Tests
**File**: `t/02-backdrop-mirror.t`
```perl
use NES::Test::Toy 'palette';

at_frame 1 => sub {
    # ROM writes $2D to $3F10, should mirror to $3F00
    assert_palette 0x3F00 => 0x2D;
    assert_palette 0x3F10 => 0x2D;
};

done_testing();
```

### Step 4.b: Implement ROM
**Tasks**:
1. Write to $3F10 instead of $3F00:
   ```asm
   LDA $2002
   LDA #$3F
   STA $2006
   LDA #$10   ; Sprite pal 0, entry 0
   STA $2006
   LDA #$2D   ; Green
   STA $2007
   ```

### Success Criteria
- [ ] Writing to $3F10 updates $3F00
- [ ] Both addresses return same value

**Commit**: `test(toy7): add backdrop mirroring test`
**Commit**: `feat(toy7): validate backdrop mirroring`

---

## Step 5: Unused Entry Mirroring

### Goal
Validate that $3F04/$3F08/$3F0C/$3F14/$3F18/$3F1C mirror $3F00.

### Step 5.a: Write Tests
**File**: `t/03-unused-entries.t`
```perl
use NES::Test::Toy 'palette';

at_frame 1 => sub {
    # ROM writes $16 to $3F04
    assert_palette 0x3F04 => 0x16;  # Unused BG pal 1, entry 0
    assert_palette 0x3F00 => 0x16;  # Should mirror backdrop

    assert_palette 0x3F14 => 0x16;  # Unused sprite pal 1, entry 0
};

done_testing();
```

### Step 5.b: Implement ROM
**Tasks**:
1. Write to $3F04:
   ```asm
   LDA $2002
   LDA #$3F
   STA $2006
   LDA #$04
   STA $2006
   LDA #$16
   STA $2007
   ```

### Success Criteria
- [ ] $3F04 write mirrors to $3F00
- [ ] $3F08, $3F0C, $3F14, $3F18, $3F1C all mirror backdrop

**Commit**: `test(toy7): add unused entry mirroring tests`
**Commit**: `feat(toy7): validate unused entry mirroring`

---

## Step 6: Full Region Mirroring ($3F20+)

### Goal
Validate that $3F20-$3FFF mirrors $3F00-$3F1F.

### Step 6.a: Write Tests
**File**: `t/04-region-mirroring.t`
```perl
use NES::Test::Toy 'palette';

at_frame 1 => sub {
    assert_palette 0x3F00 => 0x0F;
    assert_palette 0x3F20 => 0x0F;  # +$20 mirror
    assert_palette 0x3F40 => 0x0F;  # +$40 mirror

    assert_palette 0x3F01 => 0x30;
    assert_palette 0x3F21 => 0x30;  # +$20 mirror
    assert_palette 0x3F41 => 0x30;  # +$40 mirror
};

done_testing();
```

### Step 6.b: Update assert_palette
**Tasks**:
1. Handle $3F20+ addresses by wrapping to $3F00-$3F1F:
   ```perl
   my $index = ($addr & 0x1F);  # Wrap to 0-31 range
   ```

### Success Criteria
- [ ] $3F20 returns same value as $3F00
- [ ] $3F40, $3F60, $3F80 all work
- [ ] Mirroring works for all 32 palette entries

**Commit**: `test(toy7): add region mirroring tests`
**Commit**: `feat(toy7): validate full region mirroring`

---

## Step 7: Edge Cases (Color Values)

### Goal
Test invalid color values ($40-$FF) and special values ($0D, $0F).

### Step 7.a: Write Tests
**File**: `t/05-color-values.t`
```perl
use NES::Test::Toy 'palette';

at_frame 1 => sub {
    # $0D - blacker than black (should store as-is)
    assert_palette 0x3F01 => 0x0D;

    # $0F - canonical black
    assert_palette 0x3F02 => 0x0F;

    # $FF - invalid (may wrap to $3F)
    # Just verify it doesn't crash
    assert_palette 0x3F03 => sub { defined shift };
};

done_testing();
```

### Step 7.b: Implement ROM
**Tasks**:
1. Write $0D, $0F, $FF to consecutive palette entries
2. Observe what jsnes actually stores

### Success Criteria
- [ ] $0D stores literally (no special handling)
- [ ] $0F stores literally
- [ ] $FF stores something (wrap or truncate, document behavior)

**Commit**: `test(toy7): add color value edge case tests`
**Commit**: `feat(toy7): validate color value behavior`

---

## Risks

**R1: jsnes palette RAM not exposed**
- Mitigation: Check jsnes source (`nes.ppu.paletteMem` or similar)
- Fallback: Use shadow palette in ROM RAM, test indirectly via assert_ram

**R2: Palette mirroring not emulated correctly**
- Mitigation: Document jsnes behavior vs hardware
- Note in LEARNINGS.md if discrepancies found
- Phase 3 validation on Mesen2/hardware

**R3: Palette readback requires dummy read**
- Mitigation: Test both with/without dummy read
- Document actual behavior in LEARNINGS

## Dependencies

- jsnes harness modification (Step 1)
- NES::Test DSL extension (Step 1)
- ROM scaffolding tools (new-rom.pl)
