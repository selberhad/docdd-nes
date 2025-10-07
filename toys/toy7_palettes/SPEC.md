# SPEC — Palettes

<!-- Read docs/guides/SPEC_WRITING.md before writing this document -->

**Purpose**: Validate NES palette RAM structure, mirroring behavior, and access patterns via automated testing.

## Overview

**What it does**: A test ROM that writes known color values to palette RAM via PPUADDR/PPUDATA, then validates that palette memory behaves as documented in the NESdev wiki (mirroring, readback, address wrapping).

**Key principles**:
- Isolate palette RAM behavior (no rendering, no sprites, no background graphics)
- Test all mirroring quirks documented in wiki (backdrop, unused entries, $3F20+ mirrors)
- Validate via automated assertions (Phase 1 DSL extension: expose jsnes palette RAM)
- Minimal ROM complexity: setup, write palettes, idle loop (no NMI handler needed)

**Scope**: Single complexity axis - palette RAM access and mirroring. Does NOT test visual appearance (Phase 3), palette animation timing (future toy), or mid-frame palette changes (graphics_techniques.md territory).

**Integration context**:
- **Input**: None (no controller, no external state)
- **Output**: Palette RAM state readable by test harness
- **Dependencies**: Requires extending nes-test-harness.js to expose `nes.ppu.paletteMem` or equivalent

## Data Model

### Palette RAM Layout

```
Address Range: $3F00-$3F1F (32 bytes)

Background Palettes ($3F00-$3F0F):
  $3F00: Universal backdrop (shared with $3F10)
  $3F01-$3F03: BG Palette 0, colors 1-3
  $3F04: Unused (mirrors $3F00)
  $3F05-$3F07: BG Palette 1, colors 1-3
  $3F08: Unused (mirrors $3F00)
  $3F09-$3F0B: BG Palette 2, colors 1-3
  $3F0C: Unused (mirrors $3F00)
  $3F0D-$3F0F: BG Palette 3, colors 1-3

Sprite Palettes ($3F10-$3F1F):
  $3F10: Backdrop mirror (shares storage with $3F00)
  $3F11-$3F13: Sprite Palette 0, colors 1-3
  $3F14: Unused (mirrors $3F00)
  $3F15-$3F17: Sprite Palette 1, colors 1-3
  $3F18: Unused (mirrors $3F00)
  $3F19-$3F1B: Sprite Palette 2, colors 1-3
  $3F1C: Unused (mirrors $3F00)
  $3F1D-$3F1F: Sprite Palette 3, colors 1-3

Mirroring: $3F20-$3FFF mirrors $3F00-$3F1F (repeats 8 times)
```

### Color Values

- **Range**: $00-$3F (6-bit, 64 colors)
- **Special**: $0D = "blacker than black" (avoid), $0F = canonical black
- **Invalid**: $40-$FF (behavior undefined, likely wraps to $00-$3F)

## Core Operations

### Write Palette Entry

**Syntax**:
```asm
LDA #$3F
STA $2006        ; PPUADDR high byte
LDA #$01
STA $2006        ; PPUADDR low byte ($3F01)
LDA #$30
STA $2007        ; PPUDATA = $30 (white)
```

**Behavior**:
- Sets palette RAM at specified address to color value
- Auto-increments address after each $2007 write (PPUCTRL bit 2 controls increment)
- Multiple sequential writes update consecutive palette entries

**Validation**:
- Reading back via test harness should return written value
- Mirrored addresses should reflect same value

### Read Palette Entry (via ROM)

**Syntax**:
```asm
LDA #$3F
STA $2006        ; PPUADDR high byte
LDA #$01
STA $2006        ; PPUADDR low byte
LDA $2007        ; Dummy read (fills buffer)
LDA $2007        ; Actual read of $3F01
```

**Behavior**:
- First $2007 read returns buffered data (from previous address)
- Second read returns palette value (with palette reads, buffer behavior differs - immediate read)
- **Note**: Palette reads may not require dummy read (PPU quirk to validate)

**Validation**:
- Read value matches written value
- Test both with/without dummy read to determine jsnes behavior

## Test Scenarios

### 1. Simple: Basic Palette Write

**Setup**:
- Write $0F (black) to $3F00 (backdrop)
- Write $30 (white) to $3F01 (BG pal 0, color 1)

**Assertions**:
```perl
at_frame 1 => sub {
    assert_palette 0x3F00 => 0x0F;
    assert_palette 0x3F01 => 0x30;
};
```

**Expected**: Palette RAM contains written values

### 2. Complex: Backdrop Mirroring

**Setup**:
- Write $1C (red) to $3F00
- Read from $3F10 (should be $1C)
- Write $2D (green) to $3F10
- Read from $3F00 (should be $2D)

**Assertions**:
```perl
at_frame 1 => sub {
    assert_palette 0x3F00 => 0x2D;  # Last write
    assert_palette 0x3F10 => 0x2D;  # Mirrors $3F00
};
```

**Expected**: Both addresses share storage, last write wins

### 3. Complex: Full Region Mirroring

**Setup**:
- Write $0F to $3F00
- Write $30 to $3F01
- Read from $3F20 (should be $0F)
- Read from $3F21 (should be $30)
- Read from $3F40 (should be $0F)

**Assertions**:
```perl
at_frame 1 => sub {
    assert_palette 0x3F00 => 0x0F;
    assert_palette 0x3F20 => 0x0F;  # +$20 mirror
    assert_palette 0x3F40 => 0x0F;  # +$40 mirror
    assert_palette 0x3F01 => 0x30;
    assert_palette 0x3F21 => 0x30;  # +$20 mirror
};
```

**Expected**: $3F00-$3F1F repeats throughout $3F00-$3FFF

### 4. Edge: Unused Entry Behavior

**Setup**:
- Write $16 to $3F04 (unused BG pal 1, entry 0)
- Read from $3F04 (should mirror $3F00)
- Read from $3F00 (should also be $16 if mirroring works)

**Assertions**:
```perl
at_frame 1 => sub {
    assert_palette 0x3F04 => 0x16;  # Unused entry
    assert_palette 0x3F00 => 0x16;  # Should mirror
};
```

**Expected**: Unused entries mirror backdrop color

### 5. Error: Invalid Color Values

**Setup**:
- Write $FF to $3F00
- Write $0D to $3F01 (blacker than black)

**Assertions**:
```perl
at_frame 1 => sub {
    # Validate what jsnes actually stores (may wrap $FF -> $3F)
    assert_palette 0x3F00 => sub { my $val = shift; $val >= 0x00 && $val <= 0x3F };
    assert_palette 0x3F01 => 0x0D;  # Should store as-is
};
```

**Expected**: Out-of-range values handled (wrap or truncate), $0D stored literally

## Success Criteria

- [x] Palette writes via PPUADDR/PPUDATA work
- [x] Backdrop mirroring ($3F00 = $3F10) validated
- [x] Unused entries ($3F04/$3F08/$3F0C/$3F14/$3F18/$3F1C) mirror backdrop
- [x] Full region mirroring ($3F20-$3FFF) validated for at least 2 mirrors
- [x] Sequential writes work without re-setting address
- [x] Color value range ($00-$3F) enforced or wrapped (jsnes stores literally)
- [x] jsnes palette RAM exposure added to test harness
- [x] assert_palette() assertion added to NES::Test DSL
- [x] All test scenarios pass via automated assertions (no manual validation)

**Bonus achievement:** Fixed jsnes palette entry 0 mirroring bug to match hardware behavior
