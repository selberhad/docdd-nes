# SPEC — Scrolling

**Purpose**: Validate PPUSCROLL register updates in NMI handler for horizontal auto-scrolling (RAM-based validation, Phase 1).

---

## Overview

**What it does:**
- Implements auto-scroll in NMI handler (scroll_x increments each frame)
- Writes PPUSCROLL ($2005) every frame during vblank
- Tracks scroll position in RAM variables (observable via jsnes)
- Integrates with toy4 NMI pattern (Pattern 2: NMI Only)

**Key principles:**
- **One axis**: PPUSCROLL timing and NMI integration (not visual output, not nametable updates)
- **Observable**: scroll_x variable in RAM (Phase 1 limitation - no frame buffer)
- **Integration**: Combines toy4 (NMI handler) with scroll updates
- **Simple pattern**: Horizontal-only auto-scroll (vertical deferred - same mechanism)

**Scope:**
- Test PPUSCROLL register writes work (X, Y)
- Test scroll_x increments each frame in NMI
- Test wraparound at 256 (0xFF → 0x00)
- Test integration with NMI handler (toy4 pattern)
- **Out of scope**: Visual validation, nametable VRAM writes, vertical scrolling

**Integration context:**
- **Inputs**: None (self-contained test ROM)
- **Outputs**: RAM state changes (scroll_x, scroll_y)
- **Dependencies**: toy4 (NMI handler pattern)

---

## Data Model

### RAM Layout

```
$0010: scroll_x (1 byte)
  - Horizontal scroll position
  - Incremented in NMI handler (auto-scroll right)
  - Wraps at 256 (0xFF → 0x00)
  - Written to PPUSCROLL ($2005) first write
  - Observable via jsnes RAM inspection

$0011: scroll_y (1 byte)
  - Vertical scroll position
  - Always 0 in Phase 1 (horizontal-only scrolling)
  - Written to PPUSCROLL ($2005) second write
  - Observable via jsnes RAM inspection
```

### PPU Registers

```
$2002 (PPUSTATUS):
  - Read to reset PPU address latch
  - Must read before PPUSCROLL writes (clears write toggle)

$2005 (PPUSCROLL):
  - First write: X scroll position (from $0010)
  - Second write: Y scroll position (from $0011)
  - Must write EVERY frame in NMI handler
  - Order: Reset latch ($2002 read) → X → Y
```

---

## Core Operations

### Operation 1: NMI Handler with Scrolling

**Behavior**:
```asm
nmi_handler:
  ; Increment scroll position (auto-scroll)
  INC $0010        ; scroll_x += 1

  ; Reset PPU latch
  BIT $2002

  ; Write PPUSCROLL (X, then Y)
  LDA $0010        ; scroll_x
  STA $2005        ; PPUSCROLL X
  LDA $0011        ; scroll_y (always 0)
  STA $2005        ; PPUSCROLL Y

  RTI
```

**State changes**:
- $0010 (scroll_x) increments by 1
- PPUSCROLL updated with new values

**Frequency**: Every vblank (~60Hz, ~16.67ms per frame)

### Operation 2: Main Loop

**Behavior**:
```asm
main_loop:
  JMP main_loop    ; Infinite loop (all work in NMI)
```

**State changes**: None (NMI does all work)

### Operation 3: Initialization

**Behavior**:
```asm
reset:
  ; 1. CPU init
  SEI              ; Disable IRQ
  CLD              ; Clear decimal mode
  LDX #$FF
  TXS              ; Set up stack

  ; 2. Clear RAM
  LDA #$00
  STA $0010        ; scroll_x = 0
  STA $0011        ; scroll_y = 0

  ; 3. PPU warmup (2 vblanks)
  BIT $2002
  :
    BIT $2002
    BPL :-
  :
    BIT $2002
    BPL :-

  ; 4. Enable NMI
  LDA #%10000000   ; NMI enable
  STA $2000

  ; 5. Enter main loop
  JMP main_loop
```

**State changes**:
- RAM initialized (scroll_x = 0, scroll_y = 0)
- PPU warmed up (2 vblanks)
- NMI enabled
- Main loop started

---

## Test Scenarios

### Scenario 1: Horizontal Auto-Scroll

**Test**: scroll_x increments each frame

**Timeline**:
```
Frame 4: scroll_x = 0  (NMI fires at frame 4, see toy4)
Frame 5: scroll_x = 1
Frame 14: scroll_x = 10
Frame 68: scroll_x = 64
Frame 132: scroll_x = 128
```

