# SPEC — NMI Handler

**Purpose**: Validate NMI (Non-Maskable Interrupt) handler execution and frame synchronization patterns in jsnes.

---

## Overview

**What it does:**
- Implements NMI handler that fires every vblank (~60Hz)
- Increments frame counter in NMI handler (observable via RAM)
- Updates sprite X position every frame via OAM DMA in NMI
- Synchronizes main loop with vblank using NMI flag pattern

**Key principles:**
- **One axis**: NMI handler execution and frame synchronization (not controller input, not scrolling)
- **Observable**: Frame counter and sprite position changes visible in RAM inspection
- **Integration**: Combines toy1 (OAM DMA) + toy2 (PPU init) with NMI pattern
- **Simple pattern**: "NMI Only" style (all work in NMI, main loop idles) for minimal test complexity

**Scope:**
- Test NMI handler executes every frame
- Test OAM DMA works inside NMI handler
- Test sprite animation driven by NMI (X position increments)
- Test frame counter increments reliably
- **Out of scope**: Cycle counting, VRAM updates, music, controller input

**Integration context:**
- **Inputs**: None (self-contained test ROM)
- **Outputs**: RAM state changes (frame counter, sprite position)
- **Dependencies**: toy1 (OAM DMA pattern), toy2 (PPU init pattern)

---

## Data Model

### RAM Layout

```
$0010: frame_counter (1 byte)
  - Incremented in NMI handler
  - Wraps at 256 (0xFF → 0x00)
  - Observable via jsnes RAM inspection

$0011: sprite_x (1 byte)
  - Sprite X position
  - Incremented in NMI handler (moves sprite right)
  - Wraps at 256 (sprite reappears on left)
  - Observable via OAM inspection or sprite display

$0200-$02FF: OAM buffer (256 bytes)
  - Standard sprite attribute table
  - Uploaded via $4014 OAM DMA in NMI handler
  - First sprite (bytes 0-3):
    - Byte 0: Y position (fixed at 120)
    - Byte 1: Tile index (fixed at 0)
    - Byte 2: Attributes (fixed at 0)
    - Byte 3: X position (from $0011)
```

### PPU Registers

```
$2000 (PPUCTRL):
  - Bit 7: NMI enable (set to 1)
  - Bits 0-6: Standard init values

$4014 (OAMDMA):
  - Written with $02 in NMI handler
  - Triggers OAM DMA from $0200-$02FF
```

---

## Core Operations

### Operation 1: NMI Handler

**Behavior**:
```asm
nmi_handler:
  ; Increment frame counter
  INC $0010

  ; Update sprite X position
  INC $0011
  LDA $0011
  STA $0203      ; OAM byte 3 (X position)

  ; Upload OAM via DMA
  LDA #$02
  STA $4014

  RTI
```

**State changes**:
- $0010 (frame_counter) increments by 1
- $0011 (sprite_x) increments by 1
- OAM buffer uploaded to PPU

**Frequency**: Every vblank (~60Hz, ~16.67ms per frame)

### Operation 2: Main Loop

**Behavior**:
```asm
main_loop:
  JMP main_loop  ; Infinite loop (all work in NMI)
```

**State changes**: None (NMI does all work)

### Operation 3: Initialization

**Behavior** (from toy2 PPU init + toy1 OAM setup):
```asm
reset:
  ; 1. CPU init
  SEI            ; Disable IRQ
  CLD            ; Clear decimal mode
  LDX #$FF
  TXS            ; Set up stack

  ; 2. Clear RAM
  LDA #$00
  STA $0010      ; frame_counter = 0
  STA $0011      ; sprite_x = 0

  ; 3. PPU warmup (2 vblanks)
  BIT $2002
  :
    BIT $2002
    BPL :-
  :
    BIT $2002
    BPL :-

  ; 4. Set up OAM
  LDA #$78       ; Y = 120
  STA $0200
  LDA #$00       ; Tile index = 0
  STA $0201
  LDA #$00       ; Attributes = 0
  STA $0202
  LDA #$00       ; X = 0 (will be updated by NMI)
  STA $0203

  ; 5. Enable NMI
  LDA #%10000000 ; NMI enable
  STA $2000

  ; 6. Enter main loop
  JMP main_loop
```

**State changes**:
- RAM initialized
- PPU warmed up
- OAM buffer set up
- NMI enabled
- Main loop started

---

## Test Scenarios

### Scenario 1: Simple (Minimal NMI Execution)

**Test**: NMI fires and frame counter increments