**Assertions** (t/01-horizontal-scroll.t):
```perl
use NES::Test;
load_rom 'scroll.nes';

at_frame 4 => sub {
    assert_ram 0x10 => 0x00;  # scroll_x = 0
    assert_ram 0x11 => 0x00;  # scroll_y = 0
};

at_frame 5 => sub {
    assert_ram 0x10 => 0x01;  # scroll_x = 1
};

at_frame 14 => sub {
    assert_ram 0x10 => 0x0A;  # scroll_x = 10
};

at_frame 68 => sub {
    assert_ram 0x10 => 0x40;  # scroll_x = 64
};

at_frame 132 => sub {
    assert_ram 0x10 => 0x80;  # scroll_x = 128
};
```

**Expected**: 5 assertions pass, scroll_x increments correctly

---

### Scenario 2: Wraparound

**Test**: scroll_x wraps at 256 (0xFF → 0x00 → 0x01)

**Timeline**:
```
Frame 258: scroll_x = 254
Frame 259: scroll_x = 255
Frame 260: scroll_x = 0    (wraparound)
Frame 261: scroll_x = 1
Frame 264: scroll_x = 4
```

**Assertions** (t/02-wraparound.t):
```perl
use NES::Test;
load_rom 'scroll.nes';

at_frame 258 => sub { assert_ram 0x10 => 0xFE };  # 254
at_frame 259 => sub { assert_ram 0x10 => 0xFF };  # 255
at_frame 260 => sub { assert_ram 0x10 => 0x00 };  # Wrapped to 0
at_frame 261 => sub { assert_ram 0x10 => 0x01 };  # 1
at_frame 264 => sub { assert_ram 0x10 => 0x04 };  # 4
```

**Expected**: 5 assertions pass, wraparound works

---

### Scenario 3: Integration with NMI

**Test**: Combines toy4 NMI pattern + scroll updates

**Timeline**:
```
Frame 4: scroll_x = 0 (first NMI - init offset from toy4)
Frame 10: scroll_x = 6
Frame 20: scroll_x = 16
```

**Assertions** (t/03-integration.t):
```perl
use NES::Test;
load_rom 'scroll.nes';

# First NMI fires at frame 4 (toy4 finding)
at_frame 4 => sub {
    assert_ram 0x10 => 0x00;  # scroll_x = 0 (init)
    assert_ram 0x11 => 0x00;  # scroll_y = 0
};

# 6 frames after first NMI
at_frame 10 => sub {
    assert_ram 0x10 => 0x06;  # scroll_x = 6
};

# 16 frames after first NMI
at_frame 20 => sub {
    assert_ram 0x10 => 0x10;  # scroll_x = 16 (0x10)
};
```

**Expected**: 3 assertions pass, integration works

---

## Success Criteria

### Functional Requirements

- [ ] PPUSCROLL register accepts two writes (X, then Y)
- [ ] scroll_x increments every frame in NMI handler
- [ ] scroll_x wraps at 256 (0xFF → 0x00)
- [ ] scroll_y remains 0 (horizontal-only scrolling)
- [ ] PPU latch reset ($2002 read) works before PPUSCROLL writes

### Integration Requirements

- [ ] toy4 NMI pattern works with scroll updates
- [ ] NMI fires every frame (consistent timing)
- [ ] Scroll update fits in vblank budget (no timing issues)
- [ ] 4-frame init offset from toy4 applies (first NMI at frame 4)

### Testing Requirements

- [ ] All test scenarios pass (horizontal, wraparound, integration)
- [ ] Tests run in jsnes without errors
- [ ] scroll_x observable via RAM inspection
- [ ] 13 total assertions pass (5 + 5 + 3)

### Performance Requirements (Phase 2 - future)

- [ ] NMI handler completes within vblank budget (2273 cycles)
- [ ] PPUSCROLL writes cost measured (~20 cycles theory)
- [ ] Frame timing consistent (no dropped frames)

---

## Notes

**Why horizontal-only?**
- Proves PPUSCROLL register works
- Vertical scrolling is same mechanism (just different axis)
- Simpler to test (one variable changing)
- Can add vertical later if needed

**Why auto-scroll?**
- No controller input needed (simpler test)
- Observable via RAM variable (scroll_x increments)
- Easy to predict (scroll_x = frame_counter - 4)
- Validates NMI timing (60fps)

**Why no nametable initialization?**
- Phase 1 limitation: No frame buffer access (can't validate visual output)
- jsnes defaults VRAM to 0x00 (blank tiles)
- PPUSCROLL timing is what we're testing, not visual scrolling
- Defer VRAM writes to Phase 2 when visual validation available

**Why RAM validation only?**
- Phase 1 limitation: jsnes doesn't expose frame buffer
- RAM state proves PPUSCROLL writes happen
- Sufficient for pattern validation
- Visual validation deferred to Phase 2