```perl
use NES::Test;

load_rom 'nmi.nes';

at_frame 1 => sub {
    assert_ram 0x0010 => 0x01;  # frame_counter = 1
};

at_frame 2 => sub {
    assert_ram 0x0010 => 0x02;  # frame_counter = 2
};

at_frame 10 => sub {
    assert_ram 0x0010 => 0x0A;  # frame_counter = 10
};
```

**Expected**:
- Frame counter increments every frame
- Test passes with 0 failures

### Scenario 2: Complex (Sprite Animation)

**Test**: Sprite X position updates every frame

```perl
use NES::Test;

load_rom 'nmi.nes';

at_frame 1 => sub {
    assert_ram 0x0011 => 0x01;  # sprite_x = 1
    assert_ram 0x0203 => 0x01;  # OAM X position = 1
};

at_frame 10 => sub {
    assert_ram 0x0011 => 0x0A;  # sprite_x = 10
    assert_ram 0x0203 => 0x0A;  # OAM X position = 10
};

at_frame 60 => sub {
    assert_ram 0x0011 => 0x3C;  # sprite_x = 60 (1 second at 60fps)
    assert_ram 0x0203 => 0x3C;  # OAM X position = 60
};
```

**Expected**:
- Sprite X position increments every frame
- OAM buffer reflects updated position
- Sprite moves across screen (1 pixel/frame)

### Scenario 3: Wraparound (Counter Overflow)

**Test**: Frame counter wraps at 256

```perl
use NES::Test;

load_rom 'nmi.nes';

# Fast-forward to near overflow
set_frame 255;

at_frame 255 => sub {
    assert_ram 0x0010 => 0xFF;  # frame_counter = 255
};

at_frame 256 => sub {
    assert_ram 0x0010 => 0x00;  # Wrapped to 0
};

at_frame 257 => sub {
    assert_ram 0x0010 => 0x01;  # Wrapped, now incrementing again
};
```

**Expected**:
- Counter wraps correctly (0xFF → 0x00 → 0x01)
- No hang or crash on overflow

### Scenario 4: Integration (OAM DMA + PPU Init)

**Test**: Combines toy1 (OAM DMA) + toy2 (PPU init) patterns

```perl
use NES::Test;

load_rom 'nmi.nes';

# Verify PPU init worked (from toy2)
at_frame 1 => sub {
    assert_ram 0x0010 => 0x01;  # NMI fired (PPU ready)
};

# Verify OAM DMA worked (from toy1)
at_frame 1 => sub {
    assert_ram 0x0203 => 0x01;  # Sprite X updated via OAM DMA
};

# Verify integration (both work together)
at_frame 10 => sub {
    assert_ram 0x0010 => 0x0A;  # Frame counter
    assert_ram 0x0203 => 0x0A;  # Sprite X (both incremented)
};
```

**Expected**:
- PPU init completes before NMI enable
- OAM DMA uploads data every frame
- Frame counter and sprite position synchronized

---

## Success Criteria

### Functional Requirements

- [ ] NMI handler executes every frame (frame counter increments)
- [ ] NMI fires at ~60Hz (frame counter reaches 60 in ~1 second)
- [ ] Frame counter wraps correctly at 256 (0xFF → 0x00)
- [ ] Sprite X position updates every frame via OAM DMA
- [ ] OAM buffer reflects updated sprite position
- [ ] Main loop does not interfere with NMI timing

### Integration Requirements

- [ ] toy1 OAM DMA pattern works inside NMI handler
- [ ] toy2 PPU init pattern works before NMI enable
- [ ] NMI enable ($2000 bit 7) triggers NMI handler
- [ ] NMI vector at $FFFA points to correct handler

### Testing Requirements

- [ ] All test scenarios pass (simple, complex, wraparound, integration)
- [ ] Tests run in jsnes without errors
- [ ] Frame counter observable via RAM inspection
- [ ] Sprite X position observable via OAM inspection

### Performance Requirements (Phase 2 - future)

- [ ] NMI handler completes within vblank budget (2273 cycles)
- [ ] OAM DMA cost measured (should be 513-514 cycles)
- [ ] Frame timing consistent (no dropped frames)

---

## Notes

**Why "NMI Only" pattern?**
- Simplest for testing (all work in NMI)
- No synchronization complexity (no NMI flag polling)
- Easy to observe (just increment counters)
- Can test other patterns (Main only, NMI+Main) in future toys if needed

**Why sprite animation?**
- Validates OAM DMA works in NMI context
- Observable behavior (sprite moves across screen)
- Integrates toy1 pattern (OAM DMA)
- Simple to test (increment X position)

**Why frame counter?**
- Proves NMI fires every frame
- Observable via RAM inspection
- Simple to test (assert value)
- Validates 60Hz timing (counter reaches 60 in 1 second)
